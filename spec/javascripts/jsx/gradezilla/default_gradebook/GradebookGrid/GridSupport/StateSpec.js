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
import { Editors, GlobalEditorLock, Grid } from 'vendor/slickgrid';
import GridSupport from 'jsx/gradezilla/default_gradebook/GradebookGrid/GridSupport';

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

QUnit.module('GridSupport State', function (hooks) {
  hooks.beforeEach(function () {
    const $gridContainer = document.createElement('div');
    $gridContainer.id = 'example-grid';
    $fixtures.appendChild($gridContainer);
    this.grid = createGrid();
    this.gridSupport = new GridSupport(this.grid);
    this.gridSupport.initialize();
  });

  hooks.afterEach(function () {
    this.gridSupport.destroy();
    this.grid.destroy();
    $fixtures.innerHTML = '';
  });

  QUnit.module('#setActiveLocation to the "before grid" region');

  test('commits any current edit', function () {
    this.gridSupport.state.setActiveLocation('body', { row: 0, cell: 0 });
    this.spy(GlobalEditorLock, 'commitCurrentEdit');
    this.gridSupport.state.setActiveLocation('beforeGrid');
    strictEqual(GlobalEditorLock.commitCurrentEdit.callCount, 1);
  });

  test('sets the active location after committing an edit', function () {
    let locationCommitted;
    this.gridSupport.state.setActiveLocation('body', { row: 0, cell: 0 });
    this.stub(GlobalEditorLock, 'commitCurrentEdit').callsFake(() => {
      locationCommitted = this.gridSupport.state.getActiveLocation();
    });
    this.gridSupport.state.setActiveLocation('beforeGrid');
    equal(locationCommitted.region, 'body');
    strictEqual(locationCommitted.row, 0);
    strictEqual(locationCommitted.cell, 0);
  });

  test('sets the active location to the "before grid" region', function () {
    this.gridSupport.state.setActiveLocation('beforeGrid');
    const activeLocation = this.gridSupport.state.getActiveLocation();
    equal(activeLocation.region, 'beforeGrid');
    equal(typeof activeLocation.cell, 'undefined');
    equal(typeof activeLocation.row, 'undefined');
  });

  test('deactivates an active cell within the grid', function () {
    this.gridSupport.state.setActiveLocation('body', { row: 0, cell: 0 });
    this.gridSupport.state.setActiveLocation('beforeGrid');
    strictEqual(this.grid.getActiveCell(), null);
  });

  test('sets focus on the "before grid" element', function () {
    this.gridSupport.state.setActiveLocation('beforeGrid');
    const $beforeGridFocusSink = document.getElementById('example-grid').children[0];
    equal(document.activeElement, $beforeGridFocusSink);
  });

  QUnit.module('#setActiveLocation to a header cell');

  test('commits any current edit', function () {
    this.gridSupport.state.setActiveLocation('body', { row: 0, cell: 0 });
    this.spy(GlobalEditorLock, 'commitCurrentEdit');
    this.gridSupport.state.setActiveLocation('header', { cell: 1 });
    strictEqual(GlobalEditorLock.commitCurrentEdit.callCount, 1);
  });

  test('sets the active location after committing an edit', function () {
    let locationCommitted;
    this.gridSupport.state.setActiveLocation('body', { row: 0, cell: 0 });
    this.stub(GlobalEditorLock, 'commitCurrentEdit').callsFake(() => {
      locationCommitted = this.gridSupport.state.getActiveLocation();
    });
    this.gridSupport.state.setActiveLocation('header', { cell: 1 });
    equal(locationCommitted.region, 'body');
    strictEqual(locationCommitted.row, 0);
    strictEqual(locationCommitted.cell, 0);
  });

  test('activates the header cell', function () {
    this.gridSupport.state.setActiveLocation('header', { cell: 1 });
    const activeLocation = this.gridSupport.state.getActiveLocation();
    equal(activeLocation.region, 'header');
    strictEqual(activeLocation.cell, 1);
    equal(typeof activeLocation.row, 'undefined');
  });

  test('deactivates an active cell within the grid', function () {
    this.gridSupport.state.setActiveLocation('body', { row: 0, cell: 0 });
    this.gridSupport.state.setActiveLocation('header', { cell: 1 });
    strictEqual(this.grid.getActiveCell(), null);
  });

  test('sets focus on the "before grid" element', function () {
    this.gridSupport.state.setActiveLocation('header', { cell: 1 });
    const $beforeGridFocusSink = document.getElementById('example-grid').children[0];
    equal(document.activeElement, $beforeGridFocusSink);
  });

  QUnit.module('#setActiveLocation to a body cell');

  test('activates the body cell', function () {
    this.gridSupport.state.setActiveLocation('body', { row: 0, cell: 1 });
    const activeLocation = this.gridSupport.state.getActiveLocation();
    equal(activeLocation.region, 'body');
    strictEqual(activeLocation.cell, 1);
    strictEqual(activeLocation.row, 0);
  });

  test('activates the cell within the grid', function () {
    this.gridSupport.state.setActiveLocation('body', { row: 0, cell: 1 });
    deepEqual(this.grid.getActiveCell(), { row: 0, cell: 1 });
  });

  test('creates an editor for the cell', function () {
    this.gridSupport.state.setActiveLocation('body', { row: 0, cell: 1 });
    ok(this.grid.getCellEditor(), 'an editor exists for the active cell');
  });

  QUnit.module('#setActiveLocation to the "after grid" region');

  test('sets the active location to the "after grid" region', function () {
    this.gridSupport.state.setActiveLocation('afterGrid');
    const activeLocation = this.gridSupport.state.getActiveLocation();
    equal(activeLocation.region, 'afterGrid');
    equal(typeof activeLocation.cell, 'undefined');
    equal(typeof activeLocation.row, 'undefined');
  });

  test('deactivates an active cell within the grid', function () {
    this.gridSupport.state.setActiveLocation('body', { row: 0, cell: 0 });
    this.gridSupport.state.setActiveLocation('afterGrid');
    strictEqual(this.grid.getActiveCell(), null);
  });

  test('sets focus on the "after grid" element', function () {
    this.gridSupport.state.setActiveLocation('afterGrid');
    const $afterGridFocusSink = document.getElementById('example-grid').children[3];
    equal(document.activeElement, $afterGridFocusSink);
  });

  QUnit.module('#setActiveLocation to an "unknown" region');

  test('sets the active location to "unknown"', function () {
    this.gridSupport.state.setActiveLocation('unknown');
    const activeLocation = this.gridSupport.state.getActiveLocation();
    equal(activeLocation.region, 'unknown');
    equal(typeof activeLocation.cell, 'undefined');
    equal(typeof activeLocation.row, 'undefined');
  });

  test('deactivates an active cell within the grid', function () {
    this.gridSupport.state.setActiveLocation('body', { row: 0, cell: 0 });
    this.gridSupport.state.setActiveLocation('unknown');
    strictEqual(this.grid.getActiveCell(), null);
  });

  test('sets focus on the "after grid" element', function () {
    const $offGridFocus = document.createElement('input');
    $offGridFocus.id = 'off-grid-focus';
    $fixtures.appendChild($offGridFocus);
    this.gridSupport.state.setActiveLocation('beforeGrid');
    $offGridFocus.focus();
    this.gridSupport.state.setActiveLocation('unknown');
    equal(document.activeElement, $offGridFocus);
  });

  QUnit.module('#resetActiveLocation');

  test('commits any current edit', function () {
    this.gridSupport.state.setActiveLocation('body', { row: 0, cell: 0 });
    this.spy(GlobalEditorLock, 'commitCurrentEdit');
    this.gridSupport.state.resetActiveLocation();
    strictEqual(GlobalEditorLock.commitCurrentEdit.callCount, 1);
  });

  test('sets the active location after committing an edit', function () {
    let locationCommitted;
    this.gridSupport.state.setActiveLocation('body', { row: 0, cell: 0 });
    this.stub(GlobalEditorLock, 'commitCurrentEdit').callsFake(() => {
      locationCommitted = this.gridSupport.state.getActiveLocation();
    });
    this.gridSupport.state.resetActiveLocation();
    equal(locationCommitted.region, 'body');
    strictEqual(locationCommitted.row, 0);
    strictEqual(locationCommitted.cell, 0);
  });

  test('sets the active location to the "before grid" region', function () {
    this.gridSupport.state.setActiveLocation('body', { row: 0, cell: 0 });
    this.gridSupport.state.resetActiveLocation();
    const activeLocation = this.gridSupport.state.getActiveLocation();
    equal(activeLocation.region, 'beforeGrid');
    equal(typeof activeLocation.cell, 'undefined');
    equal(typeof activeLocation.row, 'undefined');
  });

  test('deactivates an active cell within the grid', function () {
    this.gridSupport.state.setActiveLocation('body', { row: 0, cell: 0 });
    this.gridSupport.state.resetActiveLocation();
    strictEqual(this.grid.getActiveCell(), null);
  });

  test('sets focus on the "before grid" element', function () {
    this.gridSupport.state.setActiveLocation('body', { row: 0, cell: 0 });
    this.gridSupport.state.resetActiveLocation();
    const $beforeGridFocusSink = document.getElementById('example-grid').children[0];
    equal(document.activeElement, $beforeGridFocusSink);
  });

  QUnit.module('#getActiveNode');

  test('returns the element for an active header cell', function () {
    this.gridSupport.state.setActiveLocation('header', { cell: 1 });
    const $headerCell = document.querySelectorAll('.slick-header-column')[1];
    strictEqual(this.gridSupport.state.getActiveNode(), $headerCell);
  });

  test('returns the element for an active body cell', function () {
    this.gridSupport.state.setActiveLocation('body', { row: 0, cell: 1 });
    equal(this.gridSupport.state.getActiveNode(), this.grid.getActiveCellNode());
  });

  test('returns null when "before grid" is the active location', function () {
    this.gridSupport.state.setActiveLocation('beforeGrid');
    strictEqual(this.gridSupport.state.getActiveNode(), null);
  });

  test('returns null when "after grid" is the active location', function () {
    this.gridSupport.state.setActiveLocation('afterGrid');
    strictEqual(this.gridSupport.state.getActiveNode(), null);
  });

  test('returns null when "unknown" is the active location', function () {
    this.gridSupport.state.setActiveLocation('unknown');
    strictEqual(this.gridSupport.state.getActiveNode(), null);
  });

  QUnit.module('#getEditingNode');

  test('returns null for an active header cell', function () {
    this.gridSupport.state.setActiveLocation('header', { cell: 1 });
    strictEqual(this.gridSupport.state.getEditingNode(), null);
  });

  test('returns the element for an active body cell editor', function () {
    this.gridSupport.state.setActiveLocation('body', { row: 0, cell: 1 });
    equal(this.gridSupport.state.getEditingNode(), this.grid.getActiveCellNode());
  });

  test('returns null for an active body cell without an editor', function () {
    this.gridSupport.state.setActiveLocation('body', { row: 0, cell: 1 });
    this.gridSupport.helper.commitCurrentEdit();
    strictEqual(this.gridSupport.state.getEditingNode(), null);
  });

  test('returns null when "before grid" is the active location', function () {
    this.gridSupport.state.setActiveLocation('beforeGrid');
    strictEqual(this.gridSupport.state.getEditingNode(), null);
  });

  test('returns null when "after grid" is the active location', function () {
    this.gridSupport.state.setActiveLocation('afterGrid');
    strictEqual(this.gridSupport.state.getEditingNode(), null);
  });

  test('returns null when "unknown" is the active location', function () {
    this.gridSupport.state.setActiveLocation('unknown');
    strictEqual(this.gridSupport.state.getEditingNode(), null);
  });

  QUnit.module('#getActiveColumnHeaderNode');

  test('returns the element for an active header cell', function () {
    this.gridSupport.state.setActiveLocation('header', { cell: 1 });
    const $headerCell = document.querySelectorAll('.slick-header-column')[1];
    strictEqual(this.gridSupport.state.getActiveColumnHeaderNode(), $headerCell);
  });

  test('returns the header element associated with an active body cell', function () {
    this.gridSupport.state.setActiveLocation('body', { row: 0, cell: 1 });
    const $headerCell = document.querySelectorAll('.slick-header-column')[1];
    strictEqual(this.gridSupport.state.getActiveColumnHeaderNode(), $headerCell);
  });

  test('returns null when "before grid" is the active location', function () {
    this.gridSupport.state.setActiveLocation('beforeGrid');
    strictEqual(this.gridSupport.state.getActiveColumnHeaderNode(), null);
  });

  test('returns null when "after grid" is the active location', function () {
    this.gridSupport.state.setActiveLocation('afterGrid');
    strictEqual(this.gridSupport.state.getActiveColumnHeaderNode(), null);
  });

  test('returns null when "unknown" is the active location', function () {
    this.gridSupport.state.setActiveLocation('unknown');
    strictEqual(this.gridSupport.state.getActiveColumnHeaderNode(), null);
  });

  QUnit.module('#blur', {
    setup () {
      this.gridSupport.state.setActiveLocation('body', { row: 0, cell: 0 });
    }
  });

  test('commits any current edit', function () {
    this.spy(GlobalEditorLock, 'commitCurrentEdit');
    this.gridSupport.state.blur();
    strictEqual(GlobalEditorLock.commitCurrentEdit.callCount, 1);
  });

  test('deactivates the cell within the grid', function () {
    this.gridSupport.state.blur();
    strictEqual(this.grid.getActiveCell(), null);
  });

  test('sets the active location to "unknown"', function () {
    this.gridSupport.state.blur();
    const activeLocation = this.gridSupport.state.getActiveLocation();
    equal(activeLocation.region, 'unknown');
    equal(typeof activeLocation.cell, 'undefined');
    equal(typeof activeLocation.row, 'undefined');
  });

  QUnit.module('with item metadata');

  test('applies the "first-row" class to the first row of data', function () {
    this.grid.invalidate();
    const $rows = document.querySelectorAll('.slick-row');
    strictEqual($rows[0], document.querySelector('.slick-row.first-row'));
  });

  test('applies the "last-row" class to the last row of data', function () {
    this.grid.invalidate();
    const $rows = document.querySelectorAll('.slick-row');
    strictEqual($rows[1], document.querySelector('.slick-row.last-row'));
  });

  test('applies the row "cssClass" to each row', function () {
    this.grid.invalidate();
    const $rows = document.querySelectorAll('.slick-row');
    strictEqual($rows[0], document.querySelector('.slick-row.row_A'), '"row_A" is applied to the first row');
    strictEqual($rows[1], document.querySelector('.slick-row.row_B'), '"row_B" is applied to the second row');
  });
});
