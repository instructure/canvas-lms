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

import { Editors, Grid } from 'vendor/slickgrid';
import GridSupport from 'jsx/gradezilla/default_gradebook/GradebookGrid/GridSupport';

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

QUnit.module('GridHelper', (suiteHooks) => {
  let $gridContainer;
  let grid;
  let gridSupport;

  suiteHooks.beforeEach(() => {
    $gridContainer = document.createElement('div');
    $gridContainer.id = 'example-grid';
    document.body.appendChild($gridContainer);
    grid = createGrid();
    gridSupport = new GridSupport(grid);
    gridSupport.initialize();
  });

  suiteHooks.afterEach(() => {
    gridSupport.destroy();
    grid.destroy();
    $gridContainer.remove();
  });

  QUnit.module('#beginEdit', (hooks) => {
    hooks.beforeEach(() => {
      gridSupport.state.setActiveLocation('body', { cell: 0, row: 0 });
      gridSupport.helper.commitCurrentEdit();
    });

    test('edits the active cell', () => {
      gridSupport.helper.beginEdit();
      strictEqual(grid.getEditorLock().isActive(), true);
    });

    test('does not edit the active cell when the grid is not editable', () => {
      grid.setOptions({ editable: false });
      gridSupport.helper.beginEdit();
      strictEqual(grid.getEditorLock().isActive(), false);
    });
  });

  QUnit.module('#focus', () => {
    test('sets focus on the grid', () => {
      gridSupport.helper.focus();
      equal(document.activeElement, gridSupport.helper.getAfterGridNode());
    });
  });
});
