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

import slickgrid from 'vendor/slickgrid';
import GridSupport from 'jsx/gradezilla/default_gradebook/GradebookGrid/GridSupport';

const { Editors, Grid } = slickgrid
const $fixtures = document.getElementById('fixtures');

function createColumns () {
  return [1, 2, 3, 4].map((id) => {
    const columnId = `column${id}`;
    const primaryClass = id === 1 ? ' primary-column' : '';

    return {
      id: columnId,
      cssClass: `${columnId}${primaryClass}`,
      field: `columnData${id}`,
      headerCssClass: `${columnId}${primaryClass}`,
      name: `Column ${id}`
    }
  });
}

function createRows () {
  return ['A', 'B'].map(id => (
    {
      id: `row${id}`,
      cssClass: `row_${id}`,
      columnData1: `${id}1`,
      columnData2: `${id}2`,
      columnData3: `${id}3`,
      columnData4: `${id}4`
    }
  ));
}

function createGrid () {
  const options = {
    autoEdit: true, // enable editing upon cell activation
    autoHeight: true, // adjusts grid to fit provided data
    editable: true,
    editorFactory: {
      getEditor () { return Editors.Text }
    },
    enableCellNavigation: true,
    enableColumnReorder: false,
    numberOfColumnsToFreeze: 2 // for possible edge cases with multiple grid viewports
  };
  return new Grid('#example-grid', createRows(), createColumns(), options);
}

QUnit.module('GridSupport Style', (hooks) => {
  let grid;
  let gridSupport;

  hooks.beforeEach(() => {
    const $gridContainer = document.createElement('div');
    $gridContainer.id = 'example-grid';
    $fixtures.appendChild($gridContainer);
    grid = createGrid();
    gridSupport = new GridSupport(grid, {
      activeBorderColor: 'rgb(12, 34, 56)'
    });
    gridSupport.initialize();
    grid.invalidate();
  });

  hooks.afterEach(() => {
    gridSupport.destroy();
    grid.destroy();
    $fixtures.innerHTML = '';
  });

  QUnit.module('when active location changes to a header cell', () => {
    test('updates styles for the active column', () => {
      gridSupport.state.setActiveLocation('header', { cell: 1 });
      const $cell = gridSupport.state.getActiveColumnHeaderNode();
      const style = window.getComputedStyle($cell);
      equal(style.getPropertyValue('border-color'), 'rgb(12, 34, 56)', 'updates the border style');
    });

    test('removes styles for the previous active column', () => {
      gridSupport.state.setActiveLocation('header', { cell: 0 });
      const $cell = gridSupport.state.getActiveColumnHeaderNode();
      gridSupport.state.setActiveLocation('header', { cell: 1 });
      const style = window.getComputedStyle($cell);
      equal(style.getPropertyValue('border-color'), 'rgb(0, 0, 0)', 'removes the border style');
    });
  });

  QUnit.module('when active location changes to a body cell', () => {
    test('updates styles for the active column', () => {
      gridSupport.state.setActiveLocation('body', { row: 0, cell: 1 });
      const $cell = gridSupport.state.getActiveColumnHeaderNode();
      const style = window.getComputedStyle($cell);
      equal(style.getPropertyValue('border-color'), 'rgb(12, 34, 56)', 'updates the border style');
    });

    test('removes styles for the previous active column', () => {
      gridSupport.state.setActiveLocation('body', { row: 0, cell: 0 });
      const $cell = gridSupport.state.getActiveColumnHeaderNode();
      gridSupport.state.setActiveLocation('body', { row: 0, cell: 1 });
      const style = window.getComputedStyle($cell);
      equal(style.getPropertyValue('border-color'), 'rgb(0, 0, 0)', 'removes the border style');
    });
  });

  QUnit.module('when active location changes to "unknown"', () => {
    test('removes styles for the previous active column', () => {
      gridSupport.state.setActiveLocation('header', { cell: 0 });
      const $cell = gridSupport.state.getActiveColumnHeaderNode();
      gridSupport.state.setActiveLocation('unknown');
      const style = window.getComputedStyle($cell);
      equal(style.getPropertyValue('border-color'), 'rgb(0, 0, 0)', 'removes the border style');
    });
  });

  QUnit.module('when active location is the primary column header cell', () => {
    test('includes borders around the header cell', () => {
      gridSupport.state.setActiveLocation('header', { cell: 0 });
      const $cell = gridSupport.state.getActiveColumnHeaderNode();
      const style = window.getComputedStyle($cell);
      equal(style.getPropertyValue('border-bottom'), '1px solid rgb(12, 34, 56)', 'has a bottom border');
      equal(style.getPropertyValue('border-left'), '1px solid rgb(12, 34, 56)', 'has a left border');
      equal(style.getPropertyValue('border-right'), '1px solid rgb(12, 34, 56)', 'has a right border');
      equal(style.getPropertyValue('border-top'), '1px solid rgb(12, 34, 56)', 'has a top border');
    });

    test('includes side borders on the column cells', () => {
      gridSupport.state.setActiveLocation('header', { cell: 0 });
      const $cell = document.querySelector('.slick-row:first-child .slick-cell');
      const style = window.getComputedStyle($cell);
      equal(style.getPropertyValue('border-bottom-width'), '0px', 'has no bottom border');
      equal(style.getPropertyValue('border-left'), '1px solid rgb(12, 34, 56)', 'has a left border');
      equal(style.getPropertyValue('border-right'), '1px solid rgb(12, 34, 56)', 'has a right border');
      equal(style.getPropertyValue('border-top-width'), '0px', 'has no top border');
    });

    test('includes side and bottom borders on the last column cell', () => {
      gridSupport.state.setActiveLocation('header', { cell: 0 });
      const $cell = document.querySelector('.slick-row.last-row .slick-cell');
      const style = window.getComputedStyle($cell);
      equal(style.getPropertyValue('border-bottom'), '1px solid rgb(12, 34, 56)', 'has a bottom border');
      equal(style.getPropertyValue('border-left'), '1px solid rgb(12, 34, 56)', 'has a left border');
      equal(style.getPropertyValue('border-right'), '1px solid rgb(12, 34, 56)', 'has a right border');
      equal(style.getPropertyValue('border-top-width'), '0px', 'has no top border');
    });
  });

  QUnit.module('when active location is a non-primary column header cell', () => {
    test('includes borders around the header cell', () => {
      gridSupport.state.setActiveLocation('header', { cell: 1 });
      const $cell = gridSupport.state.getActiveColumnHeaderNode();
      const style = window.getComputedStyle($cell);
      equal(style.getPropertyValue('border-bottom'), '1px solid rgb(12, 34, 56)', 'has a bottom border');
      equal(style.getPropertyValue('border-left'), '1px solid rgb(12, 34, 56)', 'has a left border');
      equal(style.getPropertyValue('border-right'), '1px solid rgb(12, 34, 56)', 'has a right border');
      equal(style.getPropertyValue('border-top'), '1px solid rgb(12, 34, 56)', 'has a top border');
    });

    test('includes side borders on the column cells', () => {
      gridSupport.state.setActiveLocation('header', { cell: 0 });
      const $cell = document.querySelector('.slick-row:first-child .slick-cell');
      const style = window.getComputedStyle($cell);
      equal(style.getPropertyValue('border-bottom-width'), '0px', 'has no bottom border');
      equal(style.getPropertyValue('border-left'), '1px solid rgb(12, 34, 56)', 'has a left border');
      equal(style.getPropertyValue('border-right'), '1px solid rgb(12, 34, 56)', 'has a right border');
      equal(style.getPropertyValue('border-top-width'), '0px', 'has no top border');
    });

    test('includes side and bottom borders on the last column cell', () => {
      gridSupport.state.setActiveLocation('header', { cell: 0 });
      const $cell = document.querySelector('.slick-row.last-row .slick-cell');
      const style = window.getComputedStyle($cell);
      equal(style.getPropertyValue('border-bottom'), '1px solid rgb(12, 34, 56)', 'has a bottom border');
      equal(style.getPropertyValue('border-left'), '1px solid rgb(12, 34, 56)', 'has a left border');
      equal(style.getPropertyValue('border-right'), '1px solid rgb(12, 34, 56)', 'has a right border');
      equal(style.getPropertyValue('border-top-width'), '0px', 'has no top border');
    });
  });

  QUnit.module('when active location is a primary column body cell', () => {
    test('excludes borders around the header cell', () => {
      gridSupport.state.setActiveLocation('body', { row: 0, cell: 0 });
      const $cell = gridSupport.state.getActiveColumnHeaderNode();
      const style = window.getComputedStyle($cell);
      equal(style.getPropertyValue('border-bottom-width'), '0px', 'has no bottom border');
      equal(style.getPropertyValue('border-left-width'), '0px', 'has no left border');
      equal(style.getPropertyValue('border-right-width'), '0px', 'has no right border');
      equal(style.getPropertyValue('border-top-width'), '0px', 'has no top border');
    });

    test('excludes borders around the active body cell', () => {
      // these styles do not require dynamic GridSupport Style
      gridSupport.state.setActiveLocation('body', { row: 0, cell: 0 });
      const $cell = document.querySelector('.slick-row:first-child .slick-cell');
      const style = window.getComputedStyle($cell);
      equal(style.getPropertyValue('border-bottom-width'), '0px', 'has no bottom border');
      equal(style.getPropertyValue('border-left-width'), '0px', 'has no left border');
      equal(style.getPropertyValue('border-right-width'), '0px', 'has no right border');
      equal(style.getPropertyValue('border-top-width'), '0px', 'has no top border');
    });

    test('excludes borders around the last column cell', () => {
      gridSupport.state.setActiveLocation('body', { row: 0, cell: 0 });
      const $cell = document.querySelector('.slick-row.last-row .slick-cell');
      const style = window.getComputedStyle($cell);
      equal(style.getPropertyValue('border-bottom-width'), '0px', 'has no bottom border');
      equal(style.getPropertyValue('border-left-width'), '0px', 'has no left border');
      equal(style.getPropertyValue('border-right-width'), '0px', 'has no right border');
      equal(style.getPropertyValue('border-top-width'), '0px', 'has no top border');
    });
  });

  QUnit.module('when active location is a non-primary column body cell', () => {
    test('includes borders around the header cell', () => {
      gridSupport.state.setActiveLocation('body', { row: 0, cell: 1 });
      const $cell = gridSupport.state.getActiveColumnHeaderNode();
      const style = window.getComputedStyle($cell);
      equal(style.getPropertyValue('border-bottom'), '1px solid rgb(12, 34, 56)', 'has a bottom border');
      equal(style.getPropertyValue('border-left'), '1px solid rgb(12, 34, 56)', 'has a left border');
      equal(style.getPropertyValue('border-right'), '1px solid rgb(12, 34, 56)', 'has a right border');
      equal(style.getPropertyValue('border-top'), '1px solid rgb(12, 34, 56)', 'has a top border');
    });

    test('excludes borders around the active body cell', () => {
      // these styles do not require dynamic GridSupport Style
      gridSupport.state.setActiveLocation('body', { row: 0, cell: 1 });
      const $cell = document.querySelector('.slick-row:first-child .slick-cell.column2');
      const style = window.getComputedStyle($cell);
      equal(style.getPropertyValue('border-bottom-width'), '0px', 'has no bottom border');
      equal(style.getPropertyValue('border-left-width'), '0px', 'has no left border');
      equal(style.getPropertyValue('border-right-width'), '0px', 'has no right border');
      equal(style.getPropertyValue('border-top-width'), '0px', 'has no top border');
    });

    test('excludes side and bottom borders around the last column cell', () => {
      gridSupport.state.setActiveLocation('body', { row: 0, cell: 1 });
      const $cell = document.querySelector('.slick-row.last-row .slick-cell.column2');
      const style = window.getComputedStyle($cell);
      equal(style.getPropertyValue('border-bottom'), '1px solid rgb(12, 34, 56)', 'has a bottom border');
      equal(style.getPropertyValue('border-left'), '1px solid rgb(12, 34, 56)', 'has a left border');
      equal(style.getPropertyValue('border-right'), '1px solid rgb(12, 34, 56)', 'has a right border');
      equal(style.getPropertyValue('border-top-width'), '0px', 'has no top border');
    });
  });
});
