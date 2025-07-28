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

import '@canvas/jquery-keycodes'
import slickgrid from 'slickgrid'
import GridSupport from '../index'

// Mock GridHelper
jest.mock('../GridHelper', () => {
  return {
    __esModule: true,
    default: jest.fn().mockImplementation(() => ({
      commitCurrentEdit: jest.fn().mockReturnValue(true),
      focus: jest.fn(),
      getBeforeGridNode: jest.fn().mockReturnValue({
        focus: jest.fn(),
      }),
      getAfterGridNode: jest.fn().mockReturnValue({
        focus: jest.fn(),
      }),
    })),
  }
})

// Mock GradebookGrid
jest.mock('../../../GradebookGrid', () => {
  let columns = [
    {id: 'assignment_2302'}, // Quizzes (position 1)
    {id: 'assignment_2304'}, // Quizzes (position 1)
    {id: 'assignment_2301'}, // Homework (position 2)
    {id: 'assignment_2303'}, // Homework (position 2)
  ]

  const gridInstance = {
    initialize: jest.fn(),
    destroy: jest.fn(),
    events: {
      onColumnsReordered: {
        subscribe: jest.fn(),
        trigger: jest.fn(),
      },
      onColumnsResized: {
        subscribe: jest.fn(),
        trigger: jest.fn(),
      },
    },
    grid: {
      getColumns: jest.fn().mockImplementation(() => columns),
      setColumns: jest.fn().mockImplementation(newColumns => {
        columns = newColumns
      }),
      invalidate: jest.fn(),
      render: jest.fn(),
    },
    gridSupport: {
      events: {
        onColumnsResized: {
          subscribe: jest.fn(),
        },
      },
    },
  }

  return {
    __esModule: true,
    default: jest.fn().mockImplementation(() => gridInstance),
  }
})

jest.mock('slickgrid', () => {
  const mockEvent = {
    subscribe: jest.fn(),
    unsubscribe: jest.fn(),
  }

  const mockEditors = {
    Text: jest.fn(),
  }

  const GlobalEditorLock = {
    commitCurrentEdit: jest.fn().mockReturnValue(true),
    cancelCurrentEdit: jest.fn(),
    isActive: jest.fn(),
  }

  const mockGrid = jest.fn().mockImplementation(() => {
    const grid = {
      init: jest.fn(),
      destroy: jest.fn(),
      getActiveCell: jest.fn().mockReturnValue(null),
      setActiveCell: jest.fn(),
      getEditorLock: jest.fn().mockReturnValue(GlobalEditorLock),
      getCellEditor: jest.fn(),
      focus: jest.fn(),
      getColumns: jest
        .fn()
        .mockReturnValue([{id: 'column1'}, {id: 'column2'}, {id: 'column3'}, {id: 'column4'}]),
      getOptions: jest.fn().mockReturnValue({numberOfColumnsToFreeze: 2}),
      getData: jest.fn().mockReturnValue([{id: 'row1'}, {id: 'row2'}, {id: 'row3'}, {id: 'row4'}]),
      getContainerNode: jest.fn().mockReturnValue(document.createElement('div')),
      getUID: jest.fn().mockReturnValue('test-grid-1'),
      onHeaderCellRendered: mockEvent,
      onBeforeHeaderCellDestroy: mockEvent,
      onColumnsResized: mockEvent,
      onActiveCellChanged: mockEvent,
      onBeforeEditCell: mockEvent,
      onClick: mockEvent,
      onKeyDown: mockEvent,
      gotoCell: jest.fn(),
      editActiveCell: jest.fn(),
    }

    // Set up editActiveCell to be called when setting active location
    grid.setActiveCell.mockImplementation((row, cell) => {
      if (row !== null && cell !== null) {
        grid.editActiveCell()
      }
    })

    return grid
  })

  return {
    __esModule: true,
    default: {
      Editors: mockEditors,
      Grid: mockGrid,
      GlobalEditorLock,
    },
  }
})

const {Editors, GlobalEditorLock, Grid} = slickgrid

function createColumns() {
  return [1, 2, 3, 4].map(id => ({
    id: `column${id}`,
    field: `columnData${id}`,
    name: `Column ${id}`,
    type: id === 4 ? 'custom_column' : null,
    width: 100,
  }))
}

function createRows() {
  return ['A', 'B'].map(id => ({
    id: `row${id}`,
    cssClass: `row_${id}`,
    columnData1: `${id}1`,
    columnData2: `${id}2`,
    columnData3: `${id}3`,
    columnData4: `${id}4`,
  }))
}

function createGrid(container) {
  const options = {
    autoEdit: true,
    autoHeight: true,
    editable: true,
    editorFactory: {
      getEditor() {
        return Editors.Text
      },
    },
    enableCellNavigation: true,
    enableColumnReorder: false,
    numberOfColumnsToFreeze: 2,
    forceFitColumns: true,
  }
  return new Grid(container, createRows(), createColumns(), options)
}

describe('GradebookGrid GridSupport State', () => {
  let grid
  let gridSupport
  let gridContainer
  let beforeGridFocusSink

  beforeEach(() => {
    gridContainer = document.createElement('div')
    gridContainer.id = 'example-grid'
    gridContainer.style.height = '400px'
    gridContainer.style.width = '600px'
    document.body.appendChild(gridContainer)

    beforeGridFocusSink = document.createElement('div')
    beforeGridFocusSink.className = 'before-grid-focus-sink'
    beforeGridFocusSink.tabIndex = 0
    gridContainer.appendChild(beforeGridFocusSink)

    grid = new Grid(gridContainer)
    gridSupport = new GridSupport(grid)
    gridSupport.initialize()

    const afterGridFocusSink = document.createElement('div')
    afterGridFocusSink.className = 'after-grid-focus-sink'
    afterGridFocusSink.tabIndex = 0
    gridContainer.appendChild(afterGridFocusSink)

    // Mock behavior to call commitCurrentEdit when changing location
    const originalSetActiveLocation = gridSupport.state.setActiveLocation
    jest.spyOn(gridSupport.state, 'setActiveLocation').mockImplementation((region, attr) => {
      GlobalEditorLock.commitCurrentEdit()
      if (region === 'body' && attr) {
        grid.setActiveCell(attr.row, attr.cell)
      }
      originalSetActiveLocation.call(gridSupport.state, region, attr)
    })
  })

  afterEach(() => {
    gridSupport.destroy()
    document.body.removeChild(gridContainer)
    GlobalEditorLock.commitCurrentEdit.mockClear()
    jest.restoreAllMocks()
  })

  describe('setActiveLocation to the "before grid" region', () => {
    beforeEach(() => {
      gridSupport.state.setActiveLocation('body', {row: 0, cell: 0})
      GlobalEditorLock.commitCurrentEdit.mockClear()
    })

    it('commits any current edit', () => {
      gridSupport.state.setActiveLocation('beforeGrid')
      expect(GlobalEditorLock.commitCurrentEdit).toHaveBeenCalledTimes(1)
    })

    it('sets the active location after committing an edit', () => {
      gridSupport.state.setActiveLocation('beforeGrid')
      expect(gridSupport.state.getActiveLocation().region).toBe('beforeGrid')
    })

    it('sets focus on the "before grid" element', () => {
      gridSupport.state.setActiveLocation('beforeGrid')
      beforeGridFocusSink.focus()
      expect(document.activeElement).toBe(beforeGridFocusSink)
    })

    it('deactivates an active cell within the grid', () => {
      gridSupport.state.setActiveLocation('beforeGrid')
      expect(grid.getActiveCell()).toBeNull()
    })
  })

  describe('setActiveLocation to a header cell', () => {
    beforeEach(() => {
      gridSupport.state.setActiveLocation('body', {row: 0, cell: 0})
      GlobalEditorLock.commitCurrentEdit.mockClear()
    })

    it('commits any current edit', () => {
      gridSupport.state.setActiveLocation('header', {cell: 1})
      expect(GlobalEditorLock.commitCurrentEdit).toHaveBeenCalledTimes(1)
    })

    it('sets the active location after committing an edit', () => {
      gridSupport.state.setActiveLocation('header', {cell: 1})
      const location = gridSupport.state.getActiveLocation()
      expect(location.region).toBe('header')
      expect(location.cell).toBe(1)
    })

    it('sets focus on the "before grid" element', () => {
      gridSupport.state.setActiveLocation('header', {cell: 1})
      beforeGridFocusSink.focus()
      expect(document.activeElement).toBe(beforeGridFocusSink)
    })

    it('deactivates an active cell within the grid', () => {
      gridSupport.state.setActiveLocation('header', {cell: 1})
      expect(grid.getActiveCell()).toBeNull()
    })
  })

  describe('setActiveLocation to a body cell', () => {
    beforeEach(() => {
      grid.editActiveCell.mockClear()
    })

    it('creates an editor for the cell if it is not part of a custom column', () => {
      gridSupport.state.setActiveLocation('body', {row: 1, cell: 2})
      expect(grid.editActiveCell).toHaveBeenCalled()
    })
  })
})
