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
