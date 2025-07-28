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

import slickgrid from 'slickgrid'
import GridSupport from '../index'

const {Editors, Grid} = slickgrid

function createColumns() {
  return [1, 2, 3, 4].map(id => {
    const columnId = `column${id}`
    const primaryClass = id === 1 ? ' primary-column' : ''

    return {
      id: columnId,
      cssClass: `${columnId}${primaryClass}`,
      field: `columnData${id}`,
      headerCssClass: `${columnId}${primaryClass}`,
      name: `Column ${id}`,
    }
  })
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
  }
  return new Grid('#example-grid', createRows(), createColumns(), options)
}

describe('GradebookGrid GridSupport Style', () => {
  let grid
  let gridSupport
  let fixturesDiv

  beforeEach(() => {
    fixturesDiv = document.createElement('div')
    fixturesDiv.id = 'fixtures'
    document.body.appendChild(fixturesDiv)
    const gridContainer = document.createElement('div')
    gridContainer.id = 'example-grid'
    fixturesDiv.appendChild(gridContainer)

    grid = createGrid()
    gridSupport = new GridSupport(grid, {
      activeBorderColor: 'rgb(12, 34, 56)',
    })
    gridSupport.initialize()
    grid.invalidate()
  })

  afterEach(() => {
    gridSupport.destroy()
    grid.destroy()
    fixturesDiv.remove()
  })

  describe('when active location changes to a header cell', () => {
    beforeEach(() => {
      gridSupport.state.setActiveLocation('header', {cell: 1, columnId: 'column2'})
    })

    it('updates styles for the active column', () => {
      const styleElement = document.getElementById(`GridSupport__Styles--${grid.getUID()}`)
      expect(styleElement).toBeTruthy()

      const styleContent = styleElement.innerHTML.replace(/\s+/g, ' ').trim()
      expect(styleContent).toContain('border: 1px solid rgb(12, 34, 56)')
    })

    it('removes styles for the previous active column', () => {
      // First set active location to column 2
      gridSupport.state.setActiveLocation('header', {cell: 1, columnId: 'column2'})

      // Then change to column 3
      gridSupport.state.setActiveLocation('header', {cell: 2, columnId: 'column3'})

      const styleElement = document.getElementById(`GridSupport__Styles--${grid.getUID()}`)
      const styleContent = styleElement.innerHTML.replace(/\s+/g, ' ').trim()

      expect(styleContent).toContain('column3')
      expect(styleContent).not.toContain('column2')
    })
  })

  describe('when active location changes to a body cell', () => {
    it('updates styles for the active column', () => {
      gridSupport.state.setActiveLocation('body', {row: 0, cell: 1, columnId: 'column2'})

      const styleElement = document.getElementById(`GridSupport__Styles--${grid.getUID()}`)
      const styleContent = styleElement.innerHTML.replace(/\s+/g, ' ').trim()
      expect(styleContent).toContain('border: 1px solid rgb(12, 34, 56)')
      expect(styleContent).toContain('column2')
    })

    it('removes styles for the previous active column', () => {
      // First activate column2
      gridSupport.state.setActiveLocation('body', {row: 0, cell: 1, columnId: 'column2'})

      // Then activate column3
      gridSupport.state.setActiveLocation('body', {row: 0, cell: 2, columnId: 'column3'})

      const styleElement = document.getElementById(`GridSupport__Styles--${grid.getUID()}`)
      const styleContent = styleElement.innerHTML.replace(/\s+/g, ' ').trim()

      expect(styleContent).toContain('column3')
      expect(styleContent).not.toContain('column2')
    })
  })

  describe('when active location changes to "unknown"', () => {
    it('removes styles for the previous active column', () => {
      // First activate a column
      gridSupport.state.setActiveLocation('header', {cell: 1, columnId: 'column2'})

      // Then set to unknown
      gridSupport.state.setActiveLocation('unknown')

      const styleElement = document.getElementById(`GridSupport__Styles--${grid.getUID()}`)
      expect(styleElement.innerHTML.trim()).toBe('')
    })
  })

  describe('when active location is the primary column header cell', () => {
    beforeEach(() => {
      gridSupport.state.setActiveLocation('header', {cell: 0, columnId: 'column1'})
    })

    it('includes borders around the header cell', () => {
      const styleElement = document.getElementById(`GridSupport__Styles--${grid.getUID()}`)
      const styleContent = styleElement.innerHTML.replace(/\s+/g, ' ').trim()

      expect(styleContent).toContain('border: 1px solid rgb(12, 34, 56)')
      expect(styleContent).toContain('.slick-header .slick-header-column.column1')
    })

    it('includes side borders on the column cells', () => {
      const styleElement = document.getElementById(`GridSupport__Styles--${grid.getUID()}`)
      const styleContent = styleElement.innerHTML.replace(/\s+/g, ' ').trim()

      expect(styleContent).toContain('border-left: 1px solid rgb(12, 34, 56)')
      expect(styleContent).toContain('border-right: 1px solid rgb(12, 34, 56)')
      expect(styleContent).toContain('.slick-row .slick-cell.column1')
    })

    it('includes side and bottom borders on the last column cell', () => {
      const styleElement = document.getElementById(`GridSupport__Styles--${grid.getUID()}`)
      const styleContent = styleElement.innerHTML.replace(/\s+/g, ' ').trim()

      expect(styleContent).toContain('border-bottom: 1px solid rgb(12, 34, 56)')
      expect(styleContent).toContain('.slick-row.last-row .slick-cell.column1')
    })
  })

  describe('when active location is a non-primary column header cell', () => {
    beforeEach(() => {
      gridSupport.state.setActiveLocation('header', {cell: 1, columnId: 'column2'})
    })

    it('includes borders around the header cell', () => {
      const styleElement = document.getElementById(`GridSupport__Styles--${grid.getUID()}`)
      const styleContent = styleElement.innerHTML.replace(/\s+/g, ' ').trim()

      expect(styleContent).toContain('border: 1px solid rgb(12, 34, 56)')
      expect(styleContent).toContain('.slick-header .slick-header-column.column2')
    })

    it('includes borders around non-primary column cells', () => {
      const styleElement = document.getElementById(`GridSupport__Styles--${grid.getUID()}`)
      const styleContent = styleElement.innerHTML.replace(/\s+/g, ' ').trim()

      expect(styleContent).toContain('border-left: 1px solid rgb(12, 34, 56)')
      expect(styleContent).toContain('border-right: 1px solid rgb(12, 34, 56)')
      expect(styleContent).toContain('.slick-row .slick-cell.column2')
    })

    it('includes bottom border on the last row cell', () => {
      const styleElement = document.getElementById(`GridSupport__Styles--${grid.getUID()}`)
      const styleContent = styleElement.innerHTML.replace(/\s+/g, ' ').trim()

      expect(styleContent).toContain('border-bottom: 1px solid rgb(12, 34, 56)')
      expect(styleContent).toContain('.slick-row.last-row .slick-cell.column2')
    })
  })

  describe('when active location is a primary column body cell', () => {
    beforeEach(() => {
      gridSupport.state.setActiveLocation('body', {row: 0, cell: 0, columnId: 'column1'})
    })

    it('includes appropriate styles for primary column', () => {
      const styleElement = document.getElementById(`GridSupport__Styles--${grid.getUID()}`)
      const styleContent = styleElement.innerHTML.replace(/\s+/g, ' ').trim()

      expect(styleContent).toContain(':not(.primary-column)')
      expect(styleContent).toContain('.slick-header .slick-header-column.column1')
    })
  })
})
