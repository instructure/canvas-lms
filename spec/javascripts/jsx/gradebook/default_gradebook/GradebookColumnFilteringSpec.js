/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import fakeENV from 'helpers/fakeENV'
import {
  createGradebook,
  setFixtureHtml,
} from 'ui/features/gradebook/react/default_gradebook/__tests__/GradebookSpecHelper'
import SlickGridSpecHelper from './GradebookGrid/GridSupport/SlickGridSpecHelper'

QUnit.module('Gradebook Grid Column Filtering', suiteHooks => {
  let $fixture
  let gridSpecHelper
  let gradebook

  let assignmentGroups
  let assignments
  let contextModules
  let customColumns

  function createGradebookWithAllFilters(options = {}) {
    gradebook = createGradebook({
      settings: {
        selected_view_options_filters: [
          'assignmentGroups',
          'modules',
          'gradingPeriods',
          'sections',
        ],
      },
      ...options,
    })
    sinon
      .stub(gradebook, 'saveSettings')
      .callsFake((_context_id, gradebook_settings) => Promise.resolve(gradebook_settings))
  }

  function createContextModules() {
    contextModules = [
      {id: '2601', position: 3, name: 'Final Module'},
      {id: '2602', position: 2, name: 'Second Module'},
      {id: '2603', position: 1, name: 'First Module'},
    ]
  }

  function createCustomColumns() {
    customColumns = [
      {id: '2401', teacher_notes: true, title: 'Notes'},
      {id: '2402', teacher_notes: false, title: 'Other Notes'},
    ]
  }

  function createAssignments() {
    assignments = {
      homework: [
        {
          id: '2301',
          assignment_group_id: '2201',
          course_id: '1201',
          due_at: '2015-05-04T12:00:00Z',
          html_url: '/assignments/2301',
          module_ids: ['2601'],
          module_positions: [1],
          muted: false,
          name: 'Math Assignment',
          omit_from_final_grade: false,
          points_possible: null,
          position: 1,
          published: true,
          submission_types: ['online_text_entry'],
        },
        {
          id: '2303',
          assignment_group_id: '2201',
          course_id: '1201',
          due_at: '2015-06-04T12:00:00Z',
          html_url: '/assignments/2302',
          module_ids: ['2601'],
          module_positions: [2],
          muted: false,
          name: 'English Assignment',
          omit_from_final_grade: false,
          points_possible: 15,
          position: 2,
          published: true,
          submission_types: ['online_text_entry'],
        },
      ],

      quizzes: [
        {
          id: '2302',
          assignment_group_id: '2202',
          course_id: '1201',
          due_at: '2015-05-05T12:00:00Z',
          html_url: '/assignments/2301',
          module_ids: ['2602'],
          module_positions: [1],
          muted: false,
          name: 'Math Quiz',
          omit_from_final_grade: false,
          points_possible: 10,
          position: 1,
          published: true,
          submission_types: ['online_quiz'],
        },
        {
          id: '2304',
          assignment_group_id: '2202',
          course_id: '1201',
          due_at: '2015-05-11T12:00:00Z',
          html_url: '/assignments/2302',
          module_ids: ['2603'],
          module_positions: [1],
          muted: false,
          name: 'English Quiz',
          omit_from_final_grade: false,
          points_possible: 20,
          position: 2,
          published: true,
          submission_types: ['online_quiz'],
        },
      ],
    }
  }

  function createAssignmentGroups() {
    assignmentGroups = [
      {id: '2201', position: 2, name: 'Homework', assignments: assignments.homework},
      {id: '2202', position: 1, name: 'Quizzes', assignments: assignments.quizzes},
    ]
  }

  function addStudentIds() {
    gradebook.updateStudentIds(['1101'])
  }

  function addGradingPeriodAssignments() {
    gradebook.updateGradingPeriodAssignments({1401: ['2301', '2304'], 1402: ['2302', '2303']})
  }

  function addContextModules() {
    gradebook.updateContextModules(contextModules)
  }

  function addCustomColumns() {
    gradebook.gotCustomColumns(customColumns)
  }

  function addAssignmentGroups() {
    gradebook.updateAssignmentGroups(assignmentGroups)
  }

  function addGridData() {
    addStudentIds()
    addContextModules()
    addCustomColumns()
    addAssignmentGroups()
    addGradingPeriodAssignments()
    gradebook.finishRenderingUI()
  }

  function addData() {
    addGridData()
    gridSpecHelper = new SlickGridSpecHelper(gradebook.gradebookGrid)
  }

  suiteHooks.beforeEach(() => {
    $fixture = document.createElement('div')
    document.body.appendChild($fixture)
    setFixtureHtml($fixture)

    fakeENV.setup({
      current_user_id: '1101',
      // TODO: remove this when we remove the release flag
      GRADEBOOK_OPTIONS: {grading_periods_filter_dates_enabled: true},
    })

    createAssignments()
    createAssignmentGroups()
    createContextModules()
    createCustomColumns()
  })

  suiteHooks.afterEach(() => {
    gradebook.destroy()
    fakeENV.teardown()
    $fixture.remove()
  })

  QUnit.module('with unpublished assignments', hooks => {
    function setShowUnpublishedAssignments(show) {
      gradebook.gridDisplaySettings.showUnpublishedAssignments = show
    }

    hooks.beforeEach(() => {
      assignments.homework[1].published = false
      assignments.quizzes[1].published = false
      createGradebookWithAllFilters()
    })

    test('optionally shows all unpublished assignment columns at initial render', () => {
      setShowUnpublishedAssignments(true)
      addData()
      const expectedColumns = [
        'assignment_2301',
        'assignment_2302',
        'assignment_2303',
        'assignment_2304',
        'assignment_group_2201',
        'assignment_group_2202',
        'total_grade',
      ]
      deepEqual(gridSpecHelper.listScrollableColumnIds().sort(), expectedColumns)
    })

    test('optionally hides all unpublished assignment columns at initial render', () => {
      setShowUnpublishedAssignments(false)
      addData()
      const expectedColumns = [
        'assignment_2301',
        'assignment_2302',
        'assignment_group_2201',
        'assignment_group_2202',
        'total_grade',
      ]
      deepEqual(gridSpecHelper.listScrollableColumnIds().sort(), expectedColumns)
    })

    test('optionally shows all unpublished assignment columns', () => {
      setShowUnpublishedAssignments(false)
      addData()
      gradebook.toggleUnpublishedAssignments()
      const expectedColumns = [
        'assignment_2301',
        'assignment_2302',
        'assignment_2303',
        'assignment_2304',
        'assignment_group_2201',
        'assignment_group_2202',
        'total_grade',
      ]
      deepEqual(gridSpecHelper.listScrollableColumnIds().sort(), expectedColumns)
    })

    test('optionally hides all unpublished assignment columns', () => {
      setShowUnpublishedAssignments(true)
      addData()
      gradebook.toggleUnpublishedAssignments()
      const expectedColumns = [
        'assignment_2301',
        'assignment_2302',
        'assignment_group_2201',
        'assignment_group_2202',
        'total_grade',
      ]
      deepEqual(gridSpecHelper.listScrollableColumnIds().sort(), expectedColumns)
    })

    test('sorts all scrollable columns after showing unpublished assignment columns', () => {
      const customOrder = [
        'student',
        'custom_col_2401',
        'custom_col_2402',
        'total_grade',
        'assignment_group_2201',
        'assignment_2301',
        'assignment_2303',
        'assignment_group_2202',
        'assignment_2302',
        'assignment_2304',
      ]
      setShowUnpublishedAssignments(true)
      addData()
      gridSpecHelper.updateColumnOrder(customOrder)
      gradebook.toggleUnpublishedAssignments() // hide unpublished
      gradebook.toggleUnpublishedAssignments() // show unpublished
      deepEqual(gridSpecHelper.listColumnIds(), customOrder)
    })

    test('sorts all scrollable columns after hiding unpublished assignment columns', () => {
      const customOrder = [
        'student',
        'custom_col_2401',
        'custom_col_2402',
        'total_grade',
        'assignment_group_2201',
        'assignment_2301',
        'assignment_2303',
        'assignment_group_2202',
        'assignment_2302',
        'assignment_2304',
      ]
      setShowUnpublishedAssignments(true)
      addData()
      gridSpecHelper.updateColumnOrder(customOrder)
      gradebook.toggleUnpublishedAssignments()
      const expectedColumns = [
        'student',
        'custom_col_2401',
        'custom_col_2402',
        'total_grade',
        'assignment_group_2201',
        'assignment_2301',
        'assignment_group_2202',
        'assignment_2302',
      ]
      deepEqual(gridSpecHelper.listColumnIds(), expectedColumns)
    })
  })

  QUnit.module('with attendance assignments', hooks => {
    function setShowAttendance(show) {
      gradebook.show_attendance = show
    }

    hooks.beforeEach(() => {
      assignments.homework[0].submission_types = ['attendance']
      assignments.homework[1].submission_types = ['attendance']
      createGradebookWithAllFilters()
    })

    test('optionally shows all attendance assignment columns at initial render', () => {
      setShowAttendance(true)
      addData()
      const expectedColumns = [
        'assignment_2301',
        'assignment_2302',
        'assignment_2303',
        'assignment_2304',
        'assignment_group_2201',
        'assignment_group_2202',
        'total_grade',
      ]
      deepEqual(gridSpecHelper.listScrollableColumnIds().sort(), expectedColumns)
    })

    test('optionally hides all attendance assignment columns at initial render', () => {
      setShowAttendance(false)
      addData()
      const expectedColumns = [
        'assignment_2302',
        'assignment_2304',
        'assignment_group_2201',
        'assignment_group_2202',
        'total_grade',
      ]
      deepEqual(gridSpecHelper.listScrollableColumnIds().sort(), expectedColumns)
    })
  })

  test('does not show "not graded" assignments', () => {
    assignments.homework[1].submission_types = ['not_graded']
    assignments.quizzes[1].submission_types = ['not_graded']
    createGradebookWithAllFilters()
    addData()
    const expectedColumns = [
      'assignment_2301',
      'assignment_2302',
      'assignment_group_2201',
      'assignment_group_2202',
      'total_grade',
    ]
    deepEqual(gridSpecHelper.listScrollableColumnIds().sort(), expectedColumns)
  })

  QUnit.module('with multiple assignment groups', hooks => {
    hooks.beforeEach(() => {
      createGradebookWithAllFilters()
    })

    test('optionally shows assignment columns for all assignment groups at initial render', () => {
      addData()
      gradebook.updateCurrentAssignmentGroup('0')
      const expectedColumns = [
        'assignment_2301',
        'assignment_2302',
        'assignment_2303',
        'assignment_2304',
        'assignment_group_2201',
        'assignment_group_2202',
        'total_grade',
      ]
      deepEqual(gridSpecHelper.listScrollableColumnIds().sort(), expectedColumns)
    })

    test('optionally shows only assignment columns for the selected assignment group at initial render', () => {
      addData()
      gradebook.updateCurrentAssignmentGroup('2201')
      const expectedColumns = [
        'assignment_2301',
        'assignment_2303',
        'assignment_group_2201',
        'assignment_group_2202',
        'total_grade',
      ]
      deepEqual(gridSpecHelper.listScrollableColumnIds().sort(), expectedColumns)
    })

    test('optionally shows assignment columns for all assignment groups', () => {
      addData()
      gradebook.updateCurrentAssignmentGroup('0')
      const expectedColumns = [
        'assignment_2301',
        'assignment_2302',
        'assignment_2303',
        'assignment_2304',
        'assignment_group_2201',
        'assignment_group_2202',
        'total_grade',
      ]
      deepEqual(gridSpecHelper.listScrollableColumnIds().sort(), expectedColumns)
    })

    test('optionally shows only assignment columns for the selected assignment group', () => {
      addData()
      gradebook.updateCurrentAssignmentGroup('2202')
      const expectedColumns = [
        'assignment_2302',
        'assignment_2304',
        'assignment_group_2201',
        'assignment_group_2202',
        'total_grade',
      ]
      deepEqual(gridSpecHelper.listScrollableColumnIds().sort(), expectedColumns)
    })

    test('sorts all scrollable columns after selecting an assignment group', () => {
      const customOrder = [
        'student',
        'custom_col_2401',
        'custom_col_2402',
        'total_grade',
        'assignment_group_2201',
        'assignment_2301',
        'assignment_2303',
        'assignment_group_2202',
        'assignment_2302',
        'assignment_2304',
      ]
      addData()
      gridSpecHelper.updateColumnOrder(customOrder)
      gradebook.updateCurrentAssignmentGroup('2202')
      const expectedColumns = [
        'student',
        'custom_col_2401',
        'custom_col_2402',
        'total_grade',
        'assignment_group_2201',
        'assignment_group_2202',
        'assignment_2302',
        'assignment_2304',
      ]
      deepEqual(gridSpecHelper.listColumnIds(), expectedColumns)
    })

    test('sorts all scrollable columns after deselecting an assignment group', () => {
      const customOrder = [
        'student',
        'custom_col_2401',
        'custom_col_2402',
        'total_grade',
        'assignment_group_2201',
        'assignment_2301',
        'assignment_2303',
        'assignment_group_2202',
        'assignment_2302',
        'assignment_2304',
      ]
      addData()
      gridSpecHelper.updateColumnOrder(customOrder)
      gradebook.updateCurrentAssignmentGroup('2202')
      gradebook.updateCurrentAssignmentGroup('0')
      deepEqual(gridSpecHelper.listColumnIds(), customOrder)
    })
  })

  QUnit.module('with grading periods', hooks => {
    hooks.beforeEach(() => {
      createGradebookWithAllFilters({
        grading_period_set: {
          id: '1501',
          display_totals_for_all_grading_periods: true,
          grading_periods: [
            {id: '1401', title: 'GP1', start_date: Date(), end_date: Date(), close_date: Date()},
            {id: '1402', title: 'GP2', start_date: Date(), end_date: Date(), close_date: Date()},
          ],
        },
      })
    })

    test('optionally shows assignment columns for all grading periods at initial render', () => {
      gradebook.setFilterColumnsBySetting('gradingPeriodId', '0')
      addData()
      const expectedColumns = [
        'assignment_2301',
        'assignment_2302',
        'assignment_2303',
        'assignment_2304',
        'assignment_group_2201',
        'assignment_group_2202',
        'total_grade',
      ]
      deepEqual(gridSpecHelper.listScrollableColumnIds().sort(), expectedColumns)
    })

    test('optionally shows only assignment columns for the selected grading period at initial render', () => {
      gradebook.setFilterColumnsBySetting('gradingPeriodId', '1401')
      gradebook.setCurrentGradingPeriod()
      addData()
      const expectedColumns = [
        'assignment_2301',
        'assignment_2304',
        'assignment_group_2201',
        'assignment_group_2202',
        'total_grade',
      ]
      deepEqual(gridSpecHelper.listScrollableColumnIds().sort(), expectedColumns)
    })

    test('optionally shows assignment columns for all grading periods', () => {
      addData()
      gradebook.updateCurrentGradingPeriod('0')
      const expectedColumns = [
        'assignment_2301',
        'assignment_2302',
        'assignment_2303',
        'assignment_2304',
        'assignment_group_2201',
        'assignment_group_2202',
        'total_grade',
      ]
      deepEqual(gridSpecHelper.listScrollableColumnIds().sort(), expectedColumns)
    })

    test('optionally shows only assignment columns for the selected grading period', () => {
      addData()
      gradebook.updateCurrentGradingPeriod('1402')
      const expectedColumns = [
        'assignment_2302',
        'assignment_2303',
        'assignment_group_2201',
        'assignment_group_2202',
        'total_grade',
      ]
      deepEqual(gridSpecHelper.listScrollableColumnIds().sort(), expectedColumns)
    })

    test('optionally hides assignment group and total grade columns when filtering at initial render', () => {
      gradebook.gradingPeriodSet.displayTotalsForAllGradingPeriods = false
      addData()
      gradebook.setFilterColumnsBySetting('gradingPeriodId', '0')
      const expectedColumns = [
        'assignment_2301',
        'assignment_2302',
        'assignment_2303',
        'assignment_2304',
      ]
      deepEqual(gridSpecHelper.listScrollableColumnIds().sort(), expectedColumns)
    })

    test('optionally hides assignment group and total grade columns when filtering', () => {
      gradebook.gradingPeriodSet.displayTotalsForAllGradingPeriods = false
      addData()
      gradebook.updateCurrentGradingPeriod('0')
      const expectedColumns = [
        'assignment_2301',
        'assignment_2302',
        'assignment_2303',
        'assignment_2304',
      ]
      deepEqual(gridSpecHelper.listScrollableColumnIds().sort(), expectedColumns)
    })

    test('sorts all scrollable columns after selecting a grading period', () => {
      const customOrder = [
        'student',
        'custom_col_2401',
        'custom_col_2402',
        'total_grade',
        'assignment_group_2201',
        'assignment_2301',
        'assignment_2303',
        'assignment_group_2202',
        'assignment_2302',
        'assignment_2304',
      ]
      addData()
      gridSpecHelper.updateColumnOrder(customOrder)
      gradebook.updateCurrentGradingPeriod('1402')
      const expectedColumns = [
        'student',
        'custom_col_2401',
        'custom_col_2402',
        'total_grade',
        'assignment_group_2201',
        'assignment_2303',
        'assignment_group_2202',
        'assignment_2302',
      ]
      deepEqual(gridSpecHelper.listColumnIds(), expectedColumns)
    })

    test('sorts all scrollable columns after deselecting a grading period', () => {
      const customOrder = [
        'student',
        'custom_col_2401',
        'custom_col_2402',
        'total_grade',
        'assignment_group_2201',
        'assignment_2301',
        'assignment_2303',
        'assignment_group_2202',
        'assignment_2302',
        'assignment_2304',
      ]
      addData()
      gridSpecHelper.updateColumnOrder(customOrder)
      gradebook.updateCurrentGradingPeriod('1402')
      gradebook.updateCurrentGradingPeriod('0')
      deepEqual(gridSpecHelper.listColumnIds(), customOrder)
    })
  })

  QUnit.module('with multiple context modules', hooks => {
    hooks.beforeEach(() => {
      createGradebookWithAllFilters()
    })

    test('optionally shows assignment columns for all context modules at initial render', () => {
      gradebook.setFilterColumnsBySetting('contextModuleId', '0')
      addData()
      const expectedColumns = [
        'assignment_2301',
        'assignment_2302',
        'assignment_2303',
        'assignment_2304',
        'assignment_group_2201',
        'assignment_group_2202',
        'total_grade',
      ]
      deepEqual(gridSpecHelper.listScrollableColumnIds().sort(), expectedColumns)
    })

    test('optionally shows only assignment columns for the selected context module at initial render', () => {
      gradebook.setFilterColumnsBySetting('contextModuleId', '2601')
      addData()
      const expectedColumns = [
        'assignment_2301',
        'assignment_2303',
        'assignment_group_2201',
        'assignment_group_2202',
        'total_grade',
      ]
      deepEqual(gridSpecHelper.listScrollableColumnIds().sort(), expectedColumns)
    })

    test('optionally shows assignment columns for all context modules', () => {
      addData()
      gradebook.updateCurrentModule('0')
      const expectedColumns = [
        'assignment_2301',
        'assignment_2302',
        'assignment_2303',
        'assignment_2304',
        'assignment_group_2201',
        'assignment_group_2202',
        'total_grade',
      ]
      deepEqual(gridSpecHelper.listScrollableColumnIds().sort(), expectedColumns)
    })

    test('optionally shows only assignment columns for the selected context module', () => {
      addData()
      gradebook.updateCurrentModule('2602')
      const expectedColumns = [
        'assignment_2302',
        'assignment_group_2201',
        'assignment_group_2202',
        'total_grade',
      ]
      deepEqual(gridSpecHelper.listScrollableColumnIds().sort(), expectedColumns)
    })

    test('sorts all scrollable columns after selecting a context module', () => {
      const customOrder = [
        'student',
        'custom_col_2401',
        'custom_col_2402',
        'total_grade',
        'assignment_group_2201',
        'assignment_2301',
        'assignment_2303',
        'assignment_group_2202',
        'assignment_2302',
        'assignment_2304',
      ]
      addData()
      gridSpecHelper.updateColumnOrder(customOrder)
      gradebook.updateCurrentModule('2601')
      const expectedColumns = [
        'student',
        'custom_col_2401',
        'custom_col_2402',
        'total_grade',
        'assignment_group_2201',
        'assignment_2301',
        'assignment_2303',
        'assignment_group_2202',
      ]
      deepEqual(gridSpecHelper.listColumnIds(), expectedColumns)
    })

    test('sorts all scrollable columns after deselecting a context module', () => {
      const customOrder = [
        'student',
        'custom_col_2401',
        'custom_col_2402',
        'total_grade',
        'assignment_group_2201',
        'assignment_2301',
        'assignment_2303',
        'assignment_group_2202',
        'assignment_2302',
        'assignment_2304',
      ]
      addData()
      gridSpecHelper.updateColumnOrder(customOrder)
      gradebook.updateCurrentModule('2602')
      gradebook.updateCurrentModule('0')
      deepEqual(gridSpecHelper.listColumnIds(), customOrder)
    })
  })
})
