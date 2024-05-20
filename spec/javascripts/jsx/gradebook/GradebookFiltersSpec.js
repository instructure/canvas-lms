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
import $ from 'jquery'
import 'jquery-migrate'
import {
  createGradebook,
  setFixtureHtml,
} from 'ui/features/gradebook/react/default_gradebook/__tests__/GradebookSpecHelper'
import studentRowHeaderConstants from 'ui/features/gradebook/react/default_gradebook/constants/studentRowHeaderConstants'
import ContentFilterDriver from './default_gradebook/components/content-filters/ContentFilterDriver'
import PostGradesStore from 'ui/features/gradebook/react/SISGradePassback/PostGradesStore'
import {hideAggregateColumns} from 'ui/features/gradebook/react/default_gradebook/GradebookGrid/Grid.utils'

const $fixtures = document.getElementById('fixtures')

QUnit.module('Gradebook#updateModulesFilterVisibility', {
  setup() {
    const modulesFilterContainerSelector = 'modules-filter-container'
    setFixtureHtml($fixtures)
    this.container = $fixtures.querySelector(`#${modulesFilterContainerSelector}`)
    this.gradebook = createGradebook()
    this.gradebook.setContextModules([
      {id: '1', name: 'Module 1', position: 1},
      {id: '2', name: 'Module 2', position: 2},
    ])
    this.gradebook.setSelectedViewOptionsFilters(['modules'])
  },

  teardown() {
    $fixtures.innerHTML = ''
  },
})

test('renders the module select when not already rendered', function () {
  this.gradebook.updateModulesFilterVisibility()
  ok(this.container.children.length > 0, 'something was rendered')
})

test('does not render when modules are empty', function () {
  this.gradebook.setContextModules([])
  this.gradebook.updateModulesFilterVisibility()
  strictEqual(this.container.children.length, 0, 'nothing was rendered')
})

test('does not render when filter is not selected', function () {
  this.gradebook.setSelectedViewOptionsFilters(['assignmentGroups'])
  this.gradebook.updateModulesFilterVisibility()
  strictEqual(this.container.children.length, 0, 'rendered elements have been removed')
})

QUnit.module('Gradebook#updateAssignmentGroupFilterVisibility', {
  setup() {
    const agfContainer = 'assignment-group-filter-container'
    setFixtureHtml($fixtures)
    this.container = $fixtures.querySelector(`#${agfContainer}`)
    this.gradebook = createGradebook()
    this.gradebook.setAssignmentGroups([
      {id: '1', name: 'Assignments', position: 1},
      {id: '2', name: 'Other', position: 2},
    ])
    this.gradebook.setSelectedViewOptionsFilters(['assignmentGroups'])
  },

  teardown() {
    $fixtures.innerHTML = ''
  },
})

test('renders the assignment group select when not already rendered', function () {
  const countBefore = this.container.children.length
  this.gradebook.updateAssignmentGroupFilterVisibility()
  ok(this.container.children.length > countBefore, 'something was rendered')
})

test('does not render when there is only one assignment group', function () {
  this.gradebook.setAssignmentGroups([{id: '1', name: 'Assignments', position: 1}])
  this.gradebook.updateAssignmentGroupFilterVisibility()
  strictEqual(this.container.children.length, 0, 'nothing was rendered')
})

test('does not render when filter is not selected', function () {
  this.gradebook.setSelectedViewOptionsFilters(['modules'])
  this.gradebook.updateAssignmentGroupFilterVisibility()
  strictEqual(this.container.children.length, 0, 'rendered elements have been removed')
})

QUnit.module('Gradebook#getFilterSettingsViewOptionsMenuProps', {
  setup() {
    this.gradebook = createGradebook()
    this.gradebook.setAssignmentGroups({
      301: {name: 'Assignments', group_weight: 40},
      302: {name: 'Homework', group_weight: 60},
    })
    this.gradebook.gradingPeriodSet = {id: '1501'}
    this.gradebook.setContextModules([{id: '2601'}, {id: '2602'}])
    this.gradebook.sections_enabled = true
    this.gradebook.studentGroupsEnabled = true
    sandbox.stub(this.gradebook, 'renderViewOptionsMenu')
    sandbox.stub(this.gradebook, 'renderFilters')
    sandbox.stub(this.gradebook, 'saveSettings')
  },
})

test('includes available filters', function () {
  const props = this.gradebook.getFilterSettingsViewOptionsMenuProps()
  deepEqual(props.available, [
    'assignmentGroups',
    'gradingPeriods',
    'modules',
    'sections',
    'studentGroups',
  ])
})

test('available filters exclude assignment groups when only one exists', function () {
  this.gradebook.setAssignmentGroups({301: {name: 'Assignments'}})
  const props = this.gradebook.getFilterSettingsViewOptionsMenuProps()
  deepEqual(props.available, ['gradingPeriods', 'modules', 'sections', 'studentGroups'])
})

test('available filters exclude assignment groups when not loaded', function () {
  this.gradebook.setAssignmentGroups(undefined)
  const props = this.gradebook.getFilterSettingsViewOptionsMenuProps()
  deepEqual(props.available, ['gradingPeriods', 'modules', 'sections', 'studentGroups'])
})

test('available filters exclude grading periods when no grading period set exists', function () {
  this.gradebook.gradingPeriodSet = null
  const props = this.gradebook.getFilterSettingsViewOptionsMenuProps()
  deepEqual(props.available, ['assignmentGroups', 'modules', 'sections', 'studentGroups'])
})

test('available filters exclude modules when none exist', function () {
  this.gradebook.setContextModules([])
  const props = this.gradebook.getFilterSettingsViewOptionsMenuProps()
  deepEqual(props.available, ['assignmentGroups', 'gradingPeriods', 'sections', 'studentGroups'])
})

test('available filters exclude sections when only one exists', function () {
  this.gradebook.sections_enabled = false
  const props = this.gradebook.getFilterSettingsViewOptionsMenuProps()
  deepEqual(props.available, ['assignmentGroups', 'gradingPeriods', 'modules', 'studentGroups'])
})

test('available filters exclude student groups when none exist', function () {
  this.gradebook.studentGroupsEnabled = false
  const props = this.gradebook.getFilterSettingsViewOptionsMenuProps()
  deepEqual(props.available, ['assignmentGroups', 'gradingPeriods', 'modules', 'sections'])
})

test('includes selected filters', function () {
  this.gradebook.setSelectedViewOptionsFilters(['gradingPeriods', 'modules'])
  const props = this.gradebook.getFilterSettingsViewOptionsMenuProps()
  deepEqual(props.selected, ['gradingPeriods', 'modules'])
})

test('onSelect sets the selected filters', function () {
  const props = this.gradebook.getFilterSettingsViewOptionsMenuProps()
  props.onSelect(['gradingPeriods', 'sections'])
  deepEqual(this.gradebook.listSelectedViewOptionsFilters(), ['gradingPeriods', 'sections'])
})

test('onSelect renders the view options menu after setting the selected filters', function () {
  const props = this.gradebook.getFilterSettingsViewOptionsMenuProps()
  this.gradebook.renderViewOptionsMenu.callsFake(() => {
    strictEqual(this.gradebook.listSelectedViewOptionsFilters().length, 2, 'filters were updated')
  })
  props.onSelect(['gradingPeriods', 'sections'])
})

test('onSelect renders the filters after setting the selected filters', function () {
  const props = this.gradebook.getFilterSettingsViewOptionsMenuProps()
  this.gradebook.renderFilters.callsFake(() => {
    strictEqual(this.gradebook.listSelectedViewOptionsFilters().length, 2, 'filters were updated')
  })
  props.onSelect(['gradingPeriods', 'sections'])
})

test('onSelect saves settings after setting the selected filters', function () {
  const props = this.gradebook.getFilterSettingsViewOptionsMenuProps()
  this.gradebook.saveSettings.callsFake(() => {
    strictEqual(this.gradebook.listSelectedViewOptionsFilters().length, 2, 'filters were updated')
  })
  props.onSelect(['gradingPeriods', 'sections'])
})

QUnit.module('Gradebook#updateStudentGroupFilterVisibility', hooks => {
  let gradebook
  let container

  hooks.beforeEach(() => {
    const studentGroupFilterContainerSelector = 'student-group-filter-container'
    setFixtureHtml($fixtures)
    container = $fixtures.querySelector(`#${studentGroupFilterContainerSelector}`)

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

  hooks.afterEach(() => {
    $fixtures.innerHTML = ''
  })

  test('renders the student group filter when not already rendered', () => {
    gradebook.updateStudentGroupFilterVisibility()
    const filter = ContentFilterDriver.findWithLabelText('Student Group Filter', container)
    ok(filter, 'student group menu was rendered')
  })

  test('does not render when there are no student groups', () => {
    gradebook.studentGroupsEnabled = false
    gradebook.updateStudentGroupFilterVisibility()
    strictEqual(container.children.length, 0, 'nothing was rendered')
  })

  test('does not render when filter is not selected', () => {
    gradebook.setSelectedViewOptionsFilters(['assignmentGroups'])
    gradebook.updateStudentGroupFilterVisibility()
    strictEqual(container.children.length, 0, 'rendered elements have been removed')
  })

  test('renders the filter with group sets at the top level', () => {
    gradebook.updateStudentGroupFilterVisibility()
    const filter = ContentFilterDriver.findWithLabelText('Student Group Filter', container)
    filter.clickToExpand()
    deepEqual(filter.optionGroupLabels, ['First Group Set', 'Second Group Set'])
  })

  test('renders the filter with all groups', () => {
    gradebook.updateStudentGroupFilterVisibility()
    const filter = ContentFilterDriver.findWithLabelText('Student Group Filter', container)
    filter.clickToExpand()
    deepEqual(filter.optionLabels.slice(1), [
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
    equal(filter.selectedItemLabel, 'Second Group Set 2')
  })

  test('sets the filter as disabled when students are not loaded', () => {
    gradebook.updateStudentGroupFilterVisibility()
    const filter = ContentFilterDriver.findWithLabelText('Student Group Filter', container)
    filter.clickToExpand()
    strictEqual(filter.isDisabled, true)
  })

  test('sets the filter as not disabled when students are loaded', () => {
    gradebook.setStudentsLoaded(true)
    gradebook.updateStudentGroupFilterVisibility()
    const filter = ContentFilterDriver.findWithLabelText('Student Group Filter', container)
    filter.clickToExpand()
    strictEqual(filter.isDisabled, false)
  })

  test('updates the disabled state of the rendered filter', () => {
    gradebook.updateStudentGroupFilterVisibility()
    gradebook.setStudentsLoaded(true)
    gradebook.updateStudentGroupFilterVisibility()
    const filter = ContentFilterDriver.findWithLabelText('Student Group Filter', container)
    filter.clickToExpand()
    strictEqual(filter.isDisabled, false)
  })

  test('renders only one student group filter when updated', () => {
    gradebook.updateStudentGroupFilterVisibility()
    gradebook.updateStudentGroupFilterVisibility()
    strictEqual(container.children.length, 1)
  })

  test('removes the filter when the "view student group filter" option is turned off', () => {
    gradebook.setSelectedViewOptionsFilters(['assignmentGroups'])
    gradebook.updateStudentGroupFilterVisibility()
    strictEqual(container.children.length, 0)
  })
})

QUnit.module('Gradebook#updateSectionFilterVisibility', {
  setup() {
    const sectionsFilterContainerSelector = 'sections-filter-container'
    setFixtureHtml($fixtures)
    this.container = $fixtures.querySelector(`#${sectionsFilterContainerSelector}`)
    const sections = [
      {id: '2001', name: 'Freshmen / First-Year'},
      {id: '2002', name: 'Sophomores'},
    ]
    this.gradebook = createGradebook({sections})
    this.gradebook.sections_enabled = true
    this.gradebook.setSelectedViewOptionsFilters(['sections'])
  },

  teardown() {
    $fixtures.innerHTML = ''
  },
})

test('renders the section filter when not already rendered', function () {
  this.gradebook.updateSectionFilterVisibility()
  ok(this.container.children.length > 0, 'section menu was rendered')
})

test('does not render when only one section exists', function () {
  this.gradebook.sections_enabled = false
  this.gradebook.updateSectionFilterVisibility()
  strictEqual(this.container.children.length, 0, 'nothing was rendered')
})

test('does not render when filter is not selected', function () {
  this.gradebook.setSelectedViewOptionsFilters(['assignmentGroups'])
  this.gradebook.updateSectionFilterVisibility()
  strictEqual(this.container.children.length, 0, 'rendered elements have been removed')
})

test('renders the filter with a list of sections', function () {
  this.gradebook.updateSectionFilterVisibility()
  const filter = ContentFilterDriver.findWithLabelText('Section Filter', this.container)
  filter.clickToExpand()
  deepEqual(filter.optionLabels.slice(1), ['Freshmen / First-Year', 'Sophomores'])
})

test('sets the filter to show the saved "filter rows by" setting', function () {
  this.gradebook.setFilterRowsBySetting('sectionId', '2002')
  this.gradebook.updateSectionFilterVisibility()
  const filter = ContentFilterDriver.findWithLabelText('Section Filter', this.container)
  filter.clickToExpand()
  equal(filter.selectedItemLabel, 'Sophomores')
})

test('sets the filter as disabled when students are not loaded', function () {
  this.gradebook.updateSectionFilterVisibility()
  const filter = ContentFilterDriver.findWithLabelText('Section Filter', this.container)
  filter.clickToExpand()
  strictEqual(filter.isDisabled, true)
})

test('sets the filter as not disabled when students are loaded', function () {
  this.gradebook.setStudentsLoaded(true)
  this.gradebook.updateSectionFilterVisibility()
  const filter = ContentFilterDriver.findWithLabelText('Section Filter', this.container)
  filter.clickToExpand()
  strictEqual(filter.isDisabled, false)
})

test('updates the disabled state of the rendered filter', function () {
  this.gradebook.updateSectionFilterVisibility()
  this.gradebook.setStudentsLoaded(true)
  this.gradebook.updateSectionFilterVisibility()
  const filter = ContentFilterDriver.findWithLabelText('Section Filter', this.container)
  filter.clickToExpand()
  strictEqual(filter.isDisabled, false)
})

test('renders only one section filter when updated', function () {
  this.gradebook.updateSectionFilterVisibility()
  this.gradebook.updateSectionFilterVisibility()
  strictEqual(this.container.children.length, 1)
})

test('removes the filter when the "view section filter" option is turned off', function () {
  this.gradebook.setSelectedViewOptionsFilters(['assignmentGroups'])
  this.gradebook.updateSectionFilterVisibility()
  strictEqual(this.container.children.length, 0)
})

QUnit.module('Gradebook#renderStudentSearchFilter', {
  setup() {
    setFixtureHtml($fixtures)
    this.gradebook = createGradebook()
    this.gradebook.setStudentsLoaded(true)
    this.gradebook.setSubmissionsLoaded(true)
    this.gradebook.renderStudentSearchFilter([])
  },

  teardown() {
    $fixtures.innerHTML = ''
  },
})

QUnit.module('Gradebook#updateCurrentSection', {
  setup() {
    this.server = sinon.fakeServer.create({respondImmediately: true})
    this.server.respondWith([200, {}, ''])
    this.postGradesStore = PostGradesStore({
      course: {id: '1', sis_id: null},
      selected: {id: '1', type: 'course'},
    })
    this.postGradesStore.setSelectedSection = sinon.stub()

    this.gradebook = createGradebook({
      settings_update_url: '/settingUrl',
      postGradesStore: this.postGradesStore,
    })
    sinon.stub(this.gradebook, 'saveSettings').callsFake(() => Promise.resolve())
    sandbox.stub(this.gradebook, 'updateSectionFilterVisibility')
  },

  teardown() {
    this.server.restore()
  },
})

test('updates the filter setting with the given section id', function () {
  this.gradebook.updateCurrentSection('2001')
  strictEqual(this.gradebook.getFilterRowsBySetting('sectionId'), '2001')
})

test('sets the selected section on the post grades store', function () {
  this.gradebook.updateCurrentSection('2001')
  strictEqual(this.postGradesStore.setSelectedSection.callCount, 3)
})

test('includes the selected section when updating the post grades store', function () {
  this.gradebook.updateCurrentSection('2001')
  const [sectionId] = this.postGradesStore.setSelectedSection.thirdCall.args
  strictEqual(sectionId, '2001')
})

test('saves settings', function () {
  this.gradebook.updateCurrentSection('2001')
  strictEqual(this.gradebook.saveSettings.callCount, 1)
})

test('saves settings after updating the filter setting', function () {
  this.gradebook.updateCurrentSection('2001')
  strictEqual(
    this.gradebook.getFilterRowsBySetting('sectionId'),
    '2001',
    'section was already updated'
  )
})

test('has no effect when the section has not changed', function () {
  this.gradebook.setFilterRowsBySetting('sectionId', '2001')
  this.gradebook.updateCurrentSection('2001')
  strictEqual(this.gradebook.saveSettings.callCount, 0, 'saveSettings was not called')
  strictEqual(
    this.gradebook.updateSectionFilterVisibility.callCount,
    0,
    'updateSectionFilterVisibility was not called'
  )
})

QUnit.module('Gradebook#isFilteringColumnsByGradingPeriod', {
  setup() {
    this.gradebook = createGradebook()
    this.gradebook.gradingPeriodSet = {id: '1501', gradingPeriods: [{id: '701'}, {id: '702'}]}
    this.gradebook.setFilterColumnsBySetting('gradingPeriodId', '702')
    this.gradebook.setCurrentGradingPeriod()
  },
})

test('returns true when the "filter columns by" setting includes a grading period', function () {
  strictEqual(this.gradebook.isFilteringColumnsByGradingPeriod(), true)
})

test('returns false when the "filter columns by" setting includes the "all grading periods" value ("0")', function () {
  this.gradebook.setFilterColumnsBySetting('gradingPeriodId', '0')
  this.gradebook.setCurrentGradingPeriod()
  strictEqual(this.gradebook.isFilteringColumnsByGradingPeriod(), false)
})

test('returns false when the "filter columns by" setting does not include a grading period', function () {
  this.gradebook.setFilterColumnsBySetting('gradingPeriodId', null)
  this.gradebook.setCurrentGradingPeriod()
  strictEqual(this.gradebook.isFilteringColumnsByGradingPeriod(), false)
})

test('returns false when the "filter columns by" setting does not include a valid grading period', function () {
  this.gradebook.setFilterColumnsBySetting('gradingPeriodId', '799')
  this.gradebook.setCurrentGradingPeriod()
  strictEqual(this.gradebook.isFilteringColumnsByGradingPeriod(), false)
})

test('returns false when no grading period set exists', function () {
  this.gradebook.gradingPeriodSet = null
  this.gradebook.setCurrentGradingPeriod()
  strictEqual(this.gradebook.isFilteringColumnsByGradingPeriod(), false)
})

test('returns true when the "filter columns by" setting is null and the current_grading_period_id is set', function () {
  this.gradebook.options.current_grading_period_id = '701'
  this.gradebook.setFilterColumnsBySetting('gradingPeriodId', null)
  this.gradebook.setCurrentGradingPeriod()
  strictEqual(this.gradebook.isFilteringColumnsByGradingPeriod(), true)
})

QUnit.module('Gradebook#filterAssignments', {
  setup() {
    this.assignments = [
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
    this.gradebook = createGradebook()
    this.gradebook.assignments = {
      2301: this.assignments[0],
      2302: this.assignments[1],
      2303: this.assignments[2],
      2304: this.assignments[3],
    }
    this.gradebook.students = {
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
    this.gradebook.gotSubmissionsChunk(submissionsChunk)
    this.gradebook.setAssignmentGroups([
      {id: '1', name: 'Assignments', position: 1},
      {id: '2', name: 'Homework', position: 2},
    ])
    this.gradebook.courseContent.gradingPeriodAssignments = {
      1401: ['2301', '2303'],
      1402: ['2302', '2304'],
    }
    this.gradebook.courseContent.contextModules = [
      {id: '1', name: 'Algebra', position: 1},
      {id: '2', name: 'English', position: 2},
    ]
    this.gradebook.gradingPeriodSet = {
      id: '1501',
      gradingPeriods: [
        {id: '1401', title: 'Grading Period #1'},
        {id: '1402', title: 'Grading Period #2'},
      ],
    }
    this.gradebook.gridDisplaySettings.showUnpublishedAssignments = true
    this.gradebook.show_attendance = true
    this.gradebook.setAssignmentsLoaded()
    this.gradebook.setSubmissionsLoaded(true)
  },
})

test('when filtering by assignments, only includes assignments in the filter', function () {
  this.gradebook.setFilterColumnsBySetting('gradingPeriodId', '0')
  this.gradebook.searchFilteredAssignmentIds = ['2301', '2304']
  const assignments = this.gradebook.filterAssignments(this.assignments)
  propEqual(
    assignments.map(a => a.id),
    ['2301', '2304']
  )
})

test('does not filter assignments when the filtered IDs is an empty array', function () {
  this.gradebook.setFilterColumnsBySetting('gradingPeriodId', '0')
  this.gradebook.filteredAssignmentIds = []
  const assignments = this.gradebook.filterAssignments(this.assignments)
  propEqual(
    assignments.map(a => a.id),
    ['2301', '2302', '2304']
  )
})

test('excludes "not_graded" assignments', function () {
  const assignments = this.gradebook.filterAssignments(this.assignments)
  strictEqual(
    assignments.findIndex(assignment => assignment.id === '2303'),
    -1
  )
})

test('excludes "unpublished" assignments when "showUnpublishedAssignments" is false', function () {
  this.gradebook.gridDisplaySettings.showUnpublishedAssignments = false
  const assignments = this.gradebook.filterAssignments(this.assignments)
  strictEqual(
    assignments.findIndex(assignment => assignment.id === '2302'),
    -1
  )
})

test('includes "unpublished" assignments when "showUnpublishedAssignments" is true', function () {
  this.gradebook.gridDisplaySettings.showUnpublishedAssignments = true
  const assignments = this.gradebook.filterAssignments(this.assignments)
  notEqual(
    assignments.findIndex(assignment => assignment.id === '2302'),
    -1
  )
})

test('excludes "attendance" assignments when "show_attendance" is false', function () {
  this.gradebook.show_attendance = false
  const assignments = this.gradebook.filterAssignments(this.assignments)
  strictEqual(
    assignments.findIndex(assignment => assignment.id === '2304'),
    -1
  )
})

test('includes "attendance" assignments when "show_attendance" is true', function () {
  this.gradebook.show_attendance = true
  const assignments = this.gradebook.filterAssignments(this.assignments)
  notEqual(
    assignments.findIndex(assignment => assignment.id === '2304'),
    -1
  )
})

test('includes assignments from all grading periods when not filtering by grading period', function () {
  this.gradebook.setFilterColumnsBySetting('gradingPeriodId', '0') // value indicates "All Grading Periods"
  const assignments = this.gradebook.filterAssignments(this.assignments)
  deepEqual(map(assignments, 'id'), ['2301', '2302', '2304'])
})

test('excludes assignments from other grading periods when filtering by a grading period', function () {
  this.gradebook.setFilterColumnsBySetting('gradingPeriodId', '1401')
  this.gradebook.setCurrentGradingPeriod()
  const assignments = this.gradebook.filterAssignments(this.assignments)
  deepEqual(map(assignments, 'id'), ['2301'])
})

test('includes assignments from all grading periods grading period set has not been assigned', function () {
  this.gradebook.gradingPeriodSet = null
  this.gradebook.setFilterColumnsBySetting('gradingPeriodId', '1401')
  const assignments = this.gradebook.filterAssignments(this.assignments)
  deepEqual(map(assignments, 'id'), ['2301', '2302', '2304'])
})

test('includes assignments from all modules when not filtering by module', function () {
  this.gradebook.setFilterColumnsBySetting('contextModuleId', '0') // All Modules
  const assignments = this.gradebook.filterAssignments(this.assignments)
  deepEqual(map(assignments, 'id'), ['2301', '2302', '2304'])
})

test('excludes assignments from other modules when filtering by a module', function () {
  this.gradebook.setFilterColumnsBySetting('contextModuleId', '2')
  const assignments = this.gradebook.filterAssignments(this.assignments)
  deepEqual(map(assignments, 'id'), ['2301'])
})

test('does not filter assignments when filtering by a module that was deleted', function () {
  this.gradebook.courseContent.contextModules = []
  this.gradebook.setFilterColumnsBySetting('contextModuleId', '2')
  const assignments = this.gradebook.filterAssignments(this.assignments)
  deepEqual(map(assignments, 'id'), ['2301', '2302', '2304'])
})

test('includes assignments from all assignment groups when not filtering by assignment group', function () {
  this.gradebook.setFilterColumnsBySetting('assignmentGroupId', '0') // All Modules
  const assignments = this.gradebook.filterAssignments(this.assignments)
  deepEqual(map(assignments, 'id'), ['2301', '2302', '2304'])
})

test('excludes assignments from other assignment groups when filtering by an assignment group', function () {
  this.gradebook.setFilterColumnsBySetting('assignmentGroupId', '2')
  const assignments = this.gradebook.filterAssignments(this.assignments)
  deepEqual(map(assignments, 'id'), ['2302'])
})

test('includes assignments filtered by submissions status', function () {
  this.gradebook.props.appliedFilters = [
    {
      id: '1',
      type: 'submissions',
      value: 'missing',
      created_at: new Date().toISOString(),
    },
  ]
  this.gradebook.setFilterColumnsBySetting('submissions', 'missing')
  const filteredAssignments = this.gradebook.filterAssignments(this.assignments)
  deepEqual(map(filteredAssignments, 'id'), ['2302'])
})

test('includes no assignments when filtered by non existent submissions status', function () {
  this.gradebook.props.appliedFilters = [
    {
      id: '1',
      type: 'submissions',
      value: 'extended',
      created_at: new Date().toISOString(),
    },
  ]
  this.gradebook.setFilterColumnsBySetting('submissions', 'missing')
  const filteredAssignments = this.gradebook.filterAssignments(this.assignments)
  deepEqual(map(filteredAssignments, 'id'), [])
})

test('includes assignments when filtered by existing status and searchFilteredStudentIds matches the submission', function () {
  this.gradebook.props.appliedFilters = [
    {
      id: '1',
      type: 'submissions',
      value: 'missing',
      created_at: new Date().toISOString(),
    },
  ]
  this.gradebook.searchFilteredStudentIds = ['1101']
  this.gradebook.setFilterColumnsBySetting('submissions', 'missing')
  const filteredAssignments = this.gradebook.filterAssignments(this.assignments)
  deepEqual(map(filteredAssignments, 'id'), ['2302'])
})

test('includes no assignments when filtered by existing status but searchFilteredStudentIds does not match submission', function () {
  this.gradebook.props.appliedFilters = [
    {
      id: '1',
      type: 'submissions',
      value: 'missing',
      created_at: new Date().toISOString(),
    },
  ]
  this.gradebook.searchFilteredStudentIds = ['1102']
  this.gradebook.setFilterColumnsBySetting('submissions', 'missing')
  const filteredAssignments = this.gradebook.filterAssignments(this.assignments)
  deepEqual(map(filteredAssignments, 'id'), [])
})

test('allows for multiselect when filtering by status and multiselect_gradebook_filters_enabled', function () {
  window.ENV.GRADEBOOK_OPTIONS = {
    multiselect_gradebook_filters_enabled: true,
  }
  this.gradebook.props.appliedFilters = [
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
  const filteredAssignments = this.gradebook.filterAssignments(this.assignments)
  deepEqual(map(filteredAssignments, 'id'), ['2301', '2302'])
})

test('does not allows for multiselect when filtering by status and multiselect_gradebook_filters_enabled is false', function () {
  window.ENV.GRADEBOOK_OPTIONS = {
    multiselect_gradebook_filters_enabled: false,
  }
  this.gradebook.props.appliedFilters = [
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
  const filteredAssignments = this.gradebook.filterAssignments(this.assignments)
  deepEqual(map(filteredAssignments, 'id'), [])
})

QUnit.module('Gradebook#filterStudents', {
  setup() {
    this.students = [
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
    this.gradebook = createGradebook({
      settings: {
        show_concluded_enrollments: 'false',
        show_inactive_enrollments: 'false',
      },
    })
  },
})

test('returns selected student when filtering by student and section with an active enrollment ', function () {
  this.gradebook.props.appliedFilters = [
    {
      id: '1',
      type: 'section',
      created_at: '',
      value: 'section1',
    },
  ]
  this.gradebook.searchFilteredStudentIds = ['1']
  const filteredStudents = this.gradebook.filterStudents(this.students)
  deepEqual(map(filteredStudents, 'id'), ['1'])
})

test('does not return selected student when filtering by student and section with a concluded enrollment', function () {
  this.gradebook.props.appliedFilters = [
    {
      id: '1',
      type: 'section',
      created_at: '',
      value: 'section2',
    },
  ]
  this.gradebook.searchFilteredStudentIds = ['1']
  const filteredStudents = this.gradebook.filterStudents(this.students)
  deepEqual(map(filteredStudents, 'id'), [])
})

test('returns selected student when filtering by student and section with a concluded enrollment and the show concluded enrollments filter on', function () {
  const gradebook = createGradebook({
    settings: {
      show_concluded_enrollments: 'true',
      show_inactive_enrollments: 'false',
    },
  })
  gradebook.props.appliedFilters = [
    {
      id: '1',
      type: 'section',
      created_at: '',
      value: 'section2',
    },
  ]
  gradebook.searchFilteredStudentIds = ['1']
  const filteredStudents = gradebook.filterStudents(this.students)
  deepEqual(map(filteredStudents, 'id'), ['1'])
})

test('does not return selected student when filtering by student and section with an inactive enrollment', function () {
  this.gradebook.props.appliedFilters = [
    {
      id: '1',
      type: 'section',
      created_at: '',
      value: 'section3',
    },
  ]
  this.gradebook.searchFilteredStudentIds = ['1']
  const filteredStudents = this.gradebook.filterStudents(this.students)
  deepEqual(map(filteredStudents, 'id'), [])
})

test('returns selected student when filtering by student and section with an inactive enrollment and the show inactive enrollments filter on', function () {
  const gradebook = createGradebook({
    settings: {
      show_concluded_enrollments: 'false',
      show_inactive_enrollments: 'true',
    },
  })
  gradebook.props.appliedFilters = [
    {
      id: '1',
      type: 'section',
      created_at: '',
      value: 'section3',
    },
  ]
  gradebook.searchFilteredStudentIds = ['1']
  const filteredStudents = gradebook.filterStudents(this.students)
  deepEqual(map(filteredStudents, 'id'), ['1'])
})

QUnit.module('Gradebook#getSelectedEnrollmentFilters')

test('returns empty array when all settings are off', () => {
  const gradebook = createGradebook({
    settings: {
      show_concluded_enrollments: 'false',
      show_inactive_enrollments: 'false',
    },
  })
  equal(gradebook.getSelectedEnrollmentFilters().length, 0)
})

test('returns array including "concluded" when setting is on', () => {
  const gradebook = createGradebook({
    settings: {
      show_concluded_enrollments: 'true',
      show_inactive_enrollments: 'false',
    },
  })

  ok(gradebook.getSelectedEnrollmentFilters().includes('concluded'))
  notOk(gradebook.getSelectedEnrollmentFilters().includes('inactive'))
})

test('returns array including "inactive" when setting is on', () => {
  const gradebook = createGradebook({
    settings: {
      show_concluded_enrollments: 'false',
      show_inactive_enrollments: 'true',
    },
  })
  ok(gradebook.getSelectedEnrollmentFilters().includes('inactive'))
  notOk(gradebook.getSelectedEnrollmentFilters().includes('concluded'))
})

test('returns array including multiple values when settings are on', () => {
  const gradebook = createGradebook({
    settings: {
      show_concluded_enrollments: 'true',
      show_inactive_enrollments: 'true',
    },
  })
  ok(gradebook.getSelectedEnrollmentFilters().includes('inactive'))
  ok(gradebook.getSelectedEnrollmentFilters().includes('concluded'))
})

QUnit.module('Gradebook#toggleEnrollmentFilter', {
  setup() {
    this.gradebook = createGradebook()
    this.gradebook.gradebookGrid.gridSupport = {
      columns: {
        updateColumnHeaders: sinon.stub(),
      },
    }
    sandbox.stub(this.gradebook, 'saveSettings').callsFake(() => Promise.resolve())
  },
})

test('changes the value of @getSelectedEnrollmentFilters', function () {
  studentRowHeaderConstants.enrollmentFilterKeys.forEach(key => {
    const previousValue = this.gradebook.getSelectedEnrollmentFilters().includes(key)
    this.gradebook.toggleEnrollmentFilter(key, true)
    const newValue = this.gradebook.getSelectedEnrollmentFilters().includes(key)
    notEqual(previousValue, newValue)
  })
})

test('saves settings', function () {
  this.gradebook.toggleEnrollmentFilter('inactive')
  strictEqual(this.gradebook.saveSettings.callCount, 1)
})

test('updates the student column header', async function () {
  await this.gradebook.toggleEnrollmentFilter('inactive')
  strictEqual(this.gradebook.gradebookGrid.gridSupport.columns.updateColumnHeaders.callCount, 1)
})

test('includes the "student" column id when updating column headers', async function () {
  await this.gradebook.toggleEnrollmentFilter('inactive')
  const [columnIds] =
    this.gradebook.gradebookGrid.gridSupport.columns.updateColumnHeaders.lastCall.args
  deepEqual(columnIds, ['student'])
})

QUnit.module('Gradebook#updateCurrentModule', {
  setup() {
    this.server = sinon.fakeServer.create({respondImmediately: true})
    this.server.respondWith([200, {}, ''])

    setFixtureHtml($fixtures)

    this.gradebook = createGradebook({
      settings: {
        filter_columns_by: {
          context_module_id: '2',
        },
        selected_view_options_filters: ['modules'],
      },
    })
    this.gradebook.setContextModules([
      {id: '1', name: 'Module 1', position: 1},
      {id: '2', name: 'Another Module', position: 2},
      {id: '3', name: 'Module 2', position: 3},
    ])
    sinon.spy(this.gradebook, 'setFilterColumnsBySetting')
    sandbox.spy($, 'ajaxJSON')
    sandbox.stub(this.gradebook, 'updateFilteredContentInfo')
    sandbox.stub(this.gradebook, 'updateColumnsAndRenderViewOptionsMenu')
  },

  teardown() {
    this.server.restore()
  },
})

test('updates the filter setting with the given module id', function () {
  this.gradebook.updateCurrentModule('1')
  strictEqual(this.gradebook.getFilterColumnsBySetting('contextModuleId'), '1')
})

test('saves settings with the new filter setting', function () {
  this.gradebook.updateCurrentModule('1')

  strictEqual(
    $.ajaxJSON.getCall(0).args[2].gradebook_settings.filter_columns_by.context_module_id,
    '1'
  )
})

test('has no effect when the module has not changed', function () {
  this.gradebook.updateCurrentModule('2')
  strictEqual($.ajaxJSON.callCount, 0, 'saveSettings was not called')
  strictEqual(
    this.gradebook.updateFilteredContentInfo.callCount,
    0,
    'setAssignmentVisibility was not called'
  )
  strictEqual(
    this.gradebook.updateColumnsAndRenderViewOptionsMenu.callCount,
    0,
    'updateColumnsAndRenderViewOptionsMenu was not called'
  )
})

QUnit.module('Gradebook#updateCurrentAssignmentGroup', {
  setup() {
    this.server = sinon.fakeServer.create({respondImmediately: true})
    this.server.respondWith([200, {}, ''])

    setFixtureHtml($fixtures)

    this.gradebook = createGradebook({
      settings: {
        filter_columns_by: {
          assignment_group_id: '2',
        },
        selected_view_options_filters: ['assignmentGroups'],
      },
    })
    this.gradebook.setAssignmentGroups({
      1: {id: '1', name: 'First'},
      2: {id: '2', name: 'Second'},
    })
    sinon.spy(this.gradebook, 'setFilterColumnsBySetting')
    sandbox.spy($, 'ajaxJSON')
    sandbox.stub(this.gradebook, 'updateFilteredContentInfo')
    sandbox.stub(this.gradebook, 'updateColumnsAndRenderViewOptionsMenu')
  },

  teardown() {
    this.server.restore()
  },
})

test('updates the filter setting with the given assignment group id', function () {
  this.gradebook.updateCurrentAssignmentGroup('1')
  strictEqual(this.gradebook.getFilterColumnsBySetting('assignmentGroupId'), '1')
})

test('saves settings with the new filter setting', function () {
  this.gradebook.updateCurrentAssignmentGroup('1')

  strictEqual(
    $.ajaxJSON.getCall(0).args[2].gradebook_settings.filter_columns_by.assignment_group_id,
    '1'
  )
})

test('has no effect when the assignment group has not changed', function () {
  this.gradebook.updateCurrentAssignmentGroup('2')
  strictEqual($.ajaxJSON.callCount, 0, 'saveSettings was not called')
  strictEqual(
    this.gradebook.updateFilteredContentInfo.callCount,
    0,
    'setAssignmentVisibility was not called'
  )
  strictEqual(
    this.gradebook.updateColumnsAndRenderViewOptionsMenu.callCount,
    0,
    'updateColumnsAndRenderViewOptionsMenu was not called'
  )
})

QUnit.module('Gradebook (3)', () => {
  QUnit.module('Gradebook#getActionMenuProps', hooks => {
    let options

    hooks.beforeEach(() => {
      setFixtureHtml($fixtures)
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

    hooks.afterEach(() => {
      $fixtures.innerHTML = ''
    })

    test('sets publishGradesToSis.isEnabled to true when "publish to SIS" is enabled', () => {
      options.publish_to_sis_enabled = true
      const gradebook = createGradebook(options)
      const props = gradebook.getActionMenuProps()
      strictEqual(props.publishGradesToSis.isEnabled, true)
    })

    test('sets publishGradesToSis.isEnabled to false when "publish to SIS" is not enabled', () => {
      options.publish_to_sis_enabled = false
      const gradebook = createGradebook(options)
      const props = gradebook.getActionMenuProps()
      strictEqual(props.publishGradesToSis.isEnabled, false)
    })

    test('sets gradingPeriodId', () => {
      const gradebook = createGradebook(options)
      const props = gradebook.getActionMenuProps()
      strictEqual(props.gradingPeriodId, '702')
    })
  })

  QUnit.module('#updateFilterSettings', hooks => {
    let gradebook
    let currentFilters
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
        selected_view_options_filters: currentFilters,
      },
      isModulesLoading: false,
      modules: [
        {id: '1', name: 'Module 1', position: 1},
        {id: '2', name: 'Another Module', position: 2},
        {id: '3', name: 'Module 2', position: 3},
      ],
    }

    hooks.beforeEach(() => {
      setFixtureHtml($fixtures)
      currentFilters = ['assignmentGroups', 'modules', 'gradingPeriods', 'sections']
      gradebook = createGradebook(options)
      gradebook.setAssignmentGroups({
        1: {id: '1', name: 'Assignment Group #1'},
        2: {id: '2', name: 'Assignment Group #2'},
      })

      sinon.spy(gradebook, 'setFilterColumnsBySetting')
      sinon
        .stub(gradebook, 'saveSettings')
        .callsFake((_context_id, gradebook_settings) => Promise.resolve(gradebook_settings))
      sinon.stub(gradebook, 'resetGrading')
      sinon.stub(gradebook, 'sortGridRows')
      sinon.stub(gradebook, 'updateFilteredContentInfo')
      sinon.stub(gradebook, 'updateColumnsAndRenderViewOptionsMenu')
      sinon.stub(gradebook, 'renderViewOptionsMenu')
      sinon.stub(gradebook, 'renderActionMenu')
    })

    hooks.afterEach(() => {
      gradebook = null
      $fixtures.innerHTML = ''
    })

    test('getFilterColumnsBySetting returns the assignment group filter setting', () => {
      strictEqual(gradebook.getFilterColumnsBySetting('assignmentGroupId'), '2')
    })

    test(
      'deletes the assignment group filter setting when the filter is hidden ' +
        'and assignment groups have loaded',
      () => {
        gradebook.setAssignmentGroupsLoaded(true)
        gradebook.updateFilterSettings(currentFilters.filter(type => type !== 'assignmentGroups'))
        strictEqual(gradebook.getFilterColumnsBySetting('assignmentGroupId'), null)
      }
    )

    test(
      'does not delete the assignment group filter setting when the filter is ' +
        'hidden and assignment groups have not loaded',
      () => {
        gradebook.updateFilterSettings(currentFilters.filter(type => type !== 'assignmentGroups'))
        strictEqual(gradebook.getFilterColumnsBySetting('assignmentGroupId'), '2')
      }
    )

    test('getFilterColumnsBySetting returns the grading period filter setting', () => {
      strictEqual(gradebook.getFilterColumnsBySetting('gradingPeriodId'), '1402')
    })

    test('deletes the grading period filter setting when the filter is hidden', () => {
      gradebook.updateFilterSettings(currentFilters.filter(type => type !== 'gradingPeriods'))
      strictEqual(gradebook.getFilterColumnsBySetting('gradingPeriodId'), null)
    })

    test('getFilterColumnsBySetting returns the modules filter setting', () => {
      strictEqual(gradebook.getFilterColumnsBySetting('contextModuleId'), '2')
    })

    test('deletes the modules filter setting when the filter is hidden and modules have loaded', () => {
      gradebook.updateFilterSettings(currentFilters.filter(type => type !== 'modules'))
      strictEqual(gradebook.getFilterColumnsBySetting('contextModuleId'), null)
    })

    test('does not delete the modules filter setting when the filter is hidden and modules have not loaded', () => {
      gradebook = createGradebook({
        ...options,
        isModulesLoading: true,
      })
      gradebook.updateFilterSettings(currentFilters.filter(type => type !== 'modules'))
      strictEqual(gradebook.getFilterColumnsBySetting('contextModuleId'), '2')
    })

    test('getFilterColumnsBySetting returns the sections filter setting', () => {
      strictEqual(gradebook.getFilterRowsBySetting('sectionId'), '2001')
    })

    test('deletes the sections filter setting when the filter is hidden', () => {
      gradebook.updateFilterSettings(currentFilters.filter(type => type !== 'sections'))
      strictEqual(gradebook.getFilterRowsBySetting('sectionId'), null)
    })
  })
})

QUnit.module('Gradebook#hideAggregateColumns', {
  createGradebook() {
    const gradebook = createGradebook({
      all_grading_periods_totals: false,
    })
    gradebook.gradingPeriodSet = {id: '1', gradingPeriods: [{id: '701'}, {id: '702'}]}
    return gradebook
  },
})

test('returns false if there are no grading periods', function () {
  const gradebook = this.createGradebook()
  gradebook.gradingPeriodSet = null
  notOk(hideAggregateColumns(gradebook.gradingPeriodSet, gradebook.gradingPeriodId))
})

test('returns false if there are no grading periods, even if isAllGradingPeriods is true', function () {
  const gradebook = this.createGradebook()
  gradebook.gradingPeriodSet = null
  gradebook.setFilterColumnsBySetting('gradingPeriodId', '0')
  notOk(hideAggregateColumns(gradebook.gradingPeriodSet, gradebook.gradingPeriodId))
})

test('returns false if "All Grading Periods" is not selected', function () {
  const gradebook = this.createGradebook()
  gradebook.gradingPeriodId = '701'
  gradebook.setFilterColumnsBySetting('gradingPeriodId', '701')
  notOk(hideAggregateColumns(gradebook.gradingPeriodSet, gradebook.gradingPeriodId))
})

test('returns true if "All Grading Periods" is selected', function () {
  const gradebook = this.createGradebook()
  gradebook.setFilterColumnsBySetting('gradingPeriodId', '0')
  ok(hideAggregateColumns(gradebook.gradingPeriodSet, gradebook.gradingPeriodId))
})

test(
  'returns false if "All Grading Periods" is selected and the grading period set has' +
    ' "Display Totals for All Grading Periods option" enabled',
  function () {
    const gradebook = this.createGradebook()
    gradebook.setFilterColumnsBySetting('gradingPeriodId', '0')
    gradebook.gradingPeriodSet.displayTotalsForAllGradingPeriods = true
    notOk(hideAggregateColumns(gradebook.gradingPeriodSet, gradebook.gradingPeriodId))
  }
)

QUnit.module('#listHiddenAssignments', hooks => {
  let gradebook
  let gradedAssignment
  let notGradedAssignment

  hooks.beforeEach(() => {
    gradedAssignment = {
      assignment_group: {position: 1},
      assignment_group_id: '1',
      grading_type: 'online_text_entry',
      id: '2301',
      name: 'graded assignment',
      position: 1,
      published: true,
    }
    notGradedAssignment = {
      assignment_group: {position: 2},
      assignment_group_id: '2',
      grading_type: 'not_graded',
      id: '2302',
      name: 'not graded assignment',
      position: 2,
      published: true,
    }
    const submissionsChunk = [
      {
        submissions: [
          {
            assignment_id: '2301',
            id: '2501',
            posted_at: null,
            score: 10,
            user_id: '1101',
            workflow_state: 'graded',
          },
          {
            assignment_id: '2302',
            id: '2502',
            posted_at: null,
            score: 9,
            user_id: '1101',
            workflow_state: 'graded',
          },
        ],
        user_id: '1101',
      },
    ]
    gradebook = createGradebook()
    gradebook.assignments = {
      2301: gradedAssignment,
      2302: notGradedAssignment,
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
      {
        id: '1',
        assignments: [gradedAssignment],
      },
      {
        id: '2',
        assignments: [notGradedAssignment],
      },
    ])
    gradebook.setAssignmentsLoaded()
    gradebook.setSubmissionsLoaded(true)
  })

  test('includes assignments when submission is postable', function () {
    const hiddenAssignments = gradebook.listHiddenAssignments('1101')
    ok(hiddenAssignments.find(assignment => assignment.id === gradedAssignment.id))
  })

  test('excludes "not_graded" assignments even when submission is postable', function () {
    const hiddenAssignments = gradebook.listHiddenAssignments('1101')
    notOk(hiddenAssignments.find(assignment => assignment.id === notGradedAssignment.id))
  })

  test('ignores assignments excluded by the current set of filters', function () {
    gradebook.setFilterColumnsBySetting('assignmentGroupId', '2')

    const hiddenAssignments = gradebook.listHiddenAssignments('1101')
    notOk(hiddenAssignments.find(assignment => assignment.id === gradedAssignment.id))
  })
})

QUnit.module('Gradebook#updateGradingPeriodFilterVisibility', {
  setup() {
    const sectionsFilterContainerSelector = 'grading-periods-filter-container'
    setFixtureHtml($fixtures)
    this.container = $fixtures.querySelector(`#${sectionsFilterContainerSelector}`)
    this.gradebook = createGradebook({
      grading_period_set: {
        id: '1501',
        grading_periods: [
          {id: '701', title: 'Grading Period 1', startDate: new Date(1)},
          {id: '702', title: 'Grading Period 2', startDate: new Date(2)},
        ],
      },
    })
    this.gradebook.setSelectedViewOptionsFilters(['gradingPeriods'])
  },

  teardown() {
    $fixtures.innerHTML = ''
  },
})

test('renders the grading period filter when not already rendered', function () {
  this.gradebook.updateGradingPeriodFilterVisibility()
  ok(this.container.children.length > 0, 'grading period menu was rendered')
})

test('does not render when a grading period set does not exist', function () {
  this.gradebook.gradingPeriodSet = null
  this.gradebook.updateGradingPeriodFilterVisibility()
  strictEqual(this.container.children.length, 0, 'nothing was rendered')
})

test('does not render when filter is not selected', function () {
  this.gradebook.setSelectedViewOptionsFilters(['assignmentGroups'])
  this.gradebook.updateGradingPeriodFilterVisibility()
  strictEqual(this.container.children.length, 0, 'rendered elements have been removed')
})

test('renders the filter with a list of grading periods', function () {
  this.gradebook.updateGradingPeriodFilterVisibility()
  const filter = ContentFilterDriver.findWithLabelText('Grading Period Filter', this.container)
  filter.clickToExpand()
  deepEqual(filter.optionLabels.slice(1), ['Grading Period 1', 'Grading Period 2'])
})

test('sets the filter to show the selected grading period', function () {
  this.gradebook.setFilterColumnsBySetting('gradingPeriodId', '702')
  this.gradebook.setCurrentGradingPeriod()
  this.gradebook.updateGradingPeriodFilterVisibility()
  const filter = ContentFilterDriver.findWithLabelText('Grading Period Filter', this.container)
  filter.clickToExpand()
  equal(filter.selectedItemLabel, 'Grading Period 2')
})

test('renders only one grading period filter when updated', function () {
  this.gradebook.updateGradingPeriodFilterVisibility()
  this.gradebook.updateGradingPeriodFilterVisibility()
  const filter = ContentFilterDriver.findWithLabelText('Grading Period Filter', this.container)
  filter.clickToExpand()
  strictEqual(this.container.children.length, 1)
})

test('removes the filter when the "view grading period filter" option is turned off', function () {
  this.gradebook.setSelectedViewOptionsFilters(['assignmentGroups'])
  this.gradebook.updateGradingPeriodFilterVisibility()
  strictEqual(this.container.children.length, 0)
})

QUnit.module('Gradebook#setCurrentGradingPeriod', hooks => {
  let gradebook

  hooks.beforeEach(() => {
    gradebook = createGradebook({
      grading_period_set: {
        id: '1501',
        grading_periods: [
          {id: '701', weight: 50},
          {id: '702', weight: 50},
        ],
        weighted: true,
      },
    })
  })

  test('sets grading period id to "0" if no grading period set exists', () => {
    gradebook.setFilterColumnsBySetting('gradingPeriodId', '702')
    gradebook.gradingPeriodSet = null
    gradebook.setCurrentGradingPeriod()
    strictEqual(gradebook.gradingPeriodId, '0')
  })

  test('sets grading period id to "0" if "All Grading Periods" is selected', () => {
    gradebook.setFilterColumnsBySetting('gradingPeriodId', '0')
    gradebook.setCurrentGradingPeriod()
    strictEqual(gradebook.gradingPeriodId, '0')
  })

  test('sets grading period id to the grading period being filtered by', () => {
    gradebook.setFilterColumnsBySetting('gradingPeriodId', '702')
    gradebook.setCurrentGradingPeriod()
    strictEqual(gradebook.gradingPeriodId, '702')
  })

  test('if not filtered, sets grading period id to the current_grading_period_id', () => {
    gradebook.options.current_grading_period_id = '702'
    gradebook.setCurrentGradingPeriod()
    strictEqual(gradebook.gradingPeriodId, '702')
  })

  test('if the saved grading period id is not in the set, sets period id to "0"', () => {
    gradebook.options.current_grading_period_id = '1000'
    gradebook.setCurrentGradingPeriod()
    strictEqual(gradebook.gradingPeriodId, '0')
  })
})

QUnit.module('Gradebook#updateCurrentGradingPeriod', {
  setup() {
    this.server = sinon.fakeServer.create({respondImmediately: true})
    this.server.respondWith([200, {}, ''])

    setFixtureHtml($fixtures)

    this.gradebook = createGradebook({
      grading_period_set: {
        id: '1501',
        grading_periods: [
          {id: '1401', title: 'Grading Period #1'},
          {id: '1402', title: 'Grading Period #2'},
        ],
      },
      settings: {
        filter_columns_by: {
          grading_period_id: '1402',
        },
        selected_view_options_filters: ['gradingPeriods'],
      },
    })
    sinon.spy(this.gradebook, 'saveSettings')
    sandbox.stub(this.gradebook, 'resetGrading')
    sandbox.stub(this.gradebook, 'sortGridRows')
    sandbox.stub(this.gradebook, 'updateFilteredContentInfo')
    sandbox.stub(this.gradebook, 'updateColumnsAndRenderViewOptionsMenu')
    sandbox.stub(this.gradebook, 'renderActionMenu')
  },

  teardown() {
    this.server.restore()
    $fixtures.innerHTML = ''
  },
})

test('updates the filter setting with the given grading period id', function () {
  this.gradebook.updateCurrentGradingPeriod('1401')
  strictEqual(this.gradebook.getFilterColumnsBySetting('gradingPeriodId'), '1401')
})

test('saves settings after updating the filter setting', function () {
  this.gradebook.updateCurrentGradingPeriod('1401')
  strictEqual(
    this.gradebook.getFilterColumnsBySetting('gradingPeriodId'),
    '1401',
    'setting was already updated'
  )
})

test('resets grading after updating the filter setting', function () {
  this.gradebook.updateCurrentGradingPeriod('1401')
  strictEqual(this.gradebook.resetGrading.callCount, 1)
})

test('sorts grid grows after resetting grading', function () {
  this.gradebook.sortGridRows.callsFake(() => {
    strictEqual(this.gradebook.resetGrading.callCount, 1, 'grading was already reset')
  })
  this.gradebook.updateCurrentGradingPeriod('1401')
})

test('sets assignment warnings after resetting grading', function () {
  this.gradebook.updateFilteredContentInfo.callsFake(() => {
    strictEqual(this.gradebook.resetGrading.callCount, 1, 'grading was already reset')
  })
  this.gradebook.updateCurrentGradingPeriod('1401')
})

test('updates columns and menus after settings assignment warnings', function () {
  this.gradebook.updateColumnsAndRenderViewOptionsMenu.callsFake(() => {
    strictEqual(
      this.gradebook.updateFilteredContentInfo.callCount,
      1,
      'assignment warnings were already set'
    )
  })
  this.gradebook.updateCurrentGradingPeriod('1401')
})

test('has no effect when the grading period has not changed', function () {
  this.gradebook.updateCurrentGradingPeriod('1402')
  strictEqual(this.gradebook.saveSettings.callCount, 0, 'saveSettings was not called')
  strictEqual(this.gradebook.resetGrading.callCount, 0, 'resetGrading was not called')
  strictEqual(
    this.gradebook.updateFilteredContentInfo.callCount,
    0,
    'setAssignmentVisibility was not called'
  )
  strictEqual(
    this.gradebook.updateColumnsAndRenderViewOptionsMenu.callCount,
    0,
    'updateColumnsAndRenderViewOptionsMenu was not called'
  )
})

test('renders the action menu', function () {
  this.gradebook.updateCurrentGradingPeriod('1401')
  strictEqual(this.gradebook.renderActionMenu.callCount, 1)
})
