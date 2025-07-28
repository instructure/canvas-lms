/*
 * Copyright (C) 2024 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import {map} from 'lodash'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import {createGradebook} from './GradebookSpecHelper'
import studentRowHeaderConstants from '../constants/studentRowHeaderConstants'
import fakeENV from '@canvas/test-utils/fakeENV'

// Mock React and ReactDOM
jest.mock('react', () => ({
  ...jest.requireActual('react'),
  createElement: jest.fn().mockImplementation((type, props, ...children) => ({
    type,
    props: {...props, children},
  })),
}))

jest.mock('react-dom/client', () => ({
  createRoot: jest.fn().mockReturnValue({
    render: jest.fn(),
    unmount: jest.fn(),
  }),
}))

// Mock renderComponent from Gradebook.utils
jest.mock('../Gradebook.utils', () => ({
  ...jest.requireActual('../Gradebook.utils'),
  renderComponent: jest.fn(),
}))

const server = setupServer(
  // Default handler for settings updates
  http.post('/path/to/settingsUpdateUrl', () => {
    return HttpResponse.json({success: true})
  }),
)

describe('Gradebook#filterStudents', () => {
  let students
  let gradebook

  beforeAll(() => server.listen())
  afterEach(() => server.resetHandlers())
  afterAll(() => server.close())

  beforeEach(() => {
    fakeENV.setup()
    document.body.innerHTML = `
      <div id="fixtures">
        <div id="application">
          <div id="wrapper">
            <div data-component="GridColor"></div>
            <div id="gradebook_grid"></div>
          </div>
        </div>
      </div>
    `

    students = [
      {
        id: '1',
        sections: ['section1', 'section2', 'section3'],
        enrollments: [
          {
            id: '',
            user_id: '1',
            enrollment_state: 'active',
            type: 'StudentEnrollment',
            course_section_id: 'section1',
          },
          {
            id: '',
            user_id: '1',
            enrollment_state: 'completed',
            type: 'StudentEnrollment',
            course_section_id: 'section2',
          },
          {
            id: '',
            user_id: '1',
            enrollment_state: 'inactive',
            type: 'StudentEnrollment',
            course_section_id: 'section3',
          },
        ],
      },
    ]
    gradebook = createGradebook({
      settings: {
        show_concluded_enrollments: 'false',
        show_inactive_enrollments: 'false',
      },
    })
  })

  afterEach(() => {
    fakeENV.teardown()
    document.body.innerHTML = ''
  })

  it('returns selected student when filtering by student and section with an active enrollment', () => {
    gradebook.props.appliedFilters = [
      {
        id: '1',
        type: 'section',
        created_at: '',
        value: 'section1',
      },
    ]
    gradebook.searchFilteredStudentIds = ['1']
    const filteredStudents = gradebook.filterStudents(students)
    expect(map(filteredStudents, 'id')).toEqual(['1'])
  })

  it('does not return selected student when filtering by student and section with a concluded enrollment', () => {
    gradebook.props.appliedFilters = [
      {
        id: '1',
        type: 'section',
        created_at: '',
        value: 'section2',
      },
    ]
    gradebook.searchFilteredStudentIds = ['1']
    const filteredStudents = gradebook.filterStudents(students)
    expect(map(filteredStudents, 'id')).toEqual([])
  })

  it('returns selected student when filtering by student and section with a concluded enrollment and show concluded enrollments filter on', () => {
    const gradebookWithConcluded = createGradebook({
      settings: {
        show_concluded_enrollments: 'true',
        show_inactive_enrollments: 'false',
      },
    })
    gradebookWithConcluded.props.appliedFilters = [
      {
        id: '1',
        type: 'section',
        created_at: '',
        value: 'section2',
      },
    ]
    gradebookWithConcluded.searchFilteredStudentIds = ['1']
    const filteredStudents = gradebookWithConcluded.filterStudents(students)
    expect(map(filteredStudents, 'id')).toEqual(['1'])
  })

  it('does not return selected student when filtering by student and section with an inactive enrollment', () => {
    gradebook.props.appliedFilters = [
      {
        id: '1',
        type: 'section',
        created_at: '',
        value: 'section3',
      },
    ]
    gradebook.searchFilteredStudentIds = ['1']
    const filteredStudents = gradebook.filterStudents(students)
    expect(map(filteredStudents, 'id')).toEqual([])
  })

  it('returns selected student when filtering by student and section with an inactive enrollment and show inactive enrollments filter on', () => {
    const gradebookWithInactive = createGradebook({
      settings: {
        show_concluded_enrollments: 'false',
        show_inactive_enrollments: 'true',
      },
    })
    gradebookWithInactive.props.appliedFilters = [
      {
        id: '1',
        type: 'section',
        created_at: '',
        value: 'section3',
      },
    ]
    gradebookWithInactive.searchFilteredStudentIds = ['1']
    const filteredStudents = gradebookWithInactive.filterStudents(students)
    expect(map(filteredStudents, 'id')).toEqual(['1'])
  })
})

describe('Gradebook#getSelectedEnrollmentFilters', () => {
  beforeAll(() => server.listen())
  afterEach(() => server.resetHandlers())
  afterAll(() => server.close())

  beforeEach(() => {
    fakeENV.setup()
    document.body.innerHTML = `
      <div id="fixtures">
        <div id="application">
          <div id="wrapper">
            <div data-component="GridColor"></div>
            <div id="gradebook_grid"></div>
          </div>
        </div>
      </div>
    `
  })

  afterEach(() => {
    fakeENV.teardown()
    document.body.innerHTML = ''
  })

  it('returns empty array when all settings are off', () => {
    const gradebook = createGradebook({
      settings: {
        show_concluded_enrollments: 'false',
        show_inactive_enrollments: 'false',
      },
    })
    expect(gradebook.getSelectedEnrollmentFilters()).toHaveLength(0)
  })

  it('returns array including "concluded" when setting is on', () => {
    const gradebook = createGradebook({
      settings: {
        show_concluded_enrollments: 'true',
        show_inactive_enrollments: 'false',
      },
    })
    expect(gradebook.getSelectedEnrollmentFilters()).toContain('concluded')
    expect(gradebook.getSelectedEnrollmentFilters()).not.toContain('inactive')
  })

  it('returns array including "inactive" when setting is on', () => {
    const gradebook = createGradebook({
      settings: {
        show_concluded_enrollments: 'false',
        show_inactive_enrollments: 'true',
      },
    })
    expect(gradebook.getSelectedEnrollmentFilters()).toContain('inactive')
    expect(gradebook.getSelectedEnrollmentFilters()).not.toContain('concluded')
  })

  it('returns array including multiple values when settings are on', () => {
    const gradebook = createGradebook({
      settings: {
        show_concluded_enrollments: 'true',
        show_inactive_enrollments: 'true',
      },
    })
    expect(gradebook.getSelectedEnrollmentFilters()).toContain('inactive')
    expect(gradebook.getSelectedEnrollmentFilters()).toContain('concluded')
  })
})

describe('Gradebook#toggleEnrollmentFilter', () => {
  let gradebook

  beforeAll(() => server.listen())
  afterEach(() => server.resetHandlers())
  afterAll(() => server.close())

  beforeEach(() => {
    fakeENV.setup()
    document.body.innerHTML = `
      <div id="fixtures">
        <div id="application">
          <div id="wrapper">
            <div data-component="GridColor"></div>
            <div id="gradebook_grid"></div>
          </div>
        </div>
      </div>
    `
    gradebook = createGradebook()
    gradebook.gradebookGrid.gridSupport = {
      columns: {
        updateColumnHeaders: jest.fn(),
      },
    }
    gradebook.saveSettings = jest.fn().mockResolvedValue()
  })

  afterEach(() => {
    fakeENV.teardown()
    document.body.innerHTML = ''
  })

  it('changes the value of getSelectedEnrollmentFilters', () => {
    studentRowHeaderConstants.enrollmentFilterKeys.forEach(key => {
      const previousValue = gradebook.getSelectedEnrollmentFilters().includes(key)
      gradebook.toggleEnrollmentFilter(key, true)
      const newValue = gradebook.getSelectedEnrollmentFilters().includes(key)
      expect(previousValue).not.toBe(newValue)
    })
  })

  it('saves settings', () => {
    gradebook.toggleEnrollmentFilter('inactive')
    expect(gradebook.saveSettings).toHaveBeenCalledTimes(1)
  })

  it('updates the student column header', async () => {
    await gradebook.toggleEnrollmentFilter('inactive')
    expect(gradebook.gradebookGrid.gridSupport.columns.updateColumnHeaders).toHaveBeenCalledTimes(1)
  })

  it('includes the "student" column id when updating column headers', async () => {
    await gradebook.toggleEnrollmentFilter('inactive')
    expect(gradebook.gradebookGrid.gridSupport.columns.updateColumnHeaders).toHaveBeenCalledWith([
      'student',
    ])
  })
})

describe('Gradebook#updateCurrentModule', () => {
  let gradebook

  beforeAll(() => server.listen())
  afterEach(() => server.resetHandlers())
  afterAll(() => server.close())

  beforeEach(() => {
    fakeENV.setup()
    document.body.innerHTML = `
      <div id="fixtures">
        <div id="application">
          <div id="wrapper">
            <div data-component="GridColor"></div>
            <div id="gradebook_grid"></div>
          </div>
        </div>
      </div>
    `

    gradebook = createGradebook({
      settings: {
        filter_columns_by: {
          context_module_id: '2',
        },
        selected_view_options_filters: ['modules'],
      },
    })
    gradebook.setContextModules([
      {id: '1', name: 'Module 1', position: 1},
      {id: '2', name: 'Another Module', position: 2},
      {id: '3', name: 'Module 2', position: 3},
    ])
    jest.spyOn(gradebook, 'setFilterColumnsBySetting')
    gradebook.updateFilteredContentInfo = jest.fn()
    gradebook.updateColumnsAndRenderViewOptionsMenu = jest.fn()
  })

  afterEach(() => {
    fakeENV.teardown()
    document.body.innerHTML = ''
  })

  it('updates the filter setting with the given module id', () => {
    gradebook.updateCurrentModule('1')
    expect(gradebook.getFilterColumnsBySetting('contextModuleId')).toBe('1')
  })

  it('saves settings with the new filter setting', async () => {
    gradebook.updateCurrentModule('1')
    await new Promise(resolve => setTimeout(resolve, 0))
    expect(gradebook.getFilterColumnsBySetting('contextModuleId')).toBe('1')
  })

  it('has no effect when the module has not changed', () => {
    const saveSettingsSpy = jest.spyOn(gradebook, 'saveSettings')
    gradebook.updateCurrentModule('2')
    expect(saveSettingsSpy).not.toHaveBeenCalled()
    expect(gradebook.updateFilteredContentInfo).not.toHaveBeenCalled()
    expect(gradebook.updateColumnsAndRenderViewOptionsMenu).not.toHaveBeenCalled()
  })
})

describe('Gradebook#updateCurrentAssignmentGroup', () => {
  let gradebook

  beforeAll(() => server.listen())
  afterEach(() => server.resetHandlers())
  afterAll(() => server.close())

  beforeEach(() => {
    fakeENV.setup()
    document.body.innerHTML = `
      <div id="fixtures">
        <div id="application">
          <div id="wrapper">
            <div data-component="GridColor"></div>
            <div id="gradebook_grid"></div>
          </div>
        </div>
      </div>
    `

    gradebook = createGradebook({
      settings: {
        filter_columns_by: {
          assignment_group_id: '2',
        },
        selected_view_options_filters: ['assignmentGroups'],
      },
    })
    gradebook.setAssignmentGroups({
      1: {id: '1', name: 'First'},
      2: {id: '2', name: 'Second'},
    })
    jest.spyOn(gradebook, 'setFilterColumnsBySetting')
    gradebook.updateFilteredContentInfo = jest.fn()
    gradebook.updateColumnsAndRenderViewOptionsMenu = jest.fn()
  })

  afterEach(() => {
    fakeENV.teardown()
    document.body.innerHTML = ''
  })

  it('updates the filter setting with the given assignment group id', () => {
    gradebook.updateCurrentAssignmentGroup('1')
    expect(gradebook.getFilterColumnsBySetting('assignmentGroupId')).toBe('1')
  })

  it('saves settings with the new filter setting', async () => {
    gradebook.updateCurrentAssignmentGroup('1')
    await new Promise(resolve => setTimeout(resolve, 0))
    expect(gradebook.getFilterColumnsBySetting('assignmentGroupId')).toBe('1')
  })

  it('has no effect when the assignment group has not changed', () => {
    const saveSettingsSpy = jest.spyOn(gradebook, 'saveSettings')
    gradebook.updateCurrentAssignmentGroup('2')
    expect(saveSettingsSpy).not.toHaveBeenCalled()
    expect(gradebook.updateFilteredContentInfo).not.toHaveBeenCalled()
    expect(gradebook.updateColumnsAndRenderViewOptionsMenu).not.toHaveBeenCalled()
  })
})

describe('Gradebook', () => {
  beforeAll(() => server.listen())
  afterEach(() => server.resetHandlers())
  afterAll(() => server.close())

  describe('getActionMenuProps', () => {
    let options
    let gradebook

    beforeEach(() => {
      fakeENV.setup()
      document.body.innerHTML = `
        <div id="fixtures">
          <div id="application">
            <div id="wrapper">
              <div data-component="GridColor"></div>
              <div id="gradebook_grid"></div>
            </div>
          </div>
        </div>
      `
      options = {
        context_allows_gradebook_uploads: true,
        currentUserId: '123',
        export_gradebook_csv_url: 'http://example.com/export',
        gradebook_import_url: 'http://example.com/import',
        post_grades_feature: false,
        publish_to_sis_enabled: false,
        grading_period_set: {
          id: '1501',
          grading_periods: [{id: '701'}, {id: '702'}],
        },
        current_grading_period_id: '702',
      }
    })

    afterEach(() => {
      fakeENV.teardown()
      document.body.innerHTML = ''
    })

    it('sets publishGradesToSis.isEnabled to true when "publish to SIS" is enabled', () => {
      options.publish_to_sis_enabled = true
      gradebook = createGradebook(options)
      const props = gradebook.getActionMenuProps()
      expect(props.publishGradesToSis.isEnabled).toBe(true)
    })

    it('sets publishGradesToSis.isEnabled to false when "publish to SIS" is not enabled', () => {
      options.publish_to_sis_enabled = false
      gradebook = createGradebook(options)
      const props = gradebook.getActionMenuProps()
      expect(props.publishGradesToSis.isEnabled).toBe(false)
    })

    it('sets gradingPeriodId', () => {
      gradebook = createGradebook(options)
      const props = gradebook.getActionMenuProps()
      expect(props.gradingPeriodId).toBe('702')
    })
  })

  describe('updateFilterSettings', () => {
    let gradebook
    let currentFilters

    beforeEach(() => {
      fakeENV.setup()
    })

    afterEach(() => {
      fakeENV.teardown()
    })

    const options = {
      enhanced_gradebook_filters: false,
      grading_period_set: {
        id: '1501',
        grading_periods: [
          {id: '1401', title: 'Grading Period #1'},
          {id: '1402', title: 'Grading Period #2'},
        ],
      },
      sections: [
        {id: '2001', name: 'Freshmen'},
        {id: '2002', name: 'Sophomores'},
      ],
      sections_enabled: true,
      settings: {
        filter_columns_by: {
          assignment_group_id: '2',
          grading_period_id: '1402',
          context_module_id: '2',
        },
        filter_rows_by: {
          section_id: '2001',
        },
        selected_view_options_filters: [],
      },
      isModulesLoading: false,
      modules: [
        {id: '1', name: 'Module 1', position: 1},
        {id: '2', name: 'Another Module', position: 2},
        {id: '3', name: 'Module 2', position: 3},
      ],
    }

    beforeEach(() => {
      document.body.innerHTML = `
        <div id="fixtures">
          <div id="application">
            <div id="wrapper">
              <div data-component="GridColor"></div>
              <div id="gradebook_grid"></div>
            </div>
          </div>
        </div>
      `
      currentFilters = ['assignmentGroups', 'modules', 'gradingPeriods', 'sections']
      options.settings.selected_view_options_filters = currentFilters
      gradebook = createGradebook(options)
      gradebook.setAssignmentGroups({
        1: {id: '1', name: 'Assignment Group #1'},
        2: {id: '2', name: 'Assignment Group #2'},
      })

      jest.spyOn(gradebook, 'setFilterColumnsBySetting')
      gradebook.saveSettings = jest.fn().mockResolvedValue()
      gradebook.resetGrading = jest.fn()
      gradebook.sortGridRows = jest.fn()
      gradebook.updateFilteredContentInfo = jest.fn()
      gradebook.updateColumnsAndRenderViewOptionsMenu = jest.fn()
      gradebook.renderViewOptionsMenu = jest.fn()
      gradebook.renderActionMenu = jest.fn()
    })

    afterEach(() => {
      gradebook = null
      document.body.innerHTML = ''
    })

    it('getFilterColumnsBySetting returns the assignment group filter setting', () => {
      expect(gradebook.getFilterColumnsBySetting('assignmentGroupId')).toBe('2')
    })

    it('does not delete the assignment group filter setting when the filter is hidden and assignment groups have not loaded', () => {
      gradebook.updateFilterSettings(currentFilters.filter(type => type !== 'assignmentGroups'))
      expect(gradebook.getFilterColumnsBySetting('assignmentGroupId')).toBe('2')
    })

    it('getFilterColumnsBySetting returns the grading period filter setting', () => {
      expect(gradebook.getFilterColumnsBySetting('gradingPeriodId')).toBe('1402')
    })

    it('getFilterColumnsBySetting returns the modules filter setting', () => {
      expect(gradebook.getFilterColumnsBySetting('contextModuleId')).toBe('2')
    })

    it('does not delete the modules filter setting when the filter is hidden and modules have not loaded', () => {
      gradebook = createGradebook({
        ...options,
        isModulesLoading: true,
      })
      gradebook.updateFilterSettings(currentFilters.filter(type => type !== 'modules'))
      expect(gradebook.getFilterColumnsBySetting('contextModuleId')).toBe('2')
    })

    it('getFilterColumnsBySetting returns the sections filter setting', () => {
      expect(gradebook.getFilterRowsBySetting('sectionId')).toBe('2001')
    })
  })
})
