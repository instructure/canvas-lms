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

import {createGradebook} from 'jsx/gradezilla/default_gradebook/__tests__/GradebookSpecHelper'
import GradebookGrid from 'jsx/gradezilla/default_gradebook/GradebookGrid'

QUnit.module('GradebookGrid', suiteHooks => {
  let $container
  let gradebook
  let gradebookGrid

  suiteHooks.beforeEach(() => {
    $container = document.createElement('div')
    document.body.appendChild($container)

    gradebook = createGradebook()
    gradebook.gridData.columns.frozen = ['student']
    gradebook.gridData.columns.scrollable = ['total_grade']
    gradebook.gridData.columns.definitions = {
      student: {id: 'student'},
      total_grade: {id: 'total_grade'}
    }

    gradebookGrid = new GradebookGrid({
      $container,
      activeBorderColor: '#FFFFFF',
      data: gradebook.gridData,
      editable: true,
      gradebook
    })
  })

  suiteHooks.afterEach(() => {
    gradebookGrid.destroy()
    gradebook.destroy()
    $container.remove()
  })

  function initializeGradebookGrid() {
    // temporarily necessary while keyboard events are not consolidated
    gradebookGrid.initialize()
    gradebookGrid.gridSupport.initialize()
  }

  QUnit.module('#initialize()', hooks => {
    hooks.beforeEach(() => {
      const columns = [
        {id: 'student'},
        {id: 'custom_col_2401'},
        {id: 'assignment_2301'},
        {id: 'assignment_2302'},
        {id: 'assignment_group_2201'},
        {id: 'total_grade'}
      ]
      columns.forEach(column => {
        gradebook.gridData.columns.definitions[column.id] = column
      })
      gradebook.gridData.columns.frozen = columns.slice(0, 2).map(column => column.id)
      gradebook.gridData.columns.scrollable = columns.slice(2).map(column => column.id)
    })

    test('sets the columns on the grid', () => {
      initializeGradebookGrid()
      strictEqual(gradebookGrid.grid.getColumns().length, 6)
    })

    test('sets the frozen columns before the scrollable columns', () => {
      initializeGradebookGrid()
      const columnIds = gradebookGrid.grid.getColumns().map(column => column.id)
      const expected = [
        'student',
        'custom_col_2401',
        'assignment_2301',
        'assignment_2302',
        'assignment_group_2201',
        'total_grade'
      ]
      deepEqual(columnIds, expected)
    })

    test('sets the number of frozen columns', () => {
      initializeGradebookGrid()
      strictEqual(gradebookGrid.grid.getOptions().numberOfColumnsToFreeze, 2)
    })
  })

  QUnit.module('#updateColumns()', hooks => {
    hooks.beforeEach(() => {
      initializeGradebookGrid()
      const columns = [
        {id: 'student'},
        {id: 'custom_col_2401'},
        {id: 'assignment_2301'},
        {id: 'assignment_2302'},
        {id: 'assignment_group_2201'},
        {id: 'total_grade'}
      ]
      columns.forEach(column => {
        gradebook.gridData.columns.definitions[column.id] = column
      })
      gradebook.gridData.columns.frozen = columns.slice(0, 2).map(column => column.id)
      gradebook.gridData.columns.scrollable = columns.slice(2).map(column => column.id)
    })

    test('sets the columns on the grid', () => {
      gradebookGrid.updateColumns()
      strictEqual(gradebookGrid.grid.getColumns().length, 6)
    })

    test('sets the frozen columns before the scrollable columns', () => {
      gradebookGrid.updateColumns()
      const columnIds = gradebookGrid.grid.getColumns().map(column => column.id)
      const expected = [
        'student',
        'custom_col_2401',
        'assignment_2301',
        'assignment_2302',
        'assignment_group_2201',
        'total_grade'
      ]
      deepEqual(columnIds, expected)
    })

    test('sets the number of frozen columns', () => {
      gradebookGrid.updateColumns()
      strictEqual(gradebookGrid.grid.getOptions().numberOfColumnsToFreeze, 2)
    })

    test('has no effect when the grid has not been initialized', () => {
      gradebookGrid.grid = null
      gradebookGrid.updateColumns()
      ok(true, 'no error was thrown')
    })
  })

  QUnit.module('#updateRowCell()', hooks => {
    hooks.beforeEach(() => {
      initializeGradebookGrid()
      const columns = [
        {id: 'student'},
        {id: 'custom_col_2401'},
        {id: 'assignment_2301'},
        {id: 'assignment_2302'},
        {id: 'assignment_group_2201'},
        {id: 'total_grade'}
      ]
      columns.forEach(column => {
        gradebook.gridData.columns.definitions[column.id] = column
      })
      gradebook.gridData.columns.frozen = columns.slice(0, 2).map(column => column.id)
      gradebook.gridData.columns.scrollable = columns.slice(2).map(column => column.id)
      gradebook.gridData.rows = [{id: '1101'}, {id: '1102'}]
    })

    test('updates the cell in the grid', () => {
      sinon.spy(gradebookGrid.grid, 'updateCell')
      gradebookGrid.updateRowCell('1101', 'total_grade')
      strictEqual(gradebookGrid.grid.updateCell.callCount, 1)
    })

    test('includes the row index when updating the cell in the grid', () => {
      sinon.spy(gradebookGrid.grid, 'updateCell')
      gradebookGrid.updateRowCell('1102', 'total_grade')
      const [rowIndex] = gradebookGrid.grid.updateCell.lastCall.args
      strictEqual(rowIndex, 1)
    })

    test('includes the column index when updating the cell in the grid', () => {
      sinon.spy(gradebookGrid.grid, 'updateCell')
      gradebookGrid.updateRowCell('1101', 'total_grade')
      const columnIndex = gradebookGrid.grid.updateCell.lastCall.args[1]
      strictEqual(columnIndex, 5)
    })

    test('has no effect when the grid has not been initialized', () => {
      gradebookGrid.grid = null
      gradebookGrid.updateRowCell('1101', 'total_grade')
      ok(true, 'no error was thrown')
    })
  })

  QUnit.module('#destroy()', hooks => {
    hooks.beforeEach(() => {
      initializeGradebookGrid()
    })

    test('removes the grid style element from the DOM', () => {
      const elementId = gradebookGrid.gridSupport.style.$styles.id
      gradebookGrid.destroy()
      notOk(document.getElementById(elementId))
    })

    test('removes the grid from the DOM', () => {
      gradebookGrid.destroy()
      strictEqual($container.children.length, 0)
    })
  })
})
