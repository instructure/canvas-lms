/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import GradebookApi from '../apis/GradebookApi'
import {createGradebook, setFixtureHtml} from './GradebookSpecHelper'
import AsyncComponents from '../AsyncComponents'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'

// Add fixtures div for Jest tests
document.body.innerHTML = '<div id="fixtures"></div>'

const $fixtures = document.getElementById('fixtures')

let oldEnv
let server

window.ENV.SETTINGS = {}

describe('Gradebook#saveSettings', () => {
  let gradebook

  describe('when enhanced_gradebook_filters is enabled', () => {
    let errorFn
    let successFn

    beforeEach(() => {
      gradebook = createGradebook({
        enhanced_gradebook_filters: true,
      })

      errorFn = jest.fn()
      successFn = jest.fn()

      jest.spyOn(GradebookApi, 'saveUserSettings').mockImplementation(() => Promise.resolve({}))

      oldEnv = window.ENV
      window.ENV = {FEATURES: {instui_nav: true}}
    })

    afterEach(() => {
      jest.restoreAllMocks()
      window.ENV = oldEnv
    })

    test('calls the provided successFn if the request succeeds', async () => {
      GradebookApi.saveUserSettings.mockResolvedValue({})
      await gradebook.saveSettings({}).then(successFn).catch(errorFn)
      expect(successFn).toHaveBeenCalledTimes(1)
      expect(errorFn).not.toHaveBeenCalled()
    })

    test('calls the provided errorFn if the request fails', async () => {
      GradebookApi.saveUserSettings.mockRejectedValue(new Error(':('))
      await gradebook.saveSettings({}).then(successFn).catch(errorFn)
      expect(errorFn).toHaveBeenCalledTimes(1)
      expect(successFn).not.toHaveBeenCalled()
    })

    test('just returns if the request succeeds and no successFn is provided', async () => {
      // QUnit.expect(0) is not needed in Jest
      GradebookApi.saveUserSettings.mockResolvedValue({})
      await gradebook.saveSettings({})
      // No assertions needed
    })

    test('throws an error if the request fails and no errorFn is provided', async () => {
      // QUnit.expect(1) is not needed in Jest
      GradebookApi.saveUserSettings.mockRejectedValue(new Error('>:('))

      await expect(gradebook.saveSettings({})).rejects.toThrow('>:(')
    })
  })
})

describe('#renderGradebookSettingsModal', () => {
  let gradebook

  function gradebookSettingsModalProps() {
    return AsyncComponents.renderGradebookSettingsModal.mock.calls[
      AsyncComponents.renderGradebookSettingsModal.mock.calls.length - 1
    ][0]
  }

  beforeEach(() => {
    setFixtureHtml($fixtures)
    jest.spyOn(AsyncComponents, 'renderGradebookSettingsModal').mockImplementation(() => {})
    oldEnv = window.ENV
    window.ENV = {FEATURES: {instui_nav: true}}
  })

  afterEach(() => {
    if (gradebook && gradebook.destroy) {
      gradebook.destroy()
    }
    $fixtures.innerHTML = ''
    jest.restoreAllMocks()
    window.ENV = oldEnv
  })

  test('renders the GradebookSettingsModal component', () => {
    gradebook = createGradebook()
    gradebook.renderGradebookSettingsModal()
    expect(AsyncComponents.renderGradebookSettingsModal).toHaveBeenCalledTimes(1)
  })

  test('sets the .courseFeatures prop to #courseFeatures from Gradebook', () => {
    gradebook = createGradebook()
    gradebook.renderGradebookSettingsModal()
    expect(gradebookSettingsModalProps().courseFeatures).toBe(gradebook.courseFeatures)
  })

  test('sets the .courseSettings prop to #courseSettings from Gradebook', () => {
    gradebook = createGradebook()
    gradebook.renderGradebookSettingsModal()
    expect(gradebookSettingsModalProps().courseSettings).toBe(gradebook.courseSettings)
  })

  test('passes graded_late_submissions_exist option to the modal as a prop', () => {
    gradebook = createGradebook({graded_late_submissions_exist: true})
    gradebook.renderGradebookSettingsModal()
    expect(gradebookSettingsModalProps().gradedLateSubmissionsExist).toBe(true)
  })

  test('passes the context_id option to the modal as a prop', () => {
    gradebook = createGradebook({context_id: '8473'})
    gradebook.renderGradebookSettingsModal()
    expect(gradebookSettingsModalProps().courseId).toBe('8473')
  })

  test('passes the locale option to the modal as a prop', () => {
    gradebook = createGradebook({locale: 'de'})
    gradebook.renderGradebookSettingsModal()
    expect(gradebookSettingsModalProps().locale).toBe('de')
  })

  test('passes the postPolicies object as the prop of the same name', () => {
    gradebook = createGradebook()
    gradebook.renderGradebookSettingsModal()
    expect(gradebookSettingsModalProps().postPolicies).toBe(gradebook.postPolicies)
  })

  describe('.onCourseSettingsUpdated prop', () => {
    beforeEach(() => {
      gradebook = createGradebook()
      gradebook.renderGradebookSettingsModal()
      jest.spyOn(gradebook.courseSettings, 'handleUpdated').mockImplementation(() => {})
      oldEnv = window.ENV
      window.ENV = {FEATURES: {instui_nav: true}}
    })

    afterEach(() => {
      window.ENV = oldEnv
      jest.restoreAllMocks()
    })

    test('updates the course settings when called', () => {
      const settings = {allowFinalGradeOverride: true}
      gradebookSettingsModalProps().onCourseSettingsUpdated(settings)
      expect(gradebook.courseSettings.handleUpdated).toHaveBeenCalledTimes(1)
    })

    test('updates the course settings using the given course settings data', () => {
      const settings = {allowFinalGradeOverride: true}
      gradebookSettingsModalProps().onCourseSettingsUpdated(settings)
      expect(gradebook.courseSettings.handleUpdated).toHaveBeenCalledTimes(1)
      expect(gradebook.courseSettings.handleUpdated.mock.calls[0][0]).toBe(settings)
    })
  })

  describe('anonymousAssignmentsPresent prop', () => {
    const anonymousAssignmentGroup = {
      assignments: [
        {
          anonymous_grading: true,
          assignment_group_id: '10001',
          id: '101',
          name: 'Anonymous',
          points_possible: 10,
          published: true,
        },
      ],
      group_weight: 1,
      id: '10001',
      name: 'An anonymous assignment group',
    }

    const nonAnonymousAssignmentGroup = {
      assignments: [
        {
          anonymous_grading: false,
          assignment_group_id: '10002',
          id: '102',
          name: 'Not-Anonymous',
          points_possible: 10,
          published: true,
        },
      ],
      group_weight: 1,
      id: '10002',
      name: 'An anonymous assignment group',
    }

    test('is passed as true if the course has at least one anonymous assignment', () => {
      window.ENV.SETTINGS = {}
      gradebook = createGradebook()
      gradebook.gotAllAssignmentGroups([anonymousAssignmentGroup, nonAnonymousAssignmentGroup])
      gradebook.renderGradebookSettingsModal()

      expect(gradebookSettingsModalProps().anonymousAssignmentsPresent).toBe(true)
    })

    test('is passed as false if the course has no anonymous assignments', () => {
      window.ENV.SETTINGS = {}
      gradebook = createGradebook()
      gradebook.gotAllAssignmentGroups([nonAnonymousAssignmentGroup])
      gradebook.renderGradebookSettingsModal()

      expect(gradebookSettingsModalProps().anonymousAssignmentsPresent).toBe(false)
    })
  })

  describe('when enhanced gradebook filters are enabled', () => {
    test('sets allowSortingByModules to true if modules are enabled', () => {
      gradebook = createGradebook({enhanced_gradebook_filters: true})
      gradebook.setContextModules([{id: '1', name: 'Module 1', position: 1}])
      gradebook.renderGradebookSettingsModal()

      expect(gradebookSettingsModalProps().allowSortingByModules).toBe(true)
    })

    test('sets allowSortingByModules to false if modules are not enabled', () => {
      gradebook = createGradebook({enhanced_gradebook_filters: true})
      gradebook.renderGradebookSettingsModal()

      expect(gradebookSettingsModalProps().allowSortingByModules).toBe(false)
    })

    test('sets allowViewUngradedAsZero to true if view ungraded as zero is enabled', () => {
      gradebook = createGradebook({
        allow_view_ungraded_as_zero: true,
        enhanced_gradebook_filters: true,
      })
      gradebook.renderGradebookSettingsModal()

      expect(gradebookSettingsModalProps().allowViewUngradedAsZero).toBe(true)
    })

    test('sets allowViewUngradedAsZero to false if view ungraded as zero is not enabled', () => {
      gradebook = createGradebook({enhanced_gradebook_filters: true})
      gradebook.renderGradebookSettingsModal()

      expect(gradebookSettingsModalProps().allowViewUngradedAsZero).toBe(false)
    })

    describe('loadCurrentViewOptions prop', () => {
      const viewOptions = () => gradebookSettingsModalProps().loadCurrentViewOptions()

      test('sets columnSortSettings to the current sort criterion and direction', () => {
        gradebook = createGradebook({enhanced_gradebook_filters: true})
        gradebook.setColumnOrder({sortType: 'due_date', direction: 'descending'})
        gradebook.renderGradebookSettingsModal()

        expect(viewOptions().columnSortSettings).toEqual({
          criterion: 'due_date',
          direction: 'descending',
        })
      })

      test.skip('sets showNotes to true if the notes column is shown', () => {
        gradebook = createGradebook({
          enhanced_gradebook_filters: true,
          teacher_notes: {
            id: '2401',
            title: 'Notes',
            position: 1,
            teacher_notes: true,
            hidden: false,
          },
        })
        gradebook.renderGradebookSettingsModal()

        expect(gradebookSettingsModalProps().showNotes).toBe(true)
      })

      test.skip('sets showNotes to false if the notes column is hidden', () => {
        gradebook = createGradebook({
          enhanced_gradebook_filters: true,
          teacher_notes: {
            id: '2401',
            title: 'Notes',
            position: 1,
            teacher_notes: true,
            hidden: true,
          },
        })
        gradebook.renderGradebookSettingsModal()

        expect(gradebookSettingsModalProps().showNotes).toBe(false)
      })

      test.skip('sets showNotes to false if the notes column does not exist', () => {
        gradebook = createGradebook({enhanced_gradebook_filters: true})
        gradebook.renderGradebookSettingsModal()
        expect(gradebookSettingsModalProps().showNotes).toBe(false)
      })

      test.skip('sets showUnpublishedAssignments to true if unpublished assignments are shown', () => {
        gradebook = createGradebook({enhanced_gradebook_filters: true})
        gradebook.initShowUnpublishedAssignments('true')
        gradebook.renderGradebookSettingsModal()
        expect(gradebookSettingsModalProps().showUnpublishedAssignments).toBe(true)
      })

      test.skip('sets showUnpublishedAssignments to false if unpublished assignments are not shown', () => {
        gradebook = createGradebook({enhanced_gradebook_filters: true})
        gradebook.initShowUnpublishedAssignments('not true')
        gradebook.renderGradebookSettingsModal()
        expect(gradebookSettingsModalProps().showUnpublishedAssignments).toBe(false)
      })

      test.skip('sets viewUngradedAsZero to true if view ungraded as 0 is active', () => {
        gradebook = createGradebook({
          allow_view_ungraded_as_zero: true,
          enhanced_gradebook_filters: true,
        })
        gradebook.gridDisplaySettings.viewUngradedAsZero = true
        gradebook.renderGradebookSettingsModal()
        expect(gradebookSettingsModalProps().viewUngradedAsZero).toBe(true)
      })

      test.skip('sets viewUngradedAsZero to false if view ungraded as 0 is not active', () => {
        gradebook = createGradebook({
          allow_view_ungraded_as_zero: true,
          enhanced_gradebook_filters: true,
        })
        gradebook.gridDisplaySettings.viewUngradedAsZero = false
        gradebook.renderGradebookSettingsModal()
        expect(gradebookSettingsModalProps().viewUngradedAsZero).toBe(false)
      })
    })
  })

  describe('when enhanced gradebook filters are not enabled', () => {
    test('does not set allowSortingByModules', () => {
      gradebook = createGradebook()
      gradebook.renderGradebookSettingsModal()
      expect(gradebookSettingsModalProps().allowSortingByModules).toBeUndefined()
    })

    test('does not set allowViewUngradedAsZero', () => {
      gradebook = createGradebook()
      gradebook.renderGradebookSettingsModal()
      expect(gradebookSettingsModalProps().allowViewUngradedAsZero).toBeUndefined()
    })

    test('does not set loadCurrentViewOptions', () => {
      gradebook = createGradebook()
      gradebook.renderGradebookSettingsModal()
      expect(gradebookSettingsModalProps().loadCurrentViewOptions).toBeUndefined()
    })
  })
})

describe('Gradebook "Enter Grades as" Setting', () => {
  let options
  let gradebook

  beforeAll(() => {
    server = setupServer(
      http.post('/course/1/gradebook_settings', () => {
        return HttpResponse.json({}, {status: 200})
      }),
    )
    server.listen()
  })

  afterAll(() => {
    server.close()
  })

  beforeEach(() => {
    options = {settings_update_url: '/course/1/gradebook_settings'}
    gradebook = createGradebook(options)
    gradebook.setAssignments({
      2301: {id: '2301', grading_type: 'points', name: 'Math Assignment', published: true},
      2302: {id: '2302', grading_type: 'points', name: 'English Assignment', published: false},
    })
    gradebook.gradebookGrid.grid = {
      invalidate() {},
    }
    gradebook.gradebookGrid.gridSupport = {
      columns: {
        updateColumnHeaders() {},
      },
    }
    oldEnv = window.ENV
    window.ENV = {FEATURES: {instui_nav: false}}
  })

  afterEach(() => {
    server.resetHandlers()
    window.ENV = oldEnv
  })

  describe('#getEnterGradesAsSetting', () => {
    beforeEach(() => {
      jest.spyOn(gradebook, 'saveSettings').mockImplementation(() => Promise.resolve())
    })
    test('returns the setting when stored', () => {
      gradebook.setEnterGradesAsSetting('2301', 'percent')
      expect(gradebook.getEnterGradesAsSetting('2301')).toBe('percent')
    })

    test('defaults to "points" for a "points" assignment', () => {
      gradebook.getAssignment('2301').grading_type = 'points'
      expect(gradebook.getEnterGradesAsSetting('2301')).toBe('points')
    })

    test('defaults to "percent" for a "percent" assignment', () => {
      gradebook.getAssignment('2301').grading_type = 'percent'
      expect(gradebook.getEnterGradesAsSetting('2301')).toBe('percent')
    })

    test('defaults to "passFail" for a "pass_fail" assignment', () => {
      gradebook.getAssignment('2301').grading_type = 'pass_fail'
      expect(gradebook.getEnterGradesAsSetting('2301')).toBe('passFail')
    })

    test('defaults to "gradingScheme" for a "letter_grade" assignment', () => {
      gradebook.getAssignment('2301').grading_type = 'letter_grade'
      expect(gradebook.getEnterGradesAsSetting('2301')).toBe('gradingScheme')
    })

    test('defaults to "gradingScheme" for a "gpa_scale" assignment', () => {
      gradebook.getAssignment('2301').grading_type = 'gpa_scale'
      expect(gradebook.getEnterGradesAsSetting('2301')).toBe('gradingScheme')
    })

    test('defaults to null for a "not_graded" assignment', () => {
      gradebook.getAssignment('2301').grading_type = 'not_graded'
      expect(gradebook.getEnterGradesAsSetting('2301')).toBeNull()
    })

    test('defaults to null for a "not_graded" assignment previously set as "points"', () => {
      gradebook.updateEnterGradesAsSetting('2301', 'points')
      gradebook.getAssignment('2301').grading_type = 'not_graded'
      expect(gradebook.getEnterGradesAsSetting('2301')).toBeNull()
    })

    test('defaults to null for a "not_graded" assignment previously set as "percent"', () => {
      gradebook.updateEnterGradesAsSetting('2301', 'percent')
      gradebook.getAssignment('2301').grading_type = 'not_graded'
      expect(gradebook.getEnterGradesAsSetting('2301')).toBeNull()
    })

    test('defaults to "points" for a "points" assignment previously set as "gradingScheme"', () => {
      gradebook.updateEnterGradesAsSetting('2301', 'gradingScheme')
      gradebook.getAssignment('2301').grading_type = 'points'
      expect(gradebook.getEnterGradesAsSetting('2301')).toBe('points')
    })

    test('defaults to "percent" for a "percent" assignment previously set as "gradingScheme"', () => {
      gradebook.updateEnterGradesAsSetting('2301', 'gradingScheme')
      gradebook.getAssignment('2301').grading_type = 'percent'
      expect(gradebook.getEnterGradesAsSetting('2301')).toBe('percent')
    })
  })

  describe('#updateEnterGradesAsSetting', () => {
    beforeEach(() => {
      jest.spyOn(gradebook, 'saveSettings').mockImplementation(() => Promise.resolve())
      jest.spyOn(gradebook.gradebookGrid, 'invalidate').mockImplementation(() => {})
      jest
        .spyOn(gradebook.gradebookGrid.gridSupport.columns, 'updateColumnHeaders')
        .mockImplementation(() => {})
      oldEnv = window.ENV
      window.ENV = {FEATURES: {instui_nav: false}}
    })

    afterEach(() => {
      jest.restoreAllMocks()
      window.ENV = oldEnv
    })

    test('updates the setting in Gradebook', () => {
      gradebook.updateEnterGradesAsSetting('2301', 'percent')
      expect(gradebook.getEnterGradesAsSetting('2301')).toBe('percent')
    })

    test('saves gradebooks settings', () => {
      gradebook.updateEnterGradesAsSetting('2301', 'percent')
      expect(gradebook.saveSettings).toHaveBeenCalledTimes(1)
    })

    test('saves gradebooks settings after updating the "enter grades as" setting', async () => {
      await gradebook.updateEnterGradesAsSetting('2301', 'percent')
      expect(gradebook.getEnterGradesAsSetting('2301')).toBe('percent')
    })

    test('updates the column header for the related assignment column', async () => {
      await gradebook.updateEnterGradesAsSetting('2301', 'percent')
      expect(gradebook.gradebookGrid.gridSupport.columns.updateColumnHeaders).toHaveBeenCalledTimes(
        1,
      )
    })

    test('updates the column header with the assignment column id', async () => {
      await gradebook.updateEnterGradesAsSetting('2301', 'percent')
      expect(gradebook.gradebookGrid.gridSupport.columns.updateColumnHeaders).toHaveBeenCalledWith([
        'assignment_2301',
      ])
    })

    test('updates the column header after settings have been saved', async () => {
      expect(gradebook.gradebookGrid.gridSupport.columns.updateColumnHeaders).not.toHaveBeenCalled()
      gradebook.updateEnterGradesAsSetting('2301', 'percent')
      // Assuming saveSettings is already stubbed to resolve
      await gradebook.saveSettings()
      expect(gradebook.gradebookGrid.gridSupport.columns.updateColumnHeaders).toHaveBeenCalledTimes(
        1,
      )
    })

    test('invalidates the grid', async () => {
      await gradebook.updateEnterGradesAsSetting('2301', 'percent')
      expect(gradebook.gradebookGrid.invalidate).toHaveBeenCalledTimes(1)
    })

    test('invalidates the grid after updating the column header', () => {
      gradebook.gradebookGrid.invalidate.mockImplementation(() => {
        expect(
          gradebook.gradebookGrid.gridSupport.columns.updateColumnHeaders,
        ).toHaveBeenCalledTimes(1)
      })
      gradebook.updateEnterGradesAsSetting('2301', 'percent')
    })
  })

  describe('#postAssignmentGradesTrayOpenChanged', () => {
    beforeEach(() => {
      const assignment = {id: '2301'}
      const column = gradebook.buildAssignmentColumn(assignment)
      gradebook.gridData.columns.definitions[column.id] = column
      jest.spyOn(gradebook, 'updateGrid').mockImplementation(() => {})
      oldEnv = window.ENV
      window.ENV = {FEATURES: {instui_nav: false}}
    })

    afterEach(() => {
      jest.restoreAllMocks()
      window.ENV = oldEnv
    })

    test('calls updateGrid if a corresponding column is found', () => {
      gradebook.postAssignmentGradesTrayOpenChanged({assignmentId: '2301', isOpen: true})
      expect(gradebook.updateGrid).toHaveBeenCalledTimes(1)
    })

    test('does not call updateGrid if a corresponding column is not found', () => {
      gradebook.postAssignmentGradesTrayOpenChanged({assignmentId: '2399', isOpen: true})
      expect(gradebook.updateGrid).not.toHaveBeenCalled()
    })
  })
})
