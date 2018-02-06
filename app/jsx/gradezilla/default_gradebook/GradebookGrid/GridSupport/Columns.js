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

function destroyColumnHeader (column, $node, gridSupport) {
  if (gridSupport.options.columnHeaderRenderer) {
    gridSupport.options.columnHeaderRenderer.destroyColumnHeader(column, $node, gridSupport);
  }
}

export default class Columns {
  constructor (grid, gridSupport) {
    this.grid = grid;
    this.gridSupport = gridSupport;
  }

  initialize () {
    this.grid.onHeaderCellRendered.subscribe((_event, object) => {
      this.updateColumnHeaders([object.column.id]);
    });

    this.grid.onBeforeHeaderCellDestroy.subscribe((_event, object) => {
      destroyColumnHeader(object.column, object.node, this.gridSupport);
    });

    this.grid.onColumnsResized.subscribe((sourceEvent, _object) => {
      const event = sourceEvent.originalEvent || sourceEvent;
      const columns = this.grid.getColumns();
      const resizedColumns = [];

      for (let i = 0; i < columns.length; i++) {
        const column = columns[i];
        if (column.previousWidth != null && column.previousWidth !== column.width) {
          resizedColumns.push(column);
        }
      }

      if (resizedColumns.length) {
        this.gridSupport.events.onColumnsResized.trigger(event, resizedColumns);
      }
    });

    this.updateColumnHeaders();
  }

  getColumns () {
    const columns = this.grid.getColumns();
    const frozenCount = this.grid.getOptions().numberOfColumnsToFreeze;

    return {
      frozen: columns.slice(0, frozenCount),
      scrollable: columns.slice(frozenCount)
    };
  }

  getColumnsById (columnIds) {
    const columns = this.grid.getColumns();
    const columnMap = columns.reduce((map, column) => ({ ...map, [column.id]: column }), {});
    return columnIds.map(columnId => columnMap[columnId]);
  }

  updateColumnHeaders (columnIds = []) {
    if (this.gridSupport.options.columnHeaderRenderer) {
      const columns = columnIds.length ? this.getColumnsById(columnIds) : this.grid.getColumns();

      columns.forEach((column) => {
        const $node = this.gridSupport.helper.getColumnHeaderNode(column.id);
        this.gridSupport.options.columnHeaderRenderer.renderColumnHeader(column, $node, this.gridSupport);
      });
    }
  }

  scrollToStart () {
    const { top } = this.grid.getViewport()
    this.grid.scrollCellIntoView(top, 0)
  }

  scrollToEnd () {
    const { top } = this.grid.getViewport()
    this.grid.scrollCellIntoView(top, this.grid.getColumns().length - 1)
  }
}
