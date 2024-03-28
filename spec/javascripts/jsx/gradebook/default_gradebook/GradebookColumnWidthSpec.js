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

QUnit.module('Gradebook Grid Column Widths', suiteHooks => {
  let $fixture
  let gridSpecHelper
  let gradebook

  let assignmentGroups
  let assignments
  let contextModules
  let customColumns

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
          html_url: '/assignments/2303',
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
          html_url: '/assignments/2302',
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
          html_url: '/assignments/2304',
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
    addGridData()
    gridSpecHelper = new SlickGridSpecHelper(gradebook.gradebookGrid)
  }

  suiteHooks.beforeEach(() => {
    $fixture = document.createElement('div')
    document.body.appendChild($fixture)
    setFixtureHtml($fixture)

    fakeENV.setup({
      current_user_id: '1101',
    })

    createAssignments()
    createAssignmentGroups()
    createContextModules()
    createCustomColumns()
  })

  suiteHooks.afterEach(() => {
    gradebook.gradebookGrid.destroy()
    $(document).unbind('gridready')
    fakeENV.teardown()
    $fixture.remove()
  })

  QUnit.module('when initializing the grid', hooks => {
    hooks.beforeEach(() => {
      gradebook = createGradebook()
      gradebook.gradebookColumnSizeSettings = {assignment_2302: 10, assignment_2303: 54}
      addGridData()
      gridSpecHelper = new SlickGridSpecHelper(gradebook.gradebookGrid)
    })

    test('defaults assignment column size to fit the assignment name', () => {
      const columnNode = gridSpecHelper.getColumnHeaderNode('assignment_2301')
      ok(columnNode.offsetWidth > 10, 'width is not the minimum')
    })

    // unskip in FOO-4349
    QUnit.skip('uses a stored width for assignment column headers', () => {
      const columnNode = gridSpecHelper.getColumnHeaderNode('assignment_2303')
      strictEqual(columnNode.offsetWidth, 54)
    })

    // unskip in FOO-4349
    QUnit.skip('hides assignment column header content when the column is minimized', () => {
      const columnNode = gridSpecHelper.getColumnHeaderNode('assignment_2302')
      ok(columnNode.classList.contains('minimized'))
    })

    // unskip in FOO-4349
    QUnit.skip('hides assignment column cell content when the column is minimized', () => {
      const columnIndex = gridSpecHelper.listColumnIds().indexOf('assignment_2302')
      const cellNode = gradebook.gradebookGrid.grid.getCellNode(0, columnIndex)
      ok(cellNode.classList.contains('minimized'))
    })
  })

  QUnit.module('onColumnsResized', hooks => {
    function resizeColumn(columnId, widthChange) {
      const column = gridSpecHelper.getColumn(columnId)
      const updatedColumn = {...column, width: column.width + widthChange}
      gradebook.gradebookGrid.gridSupport.events.onColumnsResized.trigger(null, [updatedColumn])
    }

    hooks.beforeEach(() => {
      createGradebookAndAddData()
      sinon.stub(gradebook, 'saveColumnWidthPreference')
    })

    test('updates the column definitions for resized columns', () => {
      const originalWidth = gridSpecHelper.getColumn('assignment_2304').width
      resizeColumn('assignment_2304', -20)
      strictEqual(
        gradebook.gradebookGrid.gridData.columns.definitions.assignment_2304.width,
        originalWidth - 20
      )
    })

    test('hides assignment column header content when the column is minimized', () => {
      resizeColumn('assignment_2304', -100)
      const columnNode = gridSpecHelper.getColumnHeaderNode('assignment_2304')
      ok(columnNode.classList.contains('minimized'))
    })

    // unskip in FOO-4349
    QUnit.skip('hides assignment column cell content when the column is minimized', () => {
      resizeColumn('assignment_2304', -100)
      const columnIndex = gridSpecHelper.listColumnIds().indexOf('assignment_2304')
      const cellNode = gradebook.gradebookGrid.grid.getCellNode(0, columnIndex)
      ok(cellNode.classList.contains('minimized'))
    })

    test('unhides assignment column header content when the column is unminimized', () => {
      resizeColumn('assignment_2304', -100)
      resizeColumn('assignment_2304', 1)
      const columnNode = gridSpecHelper.getColumnHeaderNode('assignment_2304')
      notOk(columnNode.classList.contains('minimized'))
    })

    // unskip in FOO-4349
    QUnit.skip('unhides assignment column cell content when the column is unminimized', () => {
      resizeColumn('assignment_2304', -100)
      resizeColumn('assignment_2304', 1)
      const columnIndex = gridSpecHelper.listColumnIds().indexOf('assignment_2304')
      const cellNode = gradebook.gradebookGrid.grid.getCellNode(0, columnIndex)
      notOk(cellNode.classList.contains('minimized'))
    })
  })
})
