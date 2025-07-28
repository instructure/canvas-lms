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

import 'jquery-migrate'
import slickgrid from 'slickgrid'
import GridSupport from '../index'

const {Editors, Grid} = slickgrid

function createColumns() {
  return [1, 2, 3, 4].map(id => ({
    id: `column${id}`,
    field: `columnData${id}`,
    name: `Column ${id}`,
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

function createGrid() {
  const options = {
    autoEdit: true, // enable editing upon cell activation
    autoHeight: true, // adjusts grid to fit provided data
    editable: true,
    editorFactory: {
      getEditor() {
        return Editors.Text
      },
    },
    enableCellNavigation: true,
    enableColumnReorder: false,
    numberOfColumnsToFreeze: 2, // for possible edge cases with multiple grid viewports
  }
  return new Grid('#example-grid', createRows(), createColumns(), options)
}

describe('GradebookGrid GridHelper', () => {
  let $gridContainer
  let grid
  let gridSupport

  beforeEach(() => {
    // Create and append grid container to the document body
    $gridContainer = document.createElement('div')
    $gridContainer.id = 'example-grid'
    document.body.appendChild($gridContainer)

    // Initialize SlickGrid and GridSupport
    grid = createGrid()
    gridSupport = new GridSupport(grid)
    gridSupport.initialize()
  })

  afterEach(() => {
    // Destroy GridSupport and SlickGrid instances
    gridSupport.destroy()
    grid.destroy()

    // Remove grid container from the document body
    $gridContainer.remove()
  })

  describe('#beginEdit()', () => {
    beforeEach(() => {
      // Set active location to the first cell of the first row
      gridSupport.state.setActiveLocation('body', {cell: 0, row: 0})

      // Commit any existing edits to ensure a clean state
      gridSupport.helper.commitCurrentEdit()
    })

    test('edits the active cell', () => {
      gridSupport.helper.beginEdit()
      expect(grid.getEditorLock().isActive()).toBe(true)
    })

    test('does not edit the active cell when the grid is not editable', () => {
      grid.setOptions({editable: false})
      gridSupport.helper.beginEdit()
      expect(grid.getEditorLock().isActive()).toBe(false)
    })
  })

  describe('#focus()', () => {
    test('sets focus on the grid', () => {
      gridSupport.helper.focus()
      expect(document.activeElement).toBe(gridSupport.helper.getAfterGridNode())
    })
  })
})
