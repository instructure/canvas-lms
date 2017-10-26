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
    editorRenderer: {
      getEditor () { return Editors.Text }
    },
    enableCellNavigation: true,
    enableColumnReorder: false,
    numberOfColumnsToFreeze: 2 // for possible edge cases with multiple grid viewports
  };
  return new Grid('#example-grid', createRows(), createColumns(), options);
}

QUnit.module('GridSupport Columns', function (suiteHooks) {
  let $fixture;
  let grid;
  let gridSupport;

  function createAndInitialize (options = {}) {
    gridSupport = new GridSupport(grid, options);
    gridSupport.initialize();
  }

  suiteHooks.beforeEach(function () {
    $fixture = document.createElement('div');
    document.body.appendChild($fixture);

    const $gridContainer = document.createElement('div');
    $gridContainer.id = 'example-grid';
    $fixture.appendChild($gridContainer);

    grid = createGrid();
  });

  suiteHooks.afterEach(function () {
    gridSupport.destroy();
    grid.destroy();
    $fixture.remove();
  });

  QUnit.module('#initialize', function () {
    let updatedColumns;

    const columnHeaderRenderer = {
      renderColumnHeader (column, _$container, _localGridSupport) {
        updatedColumns.push(column);
      },

      destroyColumnHeader () {}
    };

    test('updates all column headers when using a column header renderer', function () {
      updatedColumns = [];
      createAndInitialize({ columnHeaderRenderer });
      deepEqual(updatedColumns, grid.getColumns());
    });

    test('does not update column headers when not using a column header renderer', function () {
      updatedColumns = [];
      createAndInitialize();
      strictEqual(updatedColumns.length, 0);
    });
  });

  QUnit.module('#getColumns', function () {
    test('includes the frozen columns', function () {
      createAndInitialize();
      const columns = gridSupport.columns.getColumns();
      deepEqual(columns.frozen.map(column => column.id), ['column1', 'column2']);
    });

    test('includes the scrollable columns', function () {
      createAndInitialize();
      const columns = gridSupport.columns.getColumns();
      deepEqual(columns.scrollable.map(column => column.id), ['column3', 'column4']);
    });
  });

  QUnit.module('#getColumnsById', function () {
    test('returns the columns with the given ids', function () {
      createAndInitialize();
      const allColumns = grid.getColumns();
      const columns = gridSupport.columns.getColumnsById(['column3', 'column1']);
      deepEqual(columns, [allColumns[2], allColumns[0]]);
    });
  });

  QUnit.module('#updateColumnHeaders', function (hooks) {
    let columnHeaderRenderer;
    let updatedColumns = [];

    hooks.beforeEach(function () {
      columnHeaderRenderer = {
        renderColumnHeader (column, _$container, _localGridSupport) {
          updatedColumns.push(column);
        },

        destroyColumnHeader () {}
      };

      createAndInitialize({ columnHeaderRenderer });
      updatedColumns = [];
    });

    test('updates all column headers when given no ids', function () {
      gridSupport.columns.updateColumnHeaders();
      strictEqual(updatedColumns.length, 4);
    });

    test('sends each column to the "renderColumnHeader" function', function () {
      gridSupport.columns.updateColumnHeaders();
      deepEqual(updatedColumns, grid.getColumns());
    });

    test('updates only related column headers when given ids', function () {
      gridSupport.columns.updateColumnHeaders(['column3', 'column1']);
      const allColumns = grid.getColumns();
      deepEqual(updatedColumns, [allColumns[2], allColumns[0]]);
    });

    test('sends the header element to the "renderColumnHeader" function', function () {
      sinon.stub(columnHeaderRenderer, 'renderColumnHeader');
      gridSupport.columns.updateColumnHeaders(['column3']);
      const $container = columnHeaderRenderer.renderColumnHeader.lastCall.args[1];
      equal($container, gridSupport.helper.getColumnHeaderNode('column3'));
    });

    test('sends gridSupport to the "renderColumnHeader" function', function () {
      sinon.stub(columnHeaderRenderer, 'renderColumnHeader');
      gridSupport.columns.updateColumnHeaders(['column3']);
      const instance = columnHeaderRenderer.renderColumnHeader.lastCall.args[2];
      equal(instance, gridSupport);
    });
  });

  QUnit.module('onHeaderCellRendered', function (hooks) {
    const updateCounts = {};
    let columnHeaderRenderer;

    hooks.beforeEach(function () {
      columnHeaderRenderer = {
        renderColumnHeader (column, $container, _localGridSupport) {
          updateCounts[column.id]++;
          $container.innerText = `${column.id} updated`; // eslint-disable-line no-param-reassign
        },

        destroyColumnHeader () {}
      };

      gridSupport = new GridSupport(grid, { columnHeaderRenderer });
      gridSupport.initialize();

      grid.getColumns().forEach((column) => { updateCounts[column.id] = 0 });
    });

    test('renders column headers using the column header renderer', function () {
      const $node = gridSupport.helper.getColumnHeaderNode('column3');
      equal($node.innerHTML, 'column3 updated');
    });

    test('renders column headers on subsequent events', function () {
      grid.updateColumnHeader('column3');
      strictEqual(updateCounts.column3, 1);
    });

    test('does not update headers unrelated to the event', function () {
      grid.updateColumnHeader('column3');
      strictEqual(updateCounts.column2, 0);
    });
  });

  QUnit.module('onBeforeHeaderCellDestroy', function (hooks) {
    const destroyCounts = {};
    let columnHeaderRenderer;

    hooks.beforeEach(function () {
      columnHeaderRenderer = {
        renderColumnHeader () {},

        destroyColumnHeader (column, _$container, _localGridSupport) {
          destroyCounts[column.id]++;
        }
      };

      gridSupport = new GridSupport(grid, { columnHeaderRenderer });
      gridSupport.initialize();

      grid.getColumns().forEach((column) => { destroyCounts[column.id] = 0 });
    });

    test('destroys column headers using the column header renderer', function () {
      grid.updateColumnHeader('column3');
      strictEqual(destroyCounts.column3, 1);
    });

    test('does not destroy headers unrelated to the event', function () {
      grid.updateColumnHeader('column3');
      strictEqual(destroyCounts.column2, 0);
    });

    test('sends the header element to the "destroyColumnHeader" function', function () {
      const $originalContainer = gridSupport.helper.getColumnHeaderNode('column3');
      sinon.stub(columnHeaderRenderer, 'destroyColumnHeader');
      grid.updateColumnHeader('column3');
      const $container = columnHeaderRenderer.destroyColumnHeader.lastCall.args[1];
      equal($container, $originalContainer);
    });

    test('sends gridSupport to the "renderColumnHeader" function', function () {
      sinon.stub(columnHeaderRenderer, 'destroyColumnHeader');
      grid.updateColumnHeader('column3');
      const instance = columnHeaderRenderer.destroyColumnHeader.lastCall.args[2];
      equal(instance, gridSupport);
    });
  });
});
