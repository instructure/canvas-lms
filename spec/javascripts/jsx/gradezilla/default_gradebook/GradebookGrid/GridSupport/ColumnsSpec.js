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

import $ from 'jquery';
import slickgrid from 'vendor/slickgrid';
import GridSupport from 'jsx/gradezilla/default_gradebook/GradebookGrid/GridSupport';
import SlickGridSpecHelper from './SlickGridSpecHelper'

const { Editors, Grid } = slickgrid

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

QUnit.module('GridSupport Columns', (suiteHooks) => {
  let $fixture;
  let grid;
  let gridSpecHelper;
  let gridSupport;

  function createAndInitialize (options = {}) {
    gridSupport = new GridSupport(grid, options);
    gridSupport.initialize();
  }

  suiteHooks.beforeEach(() => {
    $fixture = document.createElement('div');
    document.body.appendChild($fixture);

    const $gridContainer = document.createElement('div');
    $gridContainer.id = 'example-grid';
    $fixture.appendChild($gridContainer);

    grid = createGrid();
    gridSpecHelper = new SlickGridSpecHelper({ grid });
  });

  suiteHooks.afterEach(() => {
    gridSupport.destroy();
    grid.destroy();
    $fixture.remove();
  });

  QUnit.module('#initialize', () => {
    let updatedColumns;

    const columnHeaderRenderer = {
      renderColumnHeader (column, _$container, _localGridSupport) {
        updatedColumns.push(column);
      },

      destroyColumnHeader () {}
    };

    test('updates all column headers when using a column header renderer', () => {
      updatedColumns = [];
      createAndInitialize({ columnHeaderRenderer });
      deepEqual(updatedColumns, grid.getColumns());
    });

    test('does not update column headers when not using a column header renderer', () => {
      updatedColumns = [];
      createAndInitialize();
      strictEqual(updatedColumns.length, 0);
    });
  });

  QUnit.module('#getColumns', () => {
    test('includes the frozen columns', () => {
      createAndInitialize();
      const columns = gridSupport.columns.getColumns();
      deepEqual(columns.frozen.map(column => column.id), ['column1', 'column2']);
    });

    test('includes the scrollable columns', () => {
      createAndInitialize();
      const columns = gridSupport.columns.getColumns();
      deepEqual(columns.scrollable.map(column => column.id), ['column3', 'column4']);
    });
  });

  QUnit.module('#getColumnsById', () => {
    test('returns the columns with the given ids', () => {
      createAndInitialize();
      const allColumns = grid.getColumns();
      const columns = gridSupport.columns.getColumnsById(['column3', 'column1']);
      deepEqual(columns, [allColumns[2], allColumns[0]]);
    });
  });

  QUnit.module('#updateColumnHeaders', (hooks) => {
    let columnHeaderRenderer;
    let updatedColumns = [];

    hooks.beforeEach(() => {
      columnHeaderRenderer = {
        renderColumnHeader (column, _$container, _localGridSupport) {
          updatedColumns.push(column);
        },

        destroyColumnHeader () {}
      };

      createAndInitialize({ columnHeaderRenderer });
      updatedColumns = [];
    });

    test('updates all column headers when given no ids', () => {
      gridSupport.columns.updateColumnHeaders();
      strictEqual(updatedColumns.length, 4);
    });

    test('sends each column to the "renderColumnHeader" function', () => {
      gridSupport.columns.updateColumnHeaders();
      deepEqual(updatedColumns, grid.getColumns());
    });

    test('updates only related column headers when given ids', () => {
      gridSupport.columns.updateColumnHeaders(['column3', 'column1']);
      const allColumns = grid.getColumns();
      deepEqual(updatedColumns, [allColumns[2], allColumns[0]]);
    });

    test('sends the header element to the "renderColumnHeader" function', () => {
      sinon.stub(columnHeaderRenderer, 'renderColumnHeader');
      gridSupport.columns.updateColumnHeaders(['column3']);
      const $container = columnHeaderRenderer.renderColumnHeader.lastCall.args[1];
      equal($container, gridSupport.helper.getColumnHeaderNode('column3'));
    });

    test('sends gridSupport to the "renderColumnHeader" function', () => {
      sinon.stub(columnHeaderRenderer, 'renderColumnHeader');
      gridSupport.columns.updateColumnHeaders(['column3']);
      const instance = columnHeaderRenderer.renderColumnHeader.lastCall.args[2];
      equal(instance, gridSupport);
    });
  });

  QUnit.module('#scrollToStart', () => {
    test('calls scrollCellIntoView', () => {
      createAndInitialize();
      const scrollCellIntoViewSpy = sinon.spy(gridSupport.grid, 'scrollCellIntoView')
      gridSupport.columns.scrollToStart()
      strictEqual(scrollCellIntoViewSpy.callCount, 1)
    });

    test('scrolls to the first column', () => {
      createAndInitialize();
      const scrollCellIntoViewSpy = sinon.spy(gridSupport.grid, 'scrollCellIntoView')
      gridSupport.columns.scrollToStart()
      strictEqual(scrollCellIntoViewSpy.firstCall.args[1], 0)
    });

    test('scrolls with the same visible row', () => {
      createAndInitialize();
      const scrollCellIntoViewSpy = sinon.spy(gridSupport.grid, 'scrollCellIntoView')
      const { top } = gridSupport.grid.getViewport()
      gridSupport.columns.scrollToStart()
      strictEqual(scrollCellIntoViewSpy.firstCall.args[0], top)
    });
  });

  QUnit.module('#scrollToEnd', () => {
    test('calls scrollCellIntoView', () => {
      createAndInitialize();
      const scrollCellIntoViewSpy = sinon.spy(gridSupport.grid, 'scrollCellIntoView')
      gridSupport.columns.scrollToEnd()
      strictEqual(scrollCellIntoViewSpy.callCount, 1)
    });

    test('scrolls to the last column', () => {
      createAndInitialize();
      const scrollCellIntoViewSpy = sinon.spy(gridSupport.grid, 'scrollCellIntoView')
      const lastColumn = gridSupport.grid.getColumns().length - 1
      gridSupport.columns.scrollToEnd()
      strictEqual(scrollCellIntoViewSpy.firstCall.args[1], lastColumn)
    });

    test('scrolls with the same visible row', () => {
      createAndInitialize();
      const scrollCellIntoViewSpy = sinon.spy(gridSupport.grid, 'scrollCellIntoView')
      const { top } = gridSupport.grid.getViewport()
      gridSupport.columns.scrollToEnd()
      strictEqual(scrollCellIntoViewSpy.firstCall.args[0], top)
    });
  });

  QUnit.module('onHeaderCellRendered', (hooks) => {
    const updateCounts = {};
    let columnHeaderRenderer;

    hooks.beforeEach(() => {
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

    test('renders column headers using the column header renderer', () => {
      const $node = gridSupport.helper.getColumnHeaderNode('column3');
      equal($node.innerHTML, 'column3 updated');
    });

    test('renders column headers on subsequent events', () => {
      grid.updateColumnHeader('column3');
      strictEqual(updateCounts.column3, 1);
    });

    test('does not update headers unrelated to the event', () => {
      grid.updateColumnHeader('column3');
      strictEqual(updateCounts.column2, 0);
    });
  });

  QUnit.module('onBeforeHeaderCellDestroy', (hooks) => {
    const destroyCounts = {};
    let columnHeaderRenderer;

    hooks.beforeEach(() => {
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

    test('destroys column headers using the column header renderer', () => {
      grid.updateColumnHeader('column3');
      strictEqual(destroyCounts.column3, 1);
    });

    test('does not destroy headers unrelated to the event', () => {
      grid.updateColumnHeader('column3');
      strictEqual(destroyCounts.column2, 0);
    });

    test('sends the header element to the "destroyColumnHeader" function', () => {
      const $originalContainer = gridSupport.helper.getColumnHeaderNode('column3');
      sinon.stub(columnHeaderRenderer, 'destroyColumnHeader');
      grid.updateColumnHeader('column3');
      const $container = columnHeaderRenderer.destroyColumnHeader.lastCall.args[1];
      equal($container, $originalContainer);
    });

    test('sends gridSupport to the "renderColumnHeader" function', () => {
      sinon.stub(columnHeaderRenderer, 'destroyColumnHeader');
      grid.updateColumnHeader('column3');
      const instance = columnHeaderRenderer.destroyColumnHeader.lastCall.args[2];
      equal(instance, gridSupport);
    });
  });

  QUnit.module('onColumnsResized', (hooks) => {
    let resizedColumns;

    function resizeHeader (columnId, widthChange) {
      const columnIndex = grid.getColumns().findIndex(column => column.id === columnId);
      const $container = grid.getContainerNode();
      const handle = $container.querySelectorAll('.slick-resizable-handle')[columnIndex];
      const header = $container.querySelectorAll('.slick-header-column')[columnIndex];
      const dragStart = new $.Event('dragstart');
      dragStart.pageX = 100;
      dragStart.pageY = 50;
      $(handle).trigger(dragStart);
      const currentWidth = $(header).outerWidth();
      header.style.setProperty('width', `${currentWidth + widthChange}px`);
      const drag = new $.Event('drag');
      drag.pageX = 100 + widthChange;
      drag.pageY = 50;
      $(handle).trigger(drag);
      $(handle).trigger('dragend');
    }

    hooks.beforeEach(() => {
      gridSupport = new GridSupport(grid);
      gridSupport.initialize();

      resizedColumns = [];

      gridSupport.events.onColumnsResized.subscribe((_event, columns) => {
        resizedColumns = columns;
      });
    });

    test('updates the width of a scaled-down column', () => {
      const originalWidth = gridSpecHelper.getColumn('column4').width;
      resizeHeader('column4', -20);
      strictEqual(gridSpecHelper.getColumn('column4').width, originalWidth - 20);
    });

    test('includes the updated column in the onColumnsResized event callback', () => {
      resizeHeader('column4', -20);
      deepEqual(resizedColumns, [gridSpecHelper.getColumn('column4')]);
    });

    test('updates the width of a scaled-up column', () => {
      const originalWidth = gridSpecHelper.getColumn('column4').width;
      resizeHeader('column4', 20);
      strictEqual(gridSpecHelper.getColumn('column4').width, originalWidth + 20);
    });

    test('updates the widths of multiple columns when the minimum width is surpassed', () => {
      resizeHeader('column4', -100);
      deepEqual(resizedColumns.map(column => column.id), ['column3', 'column4']);
    });

    test('does not trigger onColumnsResized when column widths did not change', () => {
      resizeHeader('column4', 0);
      strictEqual(resizedColumns.length, 0);
    });
  });
});
