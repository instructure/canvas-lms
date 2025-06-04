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

import {map} from 'lodash'
import 'jquery-migrate'
import {createGradebook, setFixtureHtml} from './GradebookSpecHelper'
import ContentFilterDriver from '@canvas/grading/content-filters/ContentFilterDriver'
import PostGradesStore from '../../SISGradePassback/PostGradesStore'

beforeEach(() => {
  document.body.innerHTML = '<div id="fixtures"></div>'
})

afterEach(() => {
  document.body.innerHTML = ''
})

describe('Gradebook#updateModulesFilterVisibility', () => {
  let gradebook
  let container

  beforeEach(() => {
    const modulesFilterContainerSelector = 'modules-filter-container'
    setFixtureHtml(document.getElementById('fixtures'))
    container = document
      .getElementById('fixtures')
      .querySelector(`#${modulesFilterContainerSelector}`)
    gradebook = createGradebook()
    gradebook.setContextModules([
      {id: '1', name: 'Module 1', position: 1},
      {id: '2', name: 'Module 2', position: 2},
    ])
    gradebook.setSelectedViewOptionsFilters(['modules'])
  })

  test('renders the module select when not already rendered', () => {
    gradebook.updateModulesFilterVisibility()
    expect(container.children.length).toBeGreaterThan(0)
  })

  test('does not render when modules are empty', () => {
    gradebook.setContextModules([])
    gradebook.updateModulesFilterVisibility()
    expect(container.children).toHaveLength(0)
  })

  test('does not render when filter is not selected', () => {
    gradebook.setSelectedViewOptionsFilters(['assignmentGroups'])
    gradebook.updateModulesFilterVisibility()
    expect(container.children).toHaveLength(0)
  })
})

describe('Gradebook#updateAssignmentGroupFilterVisibility', () => {
  let gradebook
  let container

  beforeEach(() => {
    const agfContainer = 'assignment-group-filter-container'
    setFixtureHtml(document.getElementById('fixtures'))
    container = document.getElementById('fixtures').querySelector(`#${agfContainer}`)
    gradebook = createGradebook()
    gradebook.setAssignmentGroups([
      {id: '1', name: 'Assignments', position: 1},
      {id: '2', name: 'Other', position: 2},
    ])
    gradebook.setSelectedViewOptionsFilters(['assignmentGroups'])
  })

  test('renders the assignment group select when not already rendered', () => {
    const countBefore = container.children.length
    gradebook.updateAssignmentGroupFilterVisibility()
    expect(container.children.length).toBeGreaterThan(countBefore)
  })

  test('does not render when there is only one assignment group', () => {
    gradebook.setAssignmentGroups([{id: '1', name: 'Assignments', position: 1}])
    gradebook.updateAssignmentGroupFilterVisibility()
    expect(container.children).toHaveLength(0)
  })

  test('does not render when filter is not selected', () => {
    gradebook.setSelectedViewOptionsFilters(['modules'])
    gradebook.updateAssignmentGroupFilterVisibility()
    expect(container.children).toHaveLength(0)
  })
})

describe('Gradebook#getFilterSettingsViewOptionsMenuProps', () => {
  let gradebook

  beforeEach(() => {
    gradebook = createGradebook()
    gradebook.setAssignmentGroups({
      301: {name: 'Assignments', group_weight: 40},
      302: {name: 'Homework', group_weight: 60},
    })
    gradebook.gradingPeriodSet = {id: '1501'}
    gradebook.setContextModules([{id: '2601'}, {id: '2602'}])
    gradebook.sections_enabled = true
    gradebook.studentGroupsEnabled = true
    gradebook.renderViewOptionsMenu = jest.fn()
    gradebook.renderFilters = jest.fn()
    gradebook.saveSettings = jest.fn()
  })

  test('includes available filters', () => {
    const props = gradebook.getFilterSettingsViewOptionsMenuProps()
    expect(props.available).toEqual([
      'assignmentGroups',
      'gradingPeriods',
      'modules',
      'sections',
      'studentGroups',
    ])
  })

  test('available filters exclude assignment groups when only one exists', () => {
    gradebook.setAssignmentGroups({301: {name: 'Assignments'}})
    const props = gradebook.getFilterSettingsViewOptionsMenuProps()
    expect(props.available).toEqual(['gradingPeriods', 'modules', 'sections', 'studentGroups'])
  })

  test('available filters exclude assignment groups when not loaded', () => {
    gradebook.setAssignmentGroups(undefined)
    const props = gradebook.getFilterSettingsViewOptionsMenuProps()
    expect(props.available).toEqual(['gradingPeriods', 'modules', 'sections', 'studentGroups'])
  })

  test('available filters exclude grading periods when no grading period set exists', () => {
    gradebook.gradingPeriodSet = null
    const props = gradebook.getFilterSettingsViewOptionsMenuProps()
    expect(props.available).toEqual(['assignmentGroups', 'modules', 'sections', 'studentGroups'])
  })

  test('available filters exclude modules when none exist', () => {
    gradebook.setContextModules([])
    const props = gradebook.getFilterSettingsViewOptionsMenuProps()
    expect(props.available).toEqual([
      'assignmentGroups',
      'gradingPeriods',
      'sections',
      'studentGroups',
    ])
  })

  test('available filters exclude sections when not enabled', () => {
    gradebook.sections_enabled = false
    const props = gradebook.getFilterSettingsViewOptionsMenuProps()
    expect(props.available).toEqual([
      'assignmentGroups',
      'gradingPeriods',
      'modules',
      'studentGroups',
    ])
  })

  test('available filters exclude student groups when none exist', () => {
    gradebook.studentGroupsEnabled = false
    const props = gradebook.getFilterSettingsViewOptionsMenuProps()
    expect(props.available).toEqual(['assignmentGroups', 'gradingPeriods', 'modules', 'sections'])
  })

  test('includes selected filters', () => {
    gradebook.setSelectedViewOptionsFilters(['gradingPeriods', 'modules'])
    const props = gradebook.getFilterSettingsViewOptionsMenuProps()
    expect(props.selected).toEqual(['gradingPeriods', 'modules'])
  })

  test('onSelect sets the selected filters', () => {
    const props = gradebook.getFilterSettingsViewOptionsMenuProps()
    props.onSelect(['gradingPeriods', 'sections'])
    expect(gradebook.listSelectedViewOptionsFilters()).toEqual(['gradingPeriods', 'sections'])
  })

  test('onSelect renders the view options menu after setting the selected filters', () => {
    const props = gradebook.getFilterSettingsViewOptionsMenuProps()
    gradebook.renderViewOptionsMenu.mockImplementation(() => {
      expect(gradebook.listSelectedViewOptionsFilters()).toHaveLength(2)
    })
    props.onSelect(['gradingPeriods', 'sections'])
  })

  test('onSelect renders the filters after setting the selected filters', () => {
    const props = gradebook.getFilterSettingsViewOptionsMenuProps()
    gradebook.renderFilters.mockImplementation(() => {
      expect(gradebook.listSelectedViewOptionsFilters()).toHaveLength(2)
    })
    props.onSelect(['gradingPeriods', 'sections'])
  })

  test('onSelect saves settings after setting the selected filters', () => {
    const props = gradebook.getFilterSettingsViewOptionsMenuProps()
    gradebook.saveSettings.mockImplementation(() => {
      expect(gradebook.listSelectedViewOptionsFilters()).toHaveLength(2)
    })
    props.onSelect(['gradingPeriods', 'sections'])
  })
})

describe('Gradebook#updateStudentGroupFilterVisibility', () => {
  let gradebook
  let container

  beforeEach(() => {
    const studentGroupFilterContainerSelector = 'student-group-filter-container'
    setFixtureHtml(document.getElementById('fixtures'))
    container = document
      .getElementById('fixtures')
      .querySelector(`#${studentGroupFilterContainerSelector}`)

    const studentGroups = [
      {
        groups: [
          {id: '1', name: 'First Group Set 1'},
          {id: '2', name: 'First Group Set 2'},
        ],
        id: '1',
        name: 'First Group Set',
      },
      {
        groups: [
          {id: '3', name: 'Second Group Set 1'},
          {id: '4', name: 'Second Group Set 2'},
        ],
        id: '2',
        name: 'Second Group Set',
      },
    ]

    gradebook = createGradebook({student_groups: studentGroups})
    gradebook.studentGroupsEnabled = true
    gradebook.setSelectedViewOptionsFilters(['studentGroups'])
  })

  test('renders the student group filter when not already rendered', () => {
    gradebook.updateStudentGroupFilterVisibility()
    const filter = ContentFilterDriver.findWithLabelText('Student Group Filter', container)
    expect(filter).toBeTruthy()
  })

  test('does not render when there are no student groups', () => {
    gradebook.studentGroupsEnabled = false
    gradebook.updateStudentGroupFilterVisibility()
    expect(container.children).toHaveLength(0)
  })

  test('does not render when filter is not selected', () => {
    gradebook.setSelectedViewOptionsFilters(['assignmentGroups'])
    gradebook.updateStudentGroupFilterVisibility()
    expect(container.children).toHaveLength(0)
  })

  test('renders the filter with group sets at the top level', () => {
    gradebook.updateStudentGroupFilterVisibility()
    const filter = ContentFilterDriver.findWithLabelText('Student Group Filter', container)
    filter.clickToExpand()
    expect(filter.optionGroupLabels).toEqual(['First Group Set', 'Second Group Set'])
  })

  test('renders the filter with all groups', () => {
    gradebook.updateStudentGroupFilterVisibility()
    const filter = ContentFilterDriver.findWithLabelText('Student Group Filter', container)
    filter.clickToExpand()
    expect(filter.optionLabels.slice(1)).toEqual([
      'First Group Set 1',
      'First Group Set 2',
      'Second Group Set 1',
      'Second Group Set 2',
    ])
  })

  test('sets the filter to show the saved "filter rows by" setting', () => {
    gradebook.setFilterRowsBySetting('studentGroupId', '4')
    gradebook.updateStudentGroupFilterVisibility()
    const filter = ContentFilterDriver.findWithLabelText('Student Group Filter', container)
    filter.clickToExpand()
    expect(filter.selectedItemLabel).toBe('Second Group Set 2')
  })

  test('sets the filter as disabled when students are not loaded', () => {
    gradebook.updateStudentGroupFilterVisibility()
    const filter = ContentFilterDriver.findWithLabelText('Student Group Filter', container)
    filter.clickToExpand()
    expect(filter.isDisabled).toBe(true)
  })

  test('sets the filter as not disabled when students are loaded', () => {
    gradebook.setStudentsLoaded(true)
    gradebook.updateStudentGroupFilterVisibility()
    const filter = ContentFilterDriver.findWithLabelText('Student Group Filter', container)
    filter.clickToExpand()
    expect(filter.isDisabled).toBe(false)
  })

  test('updates the disabled state of the rendered filter', () => {
    gradebook.updateStudentGroupFilterVisibility()
    gradebook.setStudentsLoaded(true)
    gradebook.updateStudentGroupFilterVisibility()
    const filter = ContentFilterDriver.findWithLabelText('Student Group Filter', container)
    filter.clickToExpand()
    expect(filter.isDisabled).toBe(false)
  })

  test('renders only one student group filter when updated', () => {
    gradebook.updateStudentGroupFilterVisibility()
    gradebook.updateStudentGroupFilterVisibility()
    expect(container.children).toHaveLength(1)
  })

  test('removes the filter when the "view student group filter" option is turned off', () => {
    gradebook.setSelectedViewOptionsFilters(['assignmentGroups'])
    gradebook.updateStudentGroupFilterVisibility()
    expect(container.children).toHaveLength(0)
  })
})

describe('Gradebook#updateSectionFilterVisibility', () => {
  let gradebook
  let container

  beforeEach(() => {
    const sectionsFilterContainerSelector = 'sections-filter-container'
    setFixtureHtml(document.getElementById('fixtures'))
    container = document
      .getElementById('fixtures')
      .querySelector(`#${sectionsFilterContainerSelector}`)
    const sections = [
      {id: '2001', name: 'Freshmen / First-Year'},
      {id: '2002', name: 'Sophomores'},
    ]
    gradebook = createGradebook({sections})
    gradebook.sections_enabled = true
    gradebook.setSelectedViewOptionsFilters(['sections'])
  })

  test('renders the section filter when not already rendered', () => {
    gradebook.updateSectionFilterVisibility()
    expect(container.children.length).toBeGreaterThan(0)
  })

  test('does not render when only one section exists', () => {
    gradebook.sections_enabled = false
    gradebook.updateSectionFilterVisibility()
    expect(container.children).toHaveLength(0)
  })

  test('does not render when filter is not selected', () => {
    gradebook.setSelectedViewOptionsFilters(['assignmentGroups'])
    gradebook.updateSectionFilterVisibility()
    expect(container.children).toHaveLength(0)
  })

  test('renders the filter with a list of sections', () => {
    gradebook.updateSectionFilterVisibility()
    const filter = ContentFilterDriver.findWithLabelText('Section Filter', container)
    filter.clickToExpand()
    expect(filter.optionLabels.slice(1)).toEqual(['Freshmen / First-Year', 'Sophomores'])
  })

  test('sets the filter to show the saved "filter rows by" setting', () => {
    gradebook.setFilterRowsBySetting('sectionId', '2002')
    gradebook.updateSectionFilterVisibility()
    const filter = ContentFilterDriver.findWithLabelText('Section Filter', container)
    filter.clickToExpand()
    expect(filter.selectedItemLabel).toBe('Sophomores')
  })

  test('sets the filter as disabled when students are not loaded', () => {
    gradebook.updateSectionFilterVisibility()
    const filter = ContentFilterDriver.findWithLabelText('Section Filter', container)
    filter.clickToExpand()
    expect(filter.isDisabled).toBe(true)
  })

  test('sets the filter as not disabled when students are loaded', () => {
    gradebook.setStudentsLoaded(true)
    gradebook.updateSectionFilterVisibility()
    const filter = ContentFilterDriver.findWithLabelText('Section Filter', container)
    filter.clickToExpand()
    expect(filter.isDisabled).toBe(false)
  })

  test('updates the disabled state of the rendered filter', () => {
    gradebook.updateSectionFilterVisibility()
    gradebook.setStudentsLoaded(true)
    gradebook.updateSectionFilterVisibility()
    const filter = ContentFilterDriver.findWithLabelText('Section Filter', container)
    filter.clickToExpand()
    expect(filter.isDisabled).toBe(false)
  })

  test('renders only one section filter when updated', () => {
    gradebook.updateSectionFilterVisibility()
    gradebook.updateSectionFilterVisibility()
    expect(container.children).toHaveLength(1)
  })

  test('removes the filter when the "view section filter" option is turned off', () => {
    gradebook.setSelectedViewOptionsFilters(['assignmentGroups'])
    gradebook.updateSectionFilterVisibility()
    expect(container.children).toHaveLength(0)
  })
})

describe('Gradebook#updateCurrentSection', () => {
  let gradebook
  let postGradesStore

  beforeEach(() => {
    postGradesStore = PostGradesStore({
      course: {id: '1', sis_id: null},
      selected: {id: '1', type: 'course'},
    })
    postGradesStore.setSelectedSection = jest.fn()

    gradebook = createGradebook({
      settings_update_url: '/settingUrl',
      postGradesStore: postGradesStore,
    })
    gradebook.saveSettings = jest.fn().mockResolvedValue({})
    gradebook.updateSectionFilterVisibility = jest.fn()
  })

  test('updates the filter setting with the given section id', () => {
    gradebook.updateCurrentSection('2001')
    expect(gradebook.getFilterRowsBySetting('sectionId')).toBe('2001')
  })

  test('sets the selected section on the post grades store', () => {
    gradebook.updateCurrentSection('2001')
    expect(postGradesStore.setSelectedSection).toHaveBeenCalledTimes(3)
  })

  test('includes the selected section when updating the post grades store', () => {
    gradebook.updateCurrentSection('2001')
    const [sectionId] = postGradesStore.setSelectedSection.mock.calls[2]
    expect(sectionId).toBe('2001')
  })

  test('saves settings', () => {
    gradebook.updateCurrentSection('2001')
    expect(gradebook.saveSettings).toHaveBeenCalledTimes(1)
  })

  test('saves settings after updating the filter setting', () => {
    gradebook.updateCurrentSection('2001')
    expect(gradebook.getFilterRowsBySetting('sectionId')).toBe('2001')
  })

  test('has no effect when the section has not changed', () => {
    gradebook.setFilterRowsBySetting('sectionId', '2001')
    gradebook.updateCurrentSection('2001')
    expect(gradebook.saveSettings).not.toHaveBeenCalled()
    expect(gradebook.updateSectionFilterVisibility).not.toHaveBeenCalled()
  })
})

describe('Gradebook#isFilteringColumnsByGradingPeriod', () => {
  let gradebook

  beforeEach(() => {
    gradebook = createGradebook()
    gradebook.gradingPeriodSet = {id: '1501', gradingPeriods: [{id: '701'}, {id: '702'}]}
    gradebook.setFilterColumnsBySetting('gradingPeriodId', '702')
    gradebook.setCurrentGradingPeriod()
  })

  test('returns true when the "filter columns by" setting includes a grading period', () => {
    expect(gradebook.isFilteringColumnsByGradingPeriod()).toBe(true)
  })

  test('returns false when the "filter columns by" setting includes the "all grading periods" value ("0")', () => {
    gradebook.setFilterColumnsBySetting('gradingPeriodId', '0')
    gradebook.setCurrentGradingPeriod()
    expect(gradebook.isFilteringColumnsByGradingPeriod()).toBe(false)
  })

  test('returns false when the "filter columns by" setting does not include a grading period', () => {
    gradebook.setFilterColumnsBySetting('gradingPeriodId', null)
    gradebook.setCurrentGradingPeriod()
    expect(gradebook.isFilteringColumnsByGradingPeriod()).toBe(false)
  })

  test('returns false when the "filter columns by" setting does not include a valid grading period', () => {
    gradebook.setFilterColumnsBySetting('gradingPeriodId', '799')
    gradebook.setCurrentGradingPeriod()
    expect(gradebook.isFilteringColumnsByGradingPeriod()).toBe(false)
  })

  test('returns false when no grading period set exists', () => {
    gradebook.gradingPeriodSet = null
    gradebook.setCurrentGradingPeriod()
    expect(gradebook.isFilteringColumnsByGradingPeriod()).toBe(false)
  })

  test('returns true when the "filter columns by" setting is null and the current_grading_period_id is set', () => {
    gradebook.options.current_grading_period_id = '701'
    gradebook.setFilterColumnsBySetting('gradingPeriodId', null)
    gradebook.setCurrentGradingPeriod()
    expect(gradebook.isFilteringColumnsByGradingPeriod()).toBe(true)
  })
})

describe('Gradebook#filterAssignments', () => {
  let gradebook
  let assignments

  beforeEach(() => {
    assignments = [
      {
        assignment_group: {position: 1},
        id: '2301',
        position: 1,
        name: 'published graded',
        published: true,
        submission_types: ['online_text_entry'],
        assignment_group_id: '1',
        module_ids: ['2'],
      },
      {
        assignment_group: {position: 2},
        id: '2302',
        position: 2,
        name: 'unpublished',
        published: false,
        submission_types: ['online_text_entry'],
        assignment_group_id: '2',
        module_ids: ['1'],
      },
      {
        assignment_group: {position: 2},
        id: '2303',
        position: 3,
        name: 'not graded',
        published: true,
        submission_types: ['not_graded'],
        assignment_group_id: '2',
        module_ids: ['2'],
      },
      {
        assignment_group: {position: 1},
        id: '2304',
        position: 4,
        name: 'attendance',
        published: true,
        submission_types: ['attendance'],
        assignment_group_id: '1',
        module_ids: ['1'],
      },
    ]
    const submissionsChunk = [
      {
        submissions: [
          {
            assignment_id: '2301',
            id: '2501',
            posted_at: null,
            score: 10,
            user_id: '1101',
            late: true,
            workflow_state: 'graded',
          },
          {
            assignment_id: '2302',
            id: '2502',
            posted_at: null,
            score: 9,
            user_id: '1101',
            missing: true,
            workflow_state: 'missing',
          },
        ],
        user_id: '1101',
      },
    ]
    gradebook = createGradebook()
    gradebook.assignments = {
      2301: assignments[0],
      2302: assignments[1],
      2303: assignments[2],
      2304: assignments[3],
    }
    gradebook.students = {
      1101: {
        id: '1101',
        name: 'Adam Jones',
        assignment_2301: {
          assignment_id: '2301',
          late: false,
          missing: false,
          excused: false,
          seconds_late: 0,
          user_id: '1101',
        },
        assignment_2302: {
          assignment_id: '2302',
          late: false,
          missing: false,
          excused: false,
          seconds_late: 0,
          user_id: '1101',
        },
      },
    }
    gradebook.gotSubmissionsChunk(submissionsChunk)
    gradebook.setAssignmentGroups([
      {id: '1', name: 'Assignments', position: 1},
      {id: '2', name: 'Homework', position: 2},
    ])
    gradebook.courseContent.gradingPeriodAssignments = {
      1401: ['2301', '2303'],
      1402: ['2302', '2304'],
    }
    gradebook.courseContent.contextModules = [
      {id: '1', name: 'Algebra', position: 1},
      {id: '2', name: 'English', position: 2},
    ]
    gradebook.gradingPeriodSet = {
      id: '1501',
      gradingPeriods: [
        {id: '1401', title: 'Grading Period #1'},
        {id: '1402', title: 'Grading Period #2'},
      ],
    }
    gradebook.gridDisplaySettings.showUnpublishedAssignments = true
    gradebook.show_attendance = true
    gradebook.setAssignmentsLoaded()
    gradebook.setSubmissionsLoaded(true)
  })

  test('when filtering by assignments, only includes assignments in the filter', () => {
    gradebook.setFilterColumnsBySetting('gradingPeriodId', '0')
    gradebook.searchFilteredAssignmentIds = ['2301', '2304']
    const filteredAssignments = gradebook.filterAssignments(assignments)
    expect(filteredAssignments.map(a => a.id)).toEqual(['2301', '2304'])
  })

  test('does not filter assignments when the filtered IDs is an empty array', () => {
    gradebook.setFilterColumnsBySetting('gradingPeriodId', '0')
    gradebook.filteredAssignmentIds = []
    const filteredAssignments = gradebook.filterAssignments(assignments)
    expect(filteredAssignments.map(a => a.id)).toEqual(['2301', '2302', '2304'])
  })

  test('excludes "not_graded" assignments', () => {
    const filteredAssignments = gradebook.filterAssignments(assignments)
    expect(filteredAssignments.findIndex(assignment => assignment.id === '2303')).toBe(-1)
  })

  test('excludes "unpublished" assignments when "showUnpublishedAssignments" is false', () => {
    gradebook.gridDisplaySettings.showUnpublishedAssignments = false
    const filteredAssignments = gradebook.filterAssignments(assignments)
    expect(filteredAssignments.findIndex(assignment => assignment.id === '2302')).toBe(-1)
  })

  test('includes "unpublished" assignments when "showUnpublishedAssignments" is true', () => {
    gradebook.gridDisplaySettings.showUnpublishedAssignments = true
    const filteredAssignments = gradebook.filterAssignments(assignments)
    expect(filteredAssignments.findIndex(assignment => assignment.id === '2302')).not.toBe(-1)
  })

  test('excludes "attendance" assignments when "show_attendance" is false', () => {
    gradebook.show_attendance = false
    const filteredAssignments = gradebook.filterAssignments(assignments)
    expect(filteredAssignments.findIndex(assignment => assignment.id === '2304')).toBe(-1)
  })

  test('includes "attendance" assignments when "show_attendance" is true', () => {
    gradebook.show_attendance = true
    const filteredAssignments = gradebook.filterAssignments(assignments)
    expect(filteredAssignments.findIndex(assignment => assignment.id === '2304')).not.toBe(-1)
  })

  test('includes assignments from all grading periods when not filtering by grading period', () => {
    gradebook.setFilterColumnsBySetting('gradingPeriodId', '0') // value indicates "All Grading Periods"
    const filteredAssignments = gradebook.filterAssignments(assignments)
    expect(map(filteredAssignments, 'id')).toEqual(['2301', '2302', '2304'])
  })

  test('excludes assignments from other grading periods when filtering by a grading period', () => {
    gradebook.setFilterColumnsBySetting('gradingPeriodId', '1401')
    gradebook.setCurrentGradingPeriod()
    const filteredAssignments = gradebook.filterAssignments(assignments)
    expect(map(filteredAssignments, 'id')).toEqual(['2301'])
  })

  test('includes assignments from all grading periods when grading period set has not been assigned', () => {
    gradebook.gradingPeriodSet = null
    gradebook.setFilterColumnsBySetting('gradingPeriodId', '1401')
    const filteredAssignments = gradebook.filterAssignments(assignments)
    expect(map(filteredAssignments, 'id')).toEqual(['2301', '2302', '2304'])
  })

  test('includes assignments from all modules when not filtering by module', () => {
    gradebook.setFilterColumnsBySetting('contextModuleId', '0') // All Modules
    const filteredAssignments = gradebook.filterAssignments(assignments)
    expect(map(filteredAssignments, 'id')).toEqual(['2301', '2302', '2304'])
  })

  test('excludes assignments from other modules when filtering by a module', () => {
    gradebook.setFilterColumnsBySetting('contextModuleId', '2')
    const filteredAssignments = gradebook.filterAssignments(assignments)
    expect(map(filteredAssignments, 'id')).toEqual(['2301'])
  })

  test('does not filter assignments when filtering by a module that was deleted', () => {
    gradebook.courseContent.contextModules = []
    gradebook.setFilterColumnsBySetting('contextModuleId', '2')
    const filteredAssignments = gradebook.filterAssignments(assignments)
    expect(map(filteredAssignments, 'id')).toEqual(['2301', '2302', '2304'])
  })

  test('includes assignments from all assignment groups when not filtering by assignment group', () => {
    gradebook.setFilterColumnsBySetting('assignmentGroupId', '0') // All Assignment Groups
    const filteredAssignments = gradebook.filterAssignments(assignments)
    expect(map(filteredAssignments, 'id')).toEqual(['2301', '2302', '2304'])
  })

  test('excludes assignments from other assignment groups when filtering by an assignment group', () => {
    gradebook.setFilterColumnsBySetting('assignmentGroupId', '2')
    const filteredAssignments = gradebook.filterAssignments(assignments)
    expect(map(filteredAssignments, 'id')).toEqual(['2302'])
  })

  test('includes assignments filtered by submissions status', () => {
    gradebook.props.appliedFilters = [
      {
        id: '1',
        type: 'submissions',
        value: 'missing',
        created_at: new Date().toISOString(),
      },
    ]
    gradebook.setFilterColumnsBySetting('submissions', 'missing')
    const filteredAssignments = gradebook.filterAssignments(assignments)
    expect(map(filteredAssignments, 'id')).toEqual(['2302'])
  })

  test('includes no assignments when filtered by non existent submissions status', () => {
    gradebook.props.appliedFilters = [
      {
        id: '1',
        type: 'submissions',
        value: 'extended',
        created_at: new Date().toISOString(),
      },
    ]
    gradebook.setFilterColumnsBySetting('submissions', 'missing')
    const filteredAssignments = gradebook.filterAssignments(assignments)
    expect(map(filteredAssignments, 'id')).toEqual([])
  })

  test('includes assignments when filtered by existing status and searchFilteredStudentIds matches the submission', () => {
    gradebook.props.appliedFilters = [
      {
        id: '1',
        type: 'submissions',
        value: 'missing',
        created_at: new Date().toISOString(),
      },
    ]
    gradebook.searchFilteredStudentIds = ['1101']
    gradebook.setFilterColumnsBySetting('submissions', 'missing')
    const filteredAssignments = gradebook.filterAssignments(assignments)
    expect(map(filteredAssignments, 'id')).toEqual(['2302'])
  })

  test('includes no assignments when filtered by existing status but searchFilteredStudentIds does not match submission', () => {
    gradebook.props.appliedFilters = [
      {
        id: '1',
        type: 'submissions',
        value: 'missing',
        created_at: new Date().toISOString(),
      },
    ]
    gradebook.searchFilteredStudentIds = ['1102']
    gradebook.setFilterColumnsBySetting('submissions', 'missing')
    const filteredAssignments = gradebook.filterAssignments(assignments)
    expect(map(filteredAssignments, 'id')).toEqual([])
  })

  test('allows for multiselect when filtering by status and multiselect_gradebook_filters_enabled', () => {
    window.ENV.GRADEBOOK_OPTIONS = {
      multiselect_gradebook_filters_enabled: true,
    }
    gradebook.props.appliedFilters = [
      {
        id: '1',
        type: 'submissions',
        value: 'late',
        created_at: new Date().toISOString(),
      },
      {
        id: '2',
        type: 'submissions',
        value: 'missing',
        created_at: new Date().toISOString(),
      },
    ]
    const filteredAssignments = gradebook.filterAssignments(assignments)
    expect(map(filteredAssignments, 'id')).toEqual(['2301', '2302'])
  })

  test('does not allows for multiselect when filtering by status and multiselect_gradebook_filters_enabled is false', () => {
    window.ENV.GRADEBOOK_OPTIONS = {
      multiselect_gradebook_filters_enabled: false,
    }
    gradebook.props.appliedFilters = [
      {
        id: '1',
        type: 'submissions',
        value: 'late',
        created_at: new Date().toISOString(),
      },
      {
        id: '2',
        type: 'submissions',
        value: 'missing',
        created_at: new Date().toISOString(),
      },
    ]
    const filteredAssignments = gradebook.filterAssignments(assignments)
    expect(map(filteredAssignments, 'id')).toEqual([])
  })
})
