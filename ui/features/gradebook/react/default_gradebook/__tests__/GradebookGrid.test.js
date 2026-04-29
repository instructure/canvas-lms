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

import {createGradebook} from './GradebookSpecHelper'
import GradebookGrid from '../GradebookGrid/index'
import slickgrid from 'slickgrid'
import {vi} from 'vitest'

vi.mock('slickgrid', () => {
  const mockGrid = vi.fn().mockImplementation(() => ({
    getColumns: vi.fn().mockReturnValue([]),
    getOptions: vi.fn().mockReturnValue({numberOfColumnsToFreeze: 2}),
    destroy: vi.fn(),
    invalidate: vi.fn(),
    updateCell: vi.fn(),
    setNumberOfColumnsToFreeze: vi.fn(),
    setColumns: vi.fn(),
    onColumnsReordered: {
      subscribe: vi.fn(),
      unsubscribe: vi.fn(),
    },
    onColumnsResized: {
      subscribe: vi.fn(),
      unsubscribe: vi.fn(),
    },
    onKeyDown: {
      subscribe: vi.fn(),
      unsubscribe: vi.fn(),
    },
    onClick: {
      subscribe: vi.fn(),
      unsubscribe: vi.fn(),
    },
    onHeaderClick: {
      subscribe: vi.fn(),
      unsubscribe: vi.fn(),
    },
    onHeaderKeyDown: {
      subscribe: vi.fn(),
      unsubscribe: vi.fn(),
    },
    onBeforeEditCell: {
      subscribe: vi.fn(),
      unsubscribe: vi.fn(),
    },
  }))
  return {
    default: {Grid: mockGrid},
    Grid: mockGrid,
  }
})

vi.mock('../GradebookGrid/GridSupport/index', () => ({
  default: vi.fn().mockImplementation(() => ({
    initialize: vi.fn(),
    destroy: vi.fn(),
    columns: {
      getColumns: vi.fn(),
      scrollToStart: vi.fn(),
      scrollToEnd: vi.fn(),
    },
    events: {
      onKeyDown: {
        subscribe: vi.fn(),
      },
      onColumnsReordered: {
        subscribe: vi.fn(),
      },
      onColumnsResized: {
        subscribe: vi.fn(),
      },
      onClick: {
        subscribe: vi.fn(),
      },
      onHeaderClick: {
        subscribe: vi.fn(),
      },
      onHeaderKeyDown: {
        subscribe: vi.fn(),
      },
      onBeforeEditCell: {
        subscribe: vi.fn(),
      },
    },
  })),
}))

describe.skip('GradebookGrid', () => {
  let container
  let gradebook
  let gradebookGrid

  beforeEach(() => {
    container = document.createElement('div')
    document.body.appendChild(container)

    gradebook = createGradebook()
    gradebook.gridData.columns.frozen = ['student']
    gradebook.gridData.columns.scrollable = ['total_grade']
    gradebook.gridData.columns.definitions = {
      student: {id: 'student'},
      total_grade: {id: 'total_grade'},
    }

    gradebookGrid = new GradebookGrid({
      $container: container,
      activeBorderColor: '#FFFFFF',
      data: gradebook.gridData,
      editable: true,
      gradebook,
    })
  })

  afterEach(() => {
    gradebookGrid.destroy()
    container.remove()
    vi.clearAllMocks()
  })

  const initializeGradebookGrid = () => {
    gradebookGrid.initialize()
    gradebookGrid.gridSupport.initialize()
  }

  describe('#initialize()', () => {
    beforeEach(() => {
      const columns = [
        {id: 'student'},
        {id: 'custom_col_2401'},
        {id: 'assignment_2301'},
        {id: 'assignment_2302'},
        {id: 'assignment_group_2201'},
        {id: 'total_grade'},
      ]
      columns.forEach(column => {
        gradebook.gridData.columns.definitions[column.id] = column
      })
      gradebook.gridData.columns.frozen = columns.slice(0, 2).map(column => column.id)
      gradebook.gridData.columns.scrollable = columns.slice(2).map(column => column.id)
    })

    it('sets the columns on the grid', () => {
      initializeGradebookGrid()
      expect(slickgrid.Grid).toHaveBeenCalled()
    })

    it('sets the frozen columns before the scrollable columns', () => {
      initializeGradebookGrid()
      const constructorCall = slickgrid.Grid.mock.calls[0]
      const columnIds = constructorCall[2].map(column => column.id)
      const expected = [
        'student',
        'custom_col_2401',
        'assignment_2301',
        'assignment_2302',
        'assignment_group_2201',
        'total_grade',
      ]
      expect(columnIds).toEqual(expected)
    })

    it('sets the number of frozen columns', () => {
      initializeGradebookGrid()
      const constructorCall = slickgrid.Grid.mock.calls[0]
      expect(constructorCall[3].numberOfColumnsToFreeze).toBe(2)
    })
  })

  describe('#updateColumns()', () => {
    beforeEach(() => {
      initializeGradebookGrid()
      const columns = [
        {id: 'student'},
        {id: 'custom_col_2401'},
        {id: 'assignment_2301'},
        {id: 'assignment_2302'},
        {id: 'assignment_group_2201'},
        {id: 'total_grade'},
      ]
      columns.forEach(column => {
        gradebook.gridData.columns.definitions[column.id] = column
      })
      gradebook.gridData.columns.frozen = columns.slice(0, 2).map(column => column.id)
      gradebook.gridData.columns.scrollable = columns.slice(2).map(column => column.id)
    })

    it('sets the columns on the grid', () => {
      gradebookGrid.updateColumns()
      expect(gradebookGrid.grid.setColumns).toHaveBeenCalled()
    })

    it('sets the frozen columns before the scrollable columns', () => {
      gradebookGrid.updateColumns()
      const setColumnsCall = gradebookGrid.grid.setColumns.mock.calls[0]
      const columnIds = setColumnsCall[0].map(column => column.id)
      const expected = [
        'student',
        'custom_col_2401',
        'assignment_2301',
        'assignment_2302',
        'assignment_group_2201',
        'total_grade',
      ]
      expect(columnIds).toEqual(expected)
    })

    it('sets the number of frozen columns', () => {
      gradebookGrid.updateColumns()
      expect(gradebookGrid.grid.setNumberOfColumnsToFreeze).toHaveBeenCalledWith(2)
    })

    it('has no effect when the grid has not been initialized', () => {
      gradebookGrid.grid = null
      expect(() => gradebookGrid.updateColumns()).not.toThrow()
    })
  })

  describe('#updateRowCell()', () => {
    beforeEach(() => {
      initializeGradebookGrid()
      const columns = [
        {id: 'student'},
        {id: 'custom_col_2401'},
        {id: 'assignment_2301'},
        {id: 'assignment_2302'},
        {id: 'assignment_group_2201'},
        {id: 'total_grade'},
      ]
      columns.forEach(column => {
        gradebook.gridData.columns.definitions[column.id] = column
      })
      gradebook.gridData.columns.frozen = columns.slice(0, 2).map(column => column.id)
      gradebook.gridData.columns.scrollable = columns.slice(2).map(column => column.id)
      gradebook.gridData.rows = [{id: '1101'}, {id: '1102'}]
    })

    it('updates the cell in the grid', () => {
      gradebookGrid.updateRowCell('1101', 'total_grade')
      expect(gradebookGrid.grid.updateCell).toHaveBeenCalled()
    })

    it('includes the row index when updating the cell in the grid', () => {
      gradebookGrid.updateRowCell('1102', 'total_grade')
      expect(gradebookGrid.grid.updateCell).toHaveBeenCalledWith(1, expect.any(Number))
    })

    it('includes the column index when updating the cell in the grid', () => {
      gradebookGrid.updateRowCell('1101', 'total_grade')
      expect(gradebookGrid.grid.updateCell).toHaveBeenCalledWith(expect.any(Number), 5)
    })

    it('has no effect when the grid has not been initialized', () => {
      gradebookGrid.grid = null
      expect(() => gradebookGrid.updateRowCell('1101', 'total_grade')).not.toThrow()
    })
  })

  describe('#destroy()', () => {
    beforeEach(() => {
      initializeGradebookGrid()
    })

    it('destroys the grid', () => {
      const grid = gradebookGrid.grid
      gradebookGrid.destroy()
      expect(grid.destroy).toHaveBeenCalled()
    })

    it('has no effect when the grid has not been initialized', () => {
      gradebookGrid.grid = null
      expect(() => gradebookGrid.destroy()).not.toThrow()
    })
  })
})
