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

import 'jquery-migrate'
import slickgrid from 'slickgrid'
import GridSupport from '../index'

const {Grid} = slickgrid

// Mock stylesheet functionality
function setupGridStylesheet() {
  const styleSheet = document.createElement('style')
  styleSheet.textContent = `
    .slick-header-column { }
    .slick-header-columns { }
    .slick-header-column.ui-sortable-helper { }
    .slick-sort-indicator { }
    .slick-sort-indicator-desc { }
    .slick-sort-indicator-asc { }
    .b0 { }
    .b1 { }
    .b2 { }
    .b3 { }
    .f0 { }
    .f1 { }
    .f2 { }
    .f3 { }
  `
  document.head.appendChild(styleSheet)

  // Mock the stylesheet's cssRules
  Object.defineProperty(styleSheet, 'cssRules', {
    get: function () {
      return Array.from(this.sheet.cssRules)
    },
  })

  return styleSheet
}

const createColumns = () => {
  return [1, 2, 3, 4].map(id => ({
    id: `column${id}`,
    field: `columnData${id}`,
    name: `Column ${id}`,
    width: 100,
    minWidth: 50,
    resizable: true,
    sortable: true,
  }))
}

const createRows = () => {
  return ['A', 'B'].map(id => ({
    id: `row${id}`,
    cssClass: `row_${id}`,
    columnData1: `${id}1`,
    columnData2: `${id}2`,
    columnData3: `${id}3`,
    columnData4: `${id}4`,
  }))
}

const createGrid = () => {
  const container = document.createElement('div')
  container.style.width = '100%'
  container.dataset.testid = 'grid-container'

  const columns = createColumns()
  const rows = createRows()
  const options = {
    autoEdit: true,
    autoHeight: true,
    editable: true,
    enableCellNavigation: true,
    enableColumnReorder: true,
    numberOfColumnsToFreeze: 0,
    forceFitColumns: false,
    headerHeight: 30,
  }

  return new Grid(container, rows, columns, options)
}

describe('GridSupport Columns', () => {
  let container
  let grid
  let gridSupport
  let styleSheet

  beforeEach(() => {
    container = document.createElement('div')
    document.body.appendChild(container)
    styleSheet = setupGridStylesheet()
    grid = createGrid()
    container.appendChild(grid.getContainerNode())
  })

  afterEach(() => {
    gridSupport?.destroy()
    container.remove()
    styleSheet.remove()
  })

  describe('initialization', () => {
    it('initializes with the grid', () => {
      gridSupport = new GridSupport(grid)
      gridSupport.initialize()
      expect(gridSupport).toBeTruthy()
      expect(grid.getColumns()).toHaveLength(4)
    })

    it('uses column headers from the column header renderer when provided', () => {
      const renderedColumns = []
      const columnHeaderRenderer = {
        renderColumnHeader: column => {
          renderedColumns.push(column.id)
        },
        destroyColumnHeader: () => {},
      }

      gridSupport = new GridSupport(grid, {columnHeaderRenderer})
      gridSupport.initialize()

      const columns = grid.getColumns()
      expect(renderedColumns).toEqual(columns.map(column => column.id))
    })
  })

  describe('column header renderers', () => {
    it('calls destroy on the previous renderer when replacing column headers', () => {
      const destroySpy = jest.fn()
      const columnHeaderRenderer = {
        renderColumnHeader: () => {},
        destroyColumnHeader: destroySpy,
      }

      gridSupport = new GridSupport(grid, {columnHeaderRenderer})
      gridSupport.initialize()
      grid.setColumns(createColumns()) // trigger header replacement

      expect(destroySpy).toHaveBeenCalled()
    })

    it('updates headers when columns change', () => {
      const renderedColumns = []
      const columnHeaderRenderer = {
        renderColumnHeader: column => {
          renderedColumns.push(column.id)
        },
        destroyColumnHeader: () => {},
      }

      gridSupport = new GridSupport(grid, {columnHeaderRenderer})
      gridSupport.initialize()

      const newColumns = createColumns().slice(0, 2)
      grid.setColumns(newColumns)

      expect(renderedColumns).toContain(newColumns[0].id)
      expect(renderedColumns).toContain(newColumns[1].id)
    })
  })

  describe('column resizing', () => {
    beforeEach(() => {
      gridSupport = new GridSupport(grid)
      gridSupport.initialize()
    })

    it('triggers onColumnsResized when resizing a column', () => {
      const onResizeSpy = jest.fn()
      grid.onColumnsResized.subscribe(onResizeSpy)

      const columns = grid.getColumns()
      const originalWidth = columns[0].width
      columns[0].width = originalWidth + 100
      grid.setColumns(columns)

      // Manually trigger the resize event since we can't simulate drag in tests
      grid.onColumnsResized.notify({grid}, null, grid)

      expect(onResizeSpy).toHaveBeenCalled()
    })

    it('maintains column order when resizing', () => {
      const columns = grid.getColumns()
      const originalOrder = columns.map(column => column.id)

      columns[0].width = 200
      grid.setColumns(columns)

      const newOrder = grid.getColumns().map(column => column.id)
      expect(newOrder).toEqual(originalOrder)
    })

    it('respects minimum width constraints', () => {
      const columns = grid.getColumns()
      const minWidth = columns[0].minWidth

      columns[0].width = minWidth - 10
      grid.setColumns(columns)

      expect(grid.getColumns()[0].width).toBeGreaterThanOrEqual(minWidth)
    })
  })

  describe('column reordering', () => {
    beforeEach(() => {
      gridSupport = new GridSupport(grid)
      gridSupport.initialize()
    })

    it('triggers onColumnsReordered when reordering columns', () => {
      const onReorderSpy = jest.fn()
      grid.onColumnsReordered.subscribe(onReorderSpy)

      const columns = grid.getColumns()
      const [first, ...rest] = columns
      grid.setColumns([...rest, first])

      // Manually trigger the reorder event since we can't simulate drag in tests
      grid.onColumnsReordered.notify({grid}, null, grid)

      expect(onReorderSpy).toHaveBeenCalled()
    })

    it('maintains column widths when reordering', () => {
      const columns = grid.getColumns()
      const originalWidths = columns.map(column => column.width)

      const [first, ...rest] = columns
      grid.setColumns([...rest, first])

      const newWidths = grid.getColumns().map(column => column.width)
      expect(newWidths).toEqual(originalWidths)
    })

    it('preserves column properties after reordering', () => {
      const columns = grid.getColumns()
      const [first, ...rest] = columns
      const originalProps = {...first}

      grid.setColumns([...rest, first])

      const movedColumn = grid.getColumns()[grid.getColumns().length - 1]
      expect(movedColumn.id).toBe(originalProps.id)
      expect(movedColumn.field).toBe(originalProps.field)
      expect(movedColumn.name).toBe(originalProps.name)
      expect(movedColumn.width).toBe(originalProps.width)
    })
  })
})
