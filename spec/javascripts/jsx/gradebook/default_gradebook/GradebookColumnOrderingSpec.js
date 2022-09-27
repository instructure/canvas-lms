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

QUnit.module('Gradebook Grid Column Ordering', suiteHooks => {
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

  function arrangeColumnsBy(sortType, direction) {
    gradebook.arrangeColumnsBy({sortType, direction})
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
    gradebook.destroy()
    fakeENV.teardown()
    $fixture.remove()
  })

  QUnit.module('when initializing the grid', () => {
    test('defaults assignment column order to assignment group positions when setting is not set', () => {
      createGradebookAndAddData()
      const expectedOrder = [
        'assignment_2302',
        'assignment_2304',
        'assignment_2301',
        'assignment_2303',
        'assignment_group_2202',
        'assignment_group_2201',
        'total_grade',
      ]
      deepEqual(gridSpecHelper.listScrollableColumnIds(), expectedOrder)
    })

    test('sorts assignment columns by assignment name when setting is "name"', () => {
      createGradebookAndAddData({
        gradebook_column_order_settings: {sortType: 'name', direction: 'ascending'},
      })
      const expectedOrder = [
        'assignment_2303',
        'assignment_2304',
        'assignment_2301',
        'assignment_2302',
        'assignment_group_2202',
        'assignment_group_2201',
        'total_grade',
      ]
      deepEqual(gridSpecHelper.listScrollableColumnIds(), expectedOrder)
    })

    test('sorts assignment columns by assignment due date when setting is "due date"', () => {
      createGradebookAndAddData({
        gradebook_column_order_settings: {sortType: 'due_date', direction: 'ascending'},
      })
      const expectedOrder = [
        'assignment_2301',
        'assignment_2302',
        'assignment_2304',
        'assignment_2303',
        'assignment_group_2202',
        'assignment_group_2201',
        'total_grade',
      ]
      deepEqual(gridSpecHelper.listScrollableColumnIds(), expectedOrder)
    })

    test('sorts assignment columns by assignment points possible when setting is "points"', () => {
      createGradebookAndAddData({
        gradebook_column_order_settings: {sortType: 'points', direction: 'ascending'},
      })
      const expectedOrder = [
        'assignment_2301',
        'assignment_2302',
        'assignment_2303',
        'assignment_2304',
        'assignment_group_2202',
        'assignment_group_2201',
        'total_grade',
      ]
      deepEqual(gridSpecHelper.listScrollableColumnIds(), expectedOrder)
    })

    test('sorts assignment columns by module position when setting is "module position"', () => {
      createGradebookAndAddData({
        gradebook_column_order_settings: {sortType: 'module_position', direction: 'ascending'},
      })
      const expectedOrder = [
        'assignment_2304',
        'assignment_2302',
        'assignment_2301',
        'assignment_2303',
        'assignment_group_2202',
        'assignment_group_2201',
        'total_grade',
      ]
      deepEqual(gridSpecHelper.listScrollableColumnIds(), expectedOrder)
    })
  })

  QUnit.module('when sorting by default', () => {
    test('sorts assignment columns by assignment group position', () => {
      assignments.homework.splice(1, 1)
      assignments.quizzes.splice(1, 1)
      createGradebookAndAddData()
      arrangeColumnsBy('default', 'ascending')
      const expectedOrder = [
        'assignment_2302',
        'assignment_2301',
        'assignment_group_2202',
        'assignment_group_2201',
        'total_grade',
      ]
      deepEqual(gridSpecHelper.listScrollableColumnIds(), expectedOrder)
    })

    test('additionally sorts assignment columns by position within assignment groups', () => {
      createGradebookAndAddData()
      arrangeColumnsBy('default', 'ascending')
      const expectedOrder = [
        'assignment_2302',
        'assignment_2304',
        'assignment_2301',
        'assignment_2303',
        'assignment_group_2202',
        'assignment_group_2201',
        'total_grade',
      ]
      deepEqual(gridSpecHelper.listScrollableColumnIds(), expectedOrder)
    })

    test('optionally sorts in descending order', () => {
      createGradebookAndAddData()
      arrangeColumnsBy('default', 'descending')
      const expectedOrder = [
        'assignment_2303',
        'assignment_2301',
        'assignment_2304',
        'assignment_2302',
        'assignment_group_2202',
        'assignment_group_2201',
        'total_grade',
      ]
      deepEqual(gridSpecHelper.listScrollableColumnIds(), expectedOrder)
    })
  })

  QUnit.module('when sorting by name', () => {
    test('sorts assignment columns by assignment name', () => {
      createGradebookAndAddData()
      arrangeColumnsBy('name', 'ascending')
      const expectedOrder = [
        'assignment_2303',
        'assignment_2304',
        'assignment_2301',
        'assignment_2302',
        'assignment_group_2202',
        'assignment_group_2201',
        'total_grade',
      ]
      deepEqual(gridSpecHelper.listScrollableColumnIds(), expectedOrder)
    })

    test('optionally sorts in descending order', () => {
      createGradebookAndAddData()
      arrangeColumnsBy('name', 'descending')
      const expectedOrder = [
        'assignment_2302',
        'assignment_2301',
        'assignment_2304',
        'assignment_2303',
        'assignment_group_2202',
        'assignment_group_2201',
        'total_grade',
      ]
      deepEqual(gridSpecHelper.listScrollableColumnIds(), expectedOrder)
    })
  })

  QUnit.module('when sorting by due date', () => {
    test('sorts assignment columns by assignment due date', () => {
      createGradebookAndAddData()
      arrangeColumnsBy('due_date', 'ascending')
      const expectedOrder = [
        'assignment_2301',
        'assignment_2302',
        'assignment_2304',
        'assignment_2303',
        'assignment_group_2202',
        'assignment_group_2201',
        'total_grade',
      ]
      deepEqual(gridSpecHelper.listScrollableColumnIds(), expectedOrder)
    })

    test('sorts assignments with due dates before assignments without due dates', () => {
      assignments.quizzes[0].due_at = null
      createGradebookAndAddData()
      arrangeColumnsBy('due_date', 'ascending')
      const expectedOrder = [
        'assignment_2301',
        'assignment_2304',
        'assignment_2303',
        'assignment_2302',
        'assignment_group_2202',
        'assignment_group_2201',
        'total_grade',
      ]
      deepEqual(gridSpecHelper.listScrollableColumnIds(), expectedOrder)
    })

    test('optionally sorts in descending order', () => {
      createGradebookAndAddData()
      arrangeColumnsBy('due_date', 'descending')
      const expectedOrder = [
        'assignment_2303',
        'assignment_2304',
        'assignment_2302',
        'assignment_2301',
        'assignment_group_2202',
        'assignment_group_2201',
        'total_grade',
      ]
      deepEqual(gridSpecHelper.listScrollableColumnIds(), expectedOrder)
    })
  })

  QUnit.module('when sorting by points', () => {
    test('sorts assignment columns by assignment points possible', () => {
      createGradebookAndAddData()
      arrangeColumnsBy('points', 'ascending')
      const expectedOrder = [
        'assignment_2301',
        'assignment_2302',
        'assignment_2303',
        'assignment_2304',
        'assignment_group_2202',
        'assignment_group_2201',
        'total_grade',
      ]
      deepEqual(gridSpecHelper.listScrollableColumnIds(), expectedOrder)
    })

    test('optionally sorts in descending order', () => {
      createGradebookAndAddData()
      arrangeColumnsBy('points', 'descending')
      const expectedOrder = [
        'assignment_2304',
        'assignment_2303',
        'assignment_2302',
        'assignment_2301',
        'assignment_group_2202',
        'assignment_group_2201',
        'total_grade',
      ]
      deepEqual(gridSpecHelper.listScrollableColumnIds(), expectedOrder)
    })
  })

  QUnit.module('when sorting by module position', () => {
    test('sorts assignment columns by module position', () => {
      assignments.homework.splice(1, 1)
      createGradebookAndAddData()
      arrangeColumnsBy('module_position', 'ascending')
      const expectedOrder = [
        'assignment_2304',
        'assignment_2302',
        'assignment_2301',
        'assignment_group_2202',
        'assignment_group_2201',
        'total_grade',
      ]
      deepEqual(gridSpecHelper.listScrollableColumnIds(), expectedOrder)
    })

    test('additionally sorts assignment columns by position within modules', () => {
      createGradebookAndAddData()
      arrangeColumnsBy('module_position', 'ascending')
      const expectedOrder = [
        'assignment_2304',
        'assignment_2302',
        'assignment_2301',
        'assignment_2303',
        'assignment_group_2202',
        'assignment_group_2201',
        'total_grade',
      ]
      deepEqual(gridSpecHelper.listScrollableColumnIds(), expectedOrder)
    })

    test('sorts assignments with modules before assignments without modules', () => {
      assignments.quizzes[0].module_ids = []
      assignments.quizzes[0].module_positions = []
      createGradebookAndAddData()
      arrangeColumnsBy('module_position', 'ascending')
      const expectedOrder = [
        'assignment_2304',
        'assignment_2301',
        'assignment_2303',
        'assignment_2302',
        'assignment_group_2202',
        'assignment_group_2201',
        'total_grade',
      ]
      deepEqual(gridSpecHelper.listScrollableColumnIds(), expectedOrder)
    })

    test('optionally sorts in descending order', () => {
      createGradebookAndAddData()
      arrangeColumnsBy('module_position', 'descending')
      const expectedOrder = [
        'assignment_2303',
        'assignment_2301',
        'assignment_2302',
        'assignment_2304',
        'assignment_group_2202',
        'assignment_group_2201',
        'total_grade',
      ]
      deepEqual(gridSpecHelper.listScrollableColumnIds(), expectedOrder)
    })
  })

  QUnit.module('when using a custom order', () => {
    test('sorts all saved columns in the saved order', () => {
      const customOrder = [
        'total_grade',
        'assignment_group_2201',
        'assignment_2301',
        'assignment_2303',
        'assignment_group_2202',
        'assignment_2302',
        'assignment_2304',
      ]
      createGradebookAndAddData({
        gradebook_column_order_settings: {sortType: 'custom', customOrder},
      })
      deepEqual(gridSpecHelper.listScrollableColumnIds(), customOrder)
    })

    test('sorts any unsaved columns after the saved order', () => {
      const customOrder = [
        'total_grade',
        'assignment_2301',
        'assignment_group_2202',
        'assignment_2302',
        'assignment_2304',
      ]
      createGradebookAndAddData({
        gradebook_column_order_settings: {sortType: 'custom', customOrder},
      })
      const expectedOrder = [
        'total_grade',
        'assignment_2301',
        'assignment_group_2202',
        'assignment_2302',
        'assignment_2304',
        'assignment_2303',
        'assignment_group_2201',
      ]
      deepEqual(gridSpecHelper.listScrollableColumnIds(), expectedOrder)
    })

    test('sorts unsaved columns by assignment group position', () => {
      const customOrder = [
        'total_grade',
        'assignment_2301',
        'assignment_group_2202',
        'assignment_group_2201',
      ]
      createGradebookAndAddData({
        gradebook_column_order_settings: {sortType: 'custom', customOrder},
      })
      const expectedOrder = [
        'total_grade',
        'assignment_2301',
        'assignment_group_2202',
        'assignment_group_2201',
        'assignment_2302',
        'assignment_2304',
        'assignment_2303',
      ]
      deepEqual(gridSpecHelper.listScrollableColumnIds(), expectedOrder)
    })
  })
})
