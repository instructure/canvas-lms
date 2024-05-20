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

import $ from 'jquery'
import 'jquery-migrate'
import fakeENV from 'helpers/fakeENV'
import {
  createGradebook,
  setFixtureHtml,
} from 'ui/features/gradebook/react/default_gradebook/__tests__/GradebookSpecHelper'
import SlickGridSpecHelper from './GradebookGrid/GridSupport/SlickGridSpecHelper'

QUnit.module('Gradebook Grid Columns', suiteHooks => {
  let $fixture
  let gridSpecHelper
  let gradebook

  let assignmentGroups
  let assignments
  let contextModules
  let customColumns

  function createAssignments() {
    assignments = {
      homework: [
        {
          id: '2301',
          assignment_group_id: '2201',
          course_id: '1201',
          html_url: '/assignments/2301',
          muted: false,
          name: 'Math Assignment',
          omit_from_final_grade: false,
          position: 1,
          published: true,
          submission_types: ['online_text_entry'],
        },
      ],

      quizzes: [
        {
          id: '2302',
          assignment_group_id: '2202',
          course_id: '1201',
          html_url: '/assignments/2302',
          muted: false,
          name: 'English Assignment',
          omit_from_final_grade: false,
          position: 1,
          published: true,
          submission_types: ['online_text_entry'],
        },
      ],
    }
  }

  function createAssignmentGroups() {
    assignmentGroups = [
      {id: '2201', position: 1, name: 'Homework', assignments: assignments.homework},
      {id: '2202', position: 2, name: 'Quizzes', assignments: assignments.quizzes},
    ]
  }

  function createContextModules() {
    contextModules = [
      {id: '2601', name: 'Science', position: 1},
      {id: '2602', name: 'Math', position: 2},
    ]
  }

  function createCustomColumns() {
    customColumns = [
      {id: '2401', teacher_notes: true, hidden: false, title: 'Notes'},
      {id: '2402', teacher_notes: false, hidden: false, title: 'Other Notes'},
    ]
  }

  function addStudentIds() {
    gradebook.updateStudentIds(['1101'])
  }

  function addGradingPeriodAssignments() {
    gradebook.updateGradingPeriodAssignments({1401: ['2301'], 1402: ['2302']})
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

  function createGradebookAndAddData(options) {
    gradebook = createGradebook(options)
    sinon.stub(gradebook, 'saveSettings').callsFake(() => Promise.resolve())
    addGridData()
  }

  suiteHooks.beforeEach(() => {
    $fixture = document.createElement('div')
    document.body.appendChild($fixture)
    setFixtureHtml($fixture)

    fakeENV.setup({
      current_user_id: '1101',
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

  QUnit.module('when initializing the grid', hooks => {
    hooks.beforeEach(() => {
      createGradebookAndAddData()
      gridSpecHelper = new SlickGridSpecHelper(gradebook.gradebookGrid)
    })

    test('adds the student column to the grid as a frozen column', () => {
      ok(gridSpecHelper.listFrozenColumnIds().includes('student'))
    })

    test('adds the total grade column to the grid as a scrollable column', () => {
      ok(gridSpecHelper.listScrollableColumnIds().includes('total_grade'))
    })

    test('adds each assignment column to the grid', () => {
      const columns = gridSpecHelper.listColumns().filter(column => column.type === 'assignment')
      deepEqual(
        columns.map(column => column.id),
        ['assignment_2301', 'assignment_2302']
      )
    })

    test('adds each assignment group column to the grid', () => {
      const columns = gridSpecHelper
        .listColumns()
        .filter(column => column.type === 'assignment_group')
      deepEqual(
        columns.map(column => column.id),
        ['assignment_group_2201', 'assignment_group_2202']
      )
    })

    test('freezes custom columns', () => {
      const columnIds = gridSpecHelper
        .listFrozenColumnIds()
        .filter(columnId => columnId.match(/^custom_col_/))
      deepEqual(columnIds.sort(), ['custom_col_2401', 'custom_col_2402'])
    })

    test('does not freeze assignment columns', () => {
      const columnIds = gridSpecHelper
        .listScrollableColumnIds()
        .filter(columnId => columnId.match(/^assignment_(?!group)/))
      deepEqual(columnIds.sort(), ['assignment_2301', 'assignment_2302'])
    })

    test('does not freeze assignment group columns', () => {
      const columnIds = gridSpecHelper
        .listScrollableColumnIds()
        .filter(columnId => columnId.match(/^assignment_group_/))
      deepEqual(columnIds.sort(), ['assignment_group_2201', 'assignment_group_2202'])
    })
  })

  QUnit.module('when reordering columns with drag and drop', hooks => {
    let reorderApiResponse
    let reorderEventData

    hooks.beforeEach(() => {
      createGradebookAndAddData()
      gridSpecHelper = new SlickGridSpecHelper(gradebook.gradebookGrid)
      reorderApiResponse = $.Deferred()
      sinon.stub(gradebook.props, 'reorderCustomColumns').returns(reorderApiResponse)
      sinon.stub(gradebook, 'saveCustomColumnOrder')
      gradebook.gradebookGrid.events.onColumnsReordered.subscribe((_event, columns) => {
        reorderEventData = columns
      })
      reorderEventData = null
    })

    // unskip in FOO-4349
    QUnit.skip('updates the stored custom column order when custom columns were reordered', () => {
      gridSpecHelper.updateColumnOrder([
        'student',
        'custom_col_2402',
        'custom_col_2401',
        'assignment_2301',
        'assignment_2302',
        'assignment_group_2201',
        'assignment_group_2202',
        'total_grade',
      ])
      reorderApiResponse.resolve()
      deepEqual(
        gradebook.gradebookContent.customColumns.map(column => column.id),
        ['2402', '2401']
      )
    })

    test('stores "custom" column order when assignment columns were reordered', () => {
      gridSpecHelper.updateColumnOrder([
        'student',
        'custom_col_2401',
        'custom_col_2402',
        'assignment_2302',
        'assignment_2301',
        'assignment_group_2201',
        'assignment_group_2202',
        'total_grade',
      ])
      strictEqual(gradebook.saveCustomColumnOrder.callCount, 1)
    })

    test('stores "custom" column order when assignment group columns were reordered', () => {
      gridSpecHelper.updateColumnOrder([
        'student',
        'custom_col_2401',
        'custom_col_2402',
        'assignment_2301',
        'assignment_2302',
        'assignment_group_2202',
        'assignment_group_2201',
        'total_grade',
      ])
      strictEqual(gradebook.saveCustomColumnOrder.callCount, 1)
    })

    test('triggers the "onColumnsReordered" event with updated frozen columns', () => {
      gridSpecHelper.updateColumnOrder([
        'student',
        'custom_col_2402',
        'custom_col_2401',
        'assignment_2301',
        'assignment_2302',
        'assignment_group_2201',
        'assignment_group_2202',
        'total_grade',
      ])
      deepEqual(
        reorderEventData.frozen.map(column => column.id),
        ['student', 'custom_col_2402', 'custom_col_2401']
      )
    })

    test('triggers the "onColumnsReordered" event with updated scrollable columns', () => {
      gridSpecHelper.updateColumnOrder([
        'student',
        'custom_col_2401',
        'custom_col_2402',
        'assignment_2302',
        'assignment_2301',
        'assignment_group_2201',
        'assignment_group_2202',
        'total_grade',
      ])
      const expectedOrder = [
        'assignment_2302',
        'assignment_2301',
        'assignment_group_2201',
        'assignment_group_2202',
        'total_grade',
      ]
      deepEqual(
        reorderEventData.scrollable.map(column => column.id),
        expectedOrder
      )
    })

    test('does not trigger the "onColumnsReordered" event when column order did not change', () => {
      const spy = sinon.spy()
      gradebook.gradebookGrid.events.onColumnsReordered.subscribe(spy)
      gridSpecHelper.updateColumnOrder([
        'student',
        'custom_col_2401',
        'custom_col_2402',
        'assignment_2301',
        'assignment_2302',
        'assignment_group_2201',
        'assignment_group_2202',
        'total_grade',
      ])
      strictEqual(spy.callCount, 0)
    })
  })

  QUnit.module('when rearranging scrollable columns', hooks => {
    hooks.beforeEach(() => {
      createGradebookAndAddData()
      gridSpecHelper = new SlickGridSpecHelper(gradebook.gradebookGrid)
    })

    test('reorders sortable grid columns to match intended ascending sort order', () => {
      gradebook.arrangeColumnsBy({sortBy: 'default', direction: 'ascending'})
      const expectedOrder = [
        'assignment_2301',
        'assignment_2302',
        'assignment_group_2201',
        'assignment_group_2202',
        'total_grade',
      ]
      deepEqual(gridSpecHelper.listScrollableColumnIds(), expectedOrder)
    })

    test('reorders sortable grid columns to match intended descending sort order', () => {
      gradebook.arrangeColumnsBy({sortBy: 'default', direction: 'descending'})
      const expectedOrder = [
        'assignment_2302',
        'assignment_2301',
        'assignment_group_2201',
        'assignment_group_2202',
        'total_grade',
      ]
      deepEqual(gridSpecHelper.listScrollableColumnIds(), expectedOrder)
    })

    test('does not reorder frozen grid columns', () => {
      gridSpecHelper.updateColumnOrder([
        'custom_col_2402',
        'student',
        'custom_col_2401',
        'assignment_2301',
        'assignment_2302',
        'assignment_group_2202',
        'assignment_group_2201',
        'total_grade',
      ])
      gradebook.arrangeColumnsBy({sortBy: 'default', direction: 'ascending'})
      deepEqual(gridSpecHelper.listFrozenColumnIds(), [
        'custom_col_2402',
        'student',
        'custom_col_2401',
      ])
    })
  })

  QUnit.module('when freezing the total grade column', hooks => {
    hooks.beforeEach(() => {
      createGradebookAndAddData()
      gridSpecHelper = new SlickGridSpecHelper(gradebook.gradebookGrid)
    })

    test('places the total grade column after the student column', () => {
      gradebook.freezeTotalGradeColumn()
      deepEqual(gridSpecHelper.listFrozenColumnIds(), [
        'student',
        'total_grade',
        'custom_col_2401',
        'custom_col_2402',
      ])
    })

    test('removes the total grade column from the scrollable columns', () => {
      gradebook.freezeTotalGradeColumn()
      const expectedOrder = [
        'assignment_2301',
        'assignment_2302',
        'assignment_group_2201',
        'assignment_group_2202',
      ]
      deepEqual(gridSpecHelper.listScrollableColumnIds(), expectedOrder)
    })

    test('preserves relative order of frozen columns', () => {
      gridSpecHelper.updateColumnOrder([
        'student',
        'custom_col_2402',
        'custom_col_2401',
        'assignment_group_2202',
        'assignment_2302',
        'total_grade',
        'assignment_group_2201',
        'assignment_2301',
      ])
      gradebook.freezeTotalGradeColumn()
      deepEqual(gridSpecHelper.listFrozenColumnIds(), [
        'student',
        'total_grade',
        'custom_col_2402',
        'custom_col_2401',
      ])
    })

    test('preserves relative order of other scrollable columns', () => {
      gridSpecHelper.updateColumnOrder([
        'student',
        'custom_col_2402',
        'custom_col_2401',
        'assignment_group_2202',
        'assignment_2302',
        'total_grade',
        'assignment_group_2201',
        'assignment_2301',
      ])
      gradebook.freezeTotalGradeColumn()
      const expectedOrder = [
        'assignment_group_2202',
        'assignment_2302',
        'assignment_group_2201',
        'assignment_2301',
      ]
      deepEqual(gridSpecHelper.listScrollableColumnIds(), expectedOrder)
    })
  })

  QUnit.module(
    'when moving the frozen total grade column to the end of the scrollable columns',
    hooks => {
      hooks.beforeEach(() => {
        createGradebookAndAddData()
        gridSpecHelper = new SlickGridSpecHelper(gradebook.gradebookGrid)
        gradebook.freezeTotalGradeColumn()
      })

      // unskip in FOO-4349
      QUnit.skip('removes the total grade column from the frozen columns', () => {
        gradebook.moveTotalGradeColumnToEnd()
        deepEqual(gridSpecHelper.listFrozenColumnIds(), [
          'student',
          'custom_col_2401',
          'custom_col_2402',
        ])
      })

      // unskip in FOO-4349
      QUnit.skip('places the total grade column after all scrollable columns', () => {
        gradebook.moveTotalGradeColumnToEnd()
        const expectedOrder = [
          'assignment_2301',
          'assignment_2302',
          'assignment_group_2201',
          'assignment_group_2202',
          'total_grade',
        ]
        deepEqual(gridSpecHelper.listScrollableColumnIds(), expectedOrder)
      })

      // unskip in FOO-4349
      QUnit.skip('preserves relative order of frozen columns', () => {
        gridSpecHelper.updateColumnOrder([
          'student',
          'custom_col_2402',
          'total_grade',
          'custom_col_2401',
          'assignment_group_2202',
          'assignment_2302',
          'assignment_group_2201',
          'assignment_2301',
        ])
        gradebook.moveTotalGradeColumnToEnd()
        deepEqual(gridSpecHelper.listFrozenColumnIds(), [
          'student',
          'custom_col_2402',
          'custom_col_2401',
        ])
      })

      // unskip in FOO-4349
      QUnit.skip('preserves relative order of other scrollable columns', () => {
        gridSpecHelper.updateColumnOrder([
          'student',
          'custom_col_2402',
          'total_grade',
          'custom_col_2401',
          'assignment_group_2202',
          'assignment_2302',
          'assignment_group_2201',
          'assignment_2301',
        ])
        gradebook.moveTotalGradeColumnToEnd()
        const expectedOrder = [
          'assignment_group_2202',
          'assignment_2302',
          'assignment_group_2201',
          'assignment_2301',
          'total_grade',
        ]
        deepEqual(gridSpecHelper.listScrollableColumnIds(), expectedOrder)
      })
    }
  )

  QUnit.module(
    'when moving the scrollable total grade column to the end of scrollable columns',
    hooks => {
      hooks.beforeEach(() => {
        createGradebookAndAddData()
        gridSpecHelper = new SlickGridSpecHelper(gradebook.gradebookGrid)
      })

      test('places the total grade column after all scrollable columns', () => {
        gridSpecHelper.updateColumnOrder([
          'student',
          'custom_col_2401',
          'custom_col_2402',
          'assignment_2301',
          'assignment_2302',
          'total_grade',
          'assignment_group_2201',
          'assignment_group_2202',
        ])
        gradebook.moveTotalGradeColumnToEnd()
        const expectedOrder = [
          'assignment_2301',
          'assignment_2302',
          'assignment_group_2201',
          'assignment_group_2202',
          'total_grade',
        ]
        deepEqual(gridSpecHelper.listScrollableColumnIds(), expectedOrder)
      })

      test('preserves order of frozen columns', () => {
        gridSpecHelper.updateColumnOrder([
          'student',
          'custom_col_2402',
          'custom_col_2401',
          'assignment_group_2202',
          'assignment_2302',
          'total_grade',
          'assignment_group_2201',
          'assignment_2301',
        ])
        gradebook.moveTotalGradeColumnToEnd()
        deepEqual(gridSpecHelper.listFrozenColumnIds(), [
          'student',
          'custom_col_2402',
          'custom_col_2401',
        ])
      })

      test('preserves relative order of other scrollable columns', () => {
        gridSpecHelper.updateColumnOrder([
          'student',
          'custom_col_2402',
          'custom_col_2401',
          'assignment_group_2202',
          'assignment_2302',
          'total_grade',
          'assignment_group_2201',
          'assignment_2301',
        ])
        gradebook.moveTotalGradeColumnToEnd()
        const expectedOrder = [
          'assignment_group_2202',
          'assignment_2302',
          'assignment_group_2201',
          'assignment_2301',
          'total_grade',
        ]
        deepEqual(gridSpecHelper.listScrollableColumnIds(), expectedOrder)
      })
    }
  )

  QUnit.module('when using grading periods', hooks => {
    function initializeAndAddData() {
      addGridData()
      gridSpecHelper = new SlickGridSpecHelper(gradebook.gradebookGrid)
    }

    hooks.beforeEach(() => {
      gradebook = createGradebook({
        grading_period_set: {
          id: '1301',
          display_totals_for_all_grading_periods: false,
          grading_periods: [
            {id: '1401', title: 'Grading Period 1'},
            {id: '1402', title: 'Grading Period 2'},
          ],
        },
      })
      sinon.stub(gradebook, 'saveSettings').callsFake(() => Promise.resolve())
    })

    test('excludes assignment group columns when setting is disabled', () => {
      initializeAndAddData()
      const columns = gridSpecHelper
        .listColumns()
        .filter(column => column.type === 'assignment_group')
      deepEqual(
        columns.map(column => column.id),
        []
      )
    })

    test('excludes the total grade column when setting is disabled', () => {
      initializeAndAddData()
      const columns = gridSpecHelper.listColumns().filter(column => column.type === 'total_grade')
      deepEqual(
        columns.map(column => column.id),
        []
      )
    })

    test('includes assignment group and total grade columns when setting is enabled', () => {
      gradebook.gradingPeriodSet.displayTotalsForAllGradingPeriods = true
      initializeAndAddData()
      const columns = gridSpecHelper
        .listColumns()
        .filter(column => column.type === 'assignment_group')
      deepEqual(
        columns.map(column => column.id),
        ['assignment_group_2201', 'assignment_group_2202']
      )
    })

    test('includes the total grade column when setting is enabled', () => {
      gradebook.gradingPeriodSet.displayTotalsForAllGradingPeriods = true
      initializeAndAddData()
      const columns = gridSpecHelper.listColumns().filter(column => column.type === 'total_grade')
      deepEqual(
        columns.map(column => column.id),
        ['total_grade']
      )
    })
  })

  QUnit.module('when changing column filters', hooks => {
    hooks.beforeEach(() => {
      createGradebookAndAddData({
        grading_period_set: {
          id: '1301',
          display_totals_for_all_grading_periods: true,
          grading_periods: [
            {
              id: '1401',
              title: 'Grading Period 1',
              start_date: Date(),
              end_date: Date(),
              close_date: Date(),
            },
            {
              id: '1402',
              title: 'Grading Period 2',
              start_date: Date(),
              end_date: Date(),
              close_date: Date(),
            },
          ],
        },
        settings: {
          selected_view_options_filters: [
            'assignmentGroups',
            'modules',
            'gradingPeriods',
            'sections',
          ],
        },
      })
      gridSpecHelper = new SlickGridSpecHelper(gradebook.gradebookGrid)
      gradebook.getAssignment('2302').published = false
    })

    test('removes unpublished assignment columns when filtered', async () => {
      await gradebook.toggleUnpublishedAssignments()
      const expectedOrder = [
        'assignment_2301',
        'assignment_group_2201',
        'assignment_group_2202',
        'total_grade',
      ]
      deepEqual(gridSpecHelper.listScrollableColumnIds(), expectedOrder)
    })

    test('removes unrelated assignment columns when filtering by assignment group', async () => {
      await gradebook.updateCurrentAssignmentGroup('2202')
      const expectedOrder = [
        'assignment_2302',
        'assignment_group_2201',
        'assignment_group_2202',
        'total_grade',
      ]
      deepEqual(gridSpecHelper.listScrollableColumnIds(), expectedOrder)
    })

    test('removes unrelated assignment columns when filtering by grading period', async () => {
      await gradebook.updateCurrentGradingPeriod('1401')
      const expectedOrder = [
        'assignment_2301',
        'assignment_group_2201',
        'assignment_group_2202',
        'total_grade',
      ]
      deepEqual(gridSpecHelper.listScrollableColumnIds(), expectedOrder)
    })

    test('does not duplicate the total column when filtering by grading period', async () => {
      gradebook.freezeTotalGradeColumn()
      await gradebook.updateCurrentGradingPeriod('1401')
      const totalGradeColumns = gridSpecHelper
        .listFrozenColumnIds()
        .filter(id => id === 'total_grade')
      strictEqual(totalGradeColumns.length, 1)
    })
  })

  QUnit.module('when teacher notes are hidden', hooks => {
    hooks.beforeEach(() => {
      customColumns[0].hidden = true
      createGradebookAndAddData({
        teacher_notes: {id: '2401', title: 'Notes', teacher_notes: true, hidden: true},
      })
      gridSpecHelper = new SlickGridSpecHelper(gradebook.gradebookGrid)
    })

    test('does not include the column in the grid', () => {
      const columns = gridSpecHelper.listColumns().filter(column => column.id.match(/^custom_col_/))
      deepEqual(
        columns.map(column => column.id),
        ['custom_col_2402']
      )
    })

    test('adds the column to the frozen columns when showing', () => {
      gradebook.showNotesColumn()
      deepEqual(gridSpecHelper.listFrozenColumnIds(), [
        'student',
        'custom_col_2401',
        'custom_col_2402',
      ])
    })
  })

  QUnit.module('when hiding the teacher notes column', hooks => {
    hooks.beforeEach(() => {
      createGradebookAndAddData()
      gridSpecHelper = new SlickGridSpecHelper(gradebook.gradebookGrid)
    })

    test('removes the column from the frozen columns', () => {
      gradebook.hideNotesColumn()
      deepEqual(gridSpecHelper.listFrozenColumnIds(), ['student', 'custom_col_2402'])
    })
  })
})
