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

import 'jquery.keycodes'; // used by some SlickGrid editors
import slickgrid from 'vendor/slickgrid';
import GridSupport from 'jsx/gradezilla/default_gradebook/GradebookGrid/GridSupport';

const { Editors, GlobalEditorLock, Grid } = slickgrid
const $fixtures = document.getElementById('fixtures');

function createColumns () {
  return [1, 2, 3, 4].map(id => (
    {
      id: `column${id}`,
      field: `columnData${id}`,
      name: `Column ${id}`
    }
  ));
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

QUnit.module('GridSupport State', (suiteHooks) => {
  let grid;
  let gridSupport;

  suiteHooks.beforeEach(() => {
    const $gridContainer = document.createElement('div');
    $gridContainer.id = 'example-grid';
    $fixtures.appendChild($gridContainer);
    grid = createGrid();
    gridSupport = new GridSupport(grid);
    gridSupport.initialize();
  });

  suiteHooks.afterEach(() => {
    gridSupport.destroy();
    grid.destroy();
    $fixtures.innerHTML = '';
  });

  QUnit.module('#setActiveLocation to the "before grid" region', () => {
    test('commits any current edit', () => {
      gridSupport.state.setActiveLocation('body', { row: 0, cell: 0 });
      sinon.spy(GlobalEditorLock, 'commitCurrentEdit');
      gridSupport.state.setActiveLocation('beforeGrid');
      strictEqual(GlobalEditorLock.commitCurrentEdit.callCount, 1);
      GlobalEditorLock.commitCurrentEdit.restore();
    });

    test('sets the active location after committing an edit', () => {
      let locationCommitted;
      gridSupport.state.setActiveLocation('body', { row: 0, cell: 0 });
      sinon.stub(GlobalEditorLock, 'commitCurrentEdit').callsFake(() => {
        locationCommitted = gridSupport.state.getActiveLocation();
      });
      gridSupport.state.setActiveLocation('beforeGrid');
      equal(locationCommitted.region, 'body');
      strictEqual(locationCommitted.row, 0);
      strictEqual(locationCommitted.cell, 0);
      GlobalEditorLock.commitCurrentEdit.restore();
    });

    test('sets the active location to the "before grid" region', () => {
      gridSupport.state.setActiveLocation('beforeGrid');
      const activeLocation = gridSupport.state.getActiveLocation();
      equal(activeLocation.region, 'beforeGrid');
      equal(typeof activeLocation.cell, 'undefined');
      equal(typeof activeLocation.row, 'undefined');
    });

    test('deactivates an active cell within the grid', () => {
      gridSupport.state.setActiveLocation('body', { row: 0, cell: 0 });
      gridSupport.state.setActiveLocation('beforeGrid');
      strictEqual(grid.getActiveCell(), null);
    });

    test('sets focus on the "before grid" element', () => {
      gridSupport.state.setActiveLocation('beforeGrid');
      const $beforeGridFocusSink = document.getElementById('example-grid').children[0];
      equal(document.activeElement, $beforeGridFocusSink);
    });
  });

  QUnit.module('#setActiveLocation to a header cell', () => {
    test('commits any current edit', () => {
      gridSupport.state.setActiveLocation('body', { row: 0, cell: 0 });
      sinon.spy(GlobalEditorLock, 'commitCurrentEdit');
      gridSupport.state.setActiveLocation('header', { cell: 1 });
      strictEqual(GlobalEditorLock.commitCurrentEdit.callCount, 1);
      GlobalEditorLock.commitCurrentEdit.restore();
    });

    test('sets the active location after committing an edit', () => {
      let locationCommitted;
      gridSupport.state.setActiveLocation('body', { row: 0, cell: 0 });
      sinon.stub(GlobalEditorLock, 'commitCurrentEdit').callsFake(() => {
        locationCommitted = gridSupport.state.getActiveLocation();
      });
      gridSupport.state.setActiveLocation('header', { cell: 1 });
      equal(locationCommitted.region, 'body');
      strictEqual(locationCommitted.row, 0);
      strictEqual(locationCommitted.cell, 0);
      GlobalEditorLock.commitCurrentEdit.restore();
    });

    test('activates the header cell', () => {
      gridSupport.state.setActiveLocation('header', { cell: 1 });
      const activeLocation = gridSupport.state.getActiveLocation();
      equal(activeLocation.region, 'header');
      strictEqual(activeLocation.cell, 1);
      equal(typeof activeLocation.row, 'undefined');
    });

    test('deactivates an active cell within the grid', () => {
      gridSupport.state.setActiveLocation('body', { row: 0, cell: 0 });
      gridSupport.state.setActiveLocation('header', { cell: 1 });
      strictEqual(grid.getActiveCell(), null);
    });

    test('sets focus on the "before grid" element', () => {
      gridSupport.state.setActiveLocation('header', { cell: 1 });
      const $beforeGridFocusSink = document.getElementById('example-grid').children[0];
      equal(document.activeElement, $beforeGridFocusSink);
    });
  });

  QUnit.module('#setActiveLocation to a body cell', () => {
    test('activates the body cell', () => {
      gridSupport.state.setActiveLocation('body', { row: 0, cell: 1 });
      const activeLocation = gridSupport.state.getActiveLocation();
      equal(activeLocation.region, 'body');
      strictEqual(activeLocation.cell, 1);
      strictEqual(activeLocation.row, 0);
    });

    test('activates the cell within the grid', () => {
      gridSupport.state.setActiveLocation('body', { row: 0, cell: 1 });
      deepEqual(grid.getActiveCell(), { row: 0, cell: 1 });
    });

    test('creates an editor for the cell', () => {
      gridSupport.state.setActiveLocation('body', { row: 0, cell: 1 });
      ok(grid.getCellEditor(), 'an editor exists for the active cell');
    });
  });

  QUnit.module('#setActiveLocation to the "after grid" region', () => {
    test('sets the active location to the "after grid" region', () => {
      gridSupport.state.setActiveLocation('afterGrid');
      const activeLocation = gridSupport.state.getActiveLocation();
      equal(activeLocation.region, 'afterGrid');
      equal(typeof activeLocation.cell, 'undefined');
      equal(typeof activeLocation.row, 'undefined');
    });

    test('deactivates an active cell within the grid', () => {
      gridSupport.state.setActiveLocation('body', { row: 0, cell: 0 });
      gridSupport.state.setActiveLocation('afterGrid');
      strictEqual(grid.getActiveCell(), null);
    });

    test('sets focus on the "after grid" element', () => {
      gridSupport.state.setActiveLocation('afterGrid');
      const $afterGridFocusSink = document.getElementById('example-grid').children[3];
      equal(document.activeElement, $afterGridFocusSink);
    });
  });

  QUnit.module('#setActiveLocation to an "unknown" region', () => {
    test('sets the active location to "unknown"', () => {
      gridSupport.state.setActiveLocation('unknown');
      const activeLocation = gridSupport.state.getActiveLocation();
      equal(activeLocation.region, 'unknown');
      equal(typeof activeLocation.cell, 'undefined');
      equal(typeof activeLocation.row, 'undefined');
    });

    test('deactivates an active cell within the grid', () => {
      gridSupport.state.setActiveLocation('body', { row: 0, cell: 0 });
      gridSupport.state.setActiveLocation('unknown');
      strictEqual(grid.getActiveCell(), null);
    });

    test('sets focus on the "after grid" element', () => {
      const $offGridFocus = document.createElement('input');
      $offGridFocus.id = 'off-grid-focus';
      $fixtures.appendChild($offGridFocus);
      gridSupport.state.setActiveLocation('beforeGrid');
      $offGridFocus.focus();
      gridSupport.state.setActiveLocation('unknown');
      equal(document.activeElement, $offGridFocus);
    });
  });

  QUnit.module('#resetActiveLocation', () => {
    test('commits any current edit', () => {
      gridSupport.state.setActiveLocation('body', { row: 0, cell: 0 });
      sinon.spy(GlobalEditorLock, 'commitCurrentEdit');
      gridSupport.state.resetActiveLocation();
      strictEqual(GlobalEditorLock.commitCurrentEdit.callCount, 1);
      GlobalEditorLock.commitCurrentEdit.restore();
    });

    test('sets the active location after committing an edit', () => {
      let locationCommitted;
      gridSupport.state.setActiveLocation('body', { row: 0, cell: 0 });
      sinon.stub(GlobalEditorLock, 'commitCurrentEdit').callsFake(() => {
        locationCommitted = gridSupport.state.getActiveLocation();
      });
      gridSupport.state.resetActiveLocation();
      equal(locationCommitted.region, 'body');
      strictEqual(locationCommitted.row, 0);
      strictEqual(locationCommitted.cell, 0);
      GlobalEditorLock.commitCurrentEdit.restore();
    });

    test('sets the active location to the "before grid" region', () => {
      gridSupport.state.setActiveLocation('body', { row: 0, cell: 0 });
      gridSupport.state.resetActiveLocation();
      const activeLocation = gridSupport.state.getActiveLocation();
      equal(activeLocation.region, 'beforeGrid');
      equal(typeof activeLocation.cell, 'undefined');
      equal(typeof activeLocation.row, 'undefined');
    });

    test('deactivates an active cell within the grid', () => {
      gridSupport.state.setActiveLocation('body', { row: 0, cell: 0 });
      gridSupport.state.resetActiveLocation();
      strictEqual(grid.getActiveCell(), null);
    });

    test('sets focus on the "before grid" element', () => {
      gridSupport.state.setActiveLocation('body', { row: 0, cell: 0 });
      gridSupport.state.resetActiveLocation();
      const $beforeGridFocusSink = document.getElementById('example-grid').children[0];
      equal(document.activeElement, $beforeGridFocusSink);
    });
  });

  QUnit.module('#restorePreviousLocation', () => {
    test('sets the active location to the first header cell when no previous location exists', () => {
      gridSupport.state.restorePreviousLocation();

      const activeLocation = gridSupport.state.getActiveLocation();
      equal(activeLocation.region, 'header');
      strictEqual(activeLocation.cell, 0);
      equal(typeof activeLocation.row, 'undefined');
    });

    test('sets the active location to the previously-selected cell when one is set', () => {
      gridSupport.state.setActiveLocation('body', { cell: 1, row: 1 });
      gridSupport.state.blur();
      gridSupport.state.restorePreviousLocation();

      const activeLocation = gridSupport.state.getActiveLocation();
      equal(activeLocation.region, 'body');
      strictEqual(activeLocation.cell, 1);
      strictEqual(activeLocation.row, 1);
    });

    test('sets the active location to the previously-selected body cell when the column has moved', () => {
      gridSupport.state.setActiveLocation('body', { cell: 1, row: 1 });

      grid.setColumns(createColumns().reverse());
      gridSupport.state.restorePreviousLocation();

      const activeLocation = gridSupport.state.getActiveLocation();
      equal(activeLocation.region, 'body');
      strictEqual(activeLocation.cell, 2);
      strictEqual(activeLocation.row, 1);
    });

    test('sets the active location to the previously-selected header cell when the column has moved', () => {
      gridSupport.state.setActiveLocation('header', { cell: 1 });

      grid.setColumns(createColumns().reverse());
      gridSupport.state.restorePreviousLocation();

      const activeLocation = gridSupport.state.getActiveLocation();
      equal(activeLocation.region, 'header');
      strictEqual(activeLocation.cell, 2);
      equal(typeof activeLocation.row, 'undefined');
    });

    test('sets the active location to the previously-selected body cell when the row has moved', () => {
      gridSupport.state.setActiveLocation('body', { cell: 1, row: 1 });

      grid.setData(createRows().reverse());
      gridSupport.state.restorePreviousLocation();

      const activeLocation = gridSupport.state.getActiveLocation();
      equal(activeLocation.region, 'body');
      strictEqual(activeLocation.cell, 1);
      strictEqual(activeLocation.row, 0);
    });

    test('sets the active location to the first header cell when the previously-selected column was removed', () => {
      gridSupport.state.setActiveLocation('body', { cell: 1, row: 1 });

      grid.setColumns(createColumns().slice(2));
      gridSupport.state.restorePreviousLocation();

      const activeLocation = gridSupport.state.getActiveLocation();
      equal(activeLocation.region, 'header');
      strictEqual(activeLocation.cell, 0);
      equal(typeof activeLocation.row, 'undefined');
    });

    test('sets the active location to the first header cell when the previously-selected row was removed', () => {
      gridSupport.state.setActiveLocation('body', { cell: 1, row: 1 });

      grid.setData(createRows().slice(0, 1));
      gridSupport.state.restorePreviousLocation();

      const activeLocation = gridSupport.state.getActiveLocation();
      equal(activeLocation.region, 'header');
      strictEqual(activeLocation.cell, 0);
      equal(typeof activeLocation.row, 'undefined');
    });
  });

  QUnit.module('#getActiveNode', () => {
    test('returns the element for an active header cell', () => {
      gridSupport.state.setActiveLocation('header', { cell: 1 });
      const $headerCell = document.querySelectorAll('.slick-header-column')[1];
      strictEqual(gridSupport.state.getActiveNode(), $headerCell);
    });

    test('returns the element for an active body cell', () => {
      gridSupport.state.setActiveLocation('body', { row: 0, cell: 1 });
      equal(gridSupport.state.getActiveNode(), grid.getActiveCellNode());
    });

    test('returns null when "before grid" is the active location', () => {
      gridSupport.state.setActiveLocation('beforeGrid');
      strictEqual(gridSupport.state.getActiveNode(), null);
    });

    test('returns null when "after grid" is the active location', () => {
      gridSupport.state.setActiveLocation('afterGrid');
      strictEqual(gridSupport.state.getActiveNode(), null);
    });

    test('returns null when "unknown" is the active location', () => {
      gridSupport.state.setActiveLocation('unknown');
      strictEqual(gridSupport.state.getActiveNode(), null);
    });
  });

  QUnit.module('#getEditingNode', () => {
    test('returns null for an active header cell', () => {
      gridSupport.state.setActiveLocation('header', { cell: 1 });
      strictEqual(gridSupport.state.getEditingNode(), null);
    });

    test('returns the element for an active body cell editor', () => {
      gridSupport.state.setActiveLocation('body', { row: 0, cell: 1 });
      equal(gridSupport.state.getEditingNode(), grid.getActiveCellNode());
    });

    test('returns null for an active body cell without an editor', () => {
      gridSupport.state.setActiveLocation('body', { row: 0, cell: 1 });
      gridSupport.helper.commitCurrentEdit();
      strictEqual(gridSupport.state.getEditingNode(), null);
    });

    test('returns null when "before grid" is the active location', () => {
      gridSupport.state.setActiveLocation('beforeGrid');
      strictEqual(gridSupport.state.getEditingNode(), null);
    });

    test('returns null when "after grid" is the active location', () => {
      gridSupport.state.setActiveLocation('afterGrid');
      strictEqual(gridSupport.state.getEditingNode(), null);
    });

    test('returns null when "unknown" is the active location', () => {
      gridSupport.state.setActiveLocation('unknown');
      strictEqual(gridSupport.state.getEditingNode(), null);
    });
  });

  QUnit.module('#getActiveColumnHeaderNode', () => {
    test('returns the element for an active header cell', () => {
      gridSupport.state.setActiveLocation('header', { cell: 1 });
      const $headerCell = document.querySelectorAll('.slick-header-column')[1];
      strictEqual(gridSupport.state.getActiveColumnHeaderNode(), $headerCell);
    });

    test('returns the header element associated with an active body cell', () => {
      gridSupport.state.setActiveLocation('body', { row: 0, cell: 1 });
      const $headerCell = document.querySelectorAll('.slick-header-column')[1];
      strictEqual(gridSupport.state.getActiveColumnHeaderNode(), $headerCell);
    });

    test('returns null when "before grid" is the active location', () => {
      gridSupport.state.setActiveLocation('beforeGrid');
      strictEqual(gridSupport.state.getActiveColumnHeaderNode(), null);
    });

    test('returns null when "after grid" is the active location', () => {
      gridSupport.state.setActiveLocation('afterGrid');
      strictEqual(gridSupport.state.getActiveColumnHeaderNode(), null);
    });

    test('returns null when "unknown" is the active location', () => {
      gridSupport.state.setActiveLocation('unknown');
      strictEqual(gridSupport.state.getActiveColumnHeaderNode(), null);
    });
  });

  QUnit.module('#blur', (hooks) => {
    hooks.beforeEach(() => {
      gridSupport.state.setActiveLocation('body', { row: 0, cell: 0 });
    });

    test('commits any current edit', () => {
      sinon.spy(GlobalEditorLock, 'commitCurrentEdit');
      gridSupport.state.blur();
      strictEqual(GlobalEditorLock.commitCurrentEdit.callCount, 1);
      GlobalEditorLock.commitCurrentEdit.restore();
    });

    test('deactivates the cell within the grid', () => {
      gridSupport.state.blur();
      strictEqual(grid.getActiveCell(), null);
    });

    test('sets the active location to "unknown"', () => {
      gridSupport.state.blur();
      const activeLocation = gridSupport.state.getActiveLocation();
      equal(activeLocation.region, 'unknown');
      equal(typeof activeLocation.cell, 'undefined');
      equal(typeof activeLocation.row, 'undefined');
    });
  });

  QUnit.module('with item metadata', () => {
    test('applies the "first-row" class to the first row of data', () => {
      grid.invalidate();
      const $rows = document.querySelectorAll('.slick-row');
      strictEqual($rows[0], document.querySelector('.slick-row.first-row'));
    });

    test('applies the "last-row" class to the last row of data', () => {
      grid.invalidate();
      const $rows = document.querySelectorAll('.slick-row');
      strictEqual($rows[1], document.querySelector('.slick-row.last-row'));
    });

    test('applies the row "cssClass" to each row', () => {
      grid.invalidate();
      const $rows = document.querySelectorAll('.slick-row');
      strictEqual($rows[0], document.querySelector('.slick-row.row_A'), '"row_A" is applied to the first row');
      strictEqual($rows[1], document.querySelector('.slick-row.row_B'), '"row_B" is applied to the second row');
    });
  });
});
