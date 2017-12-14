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

export default class Columns {
  constructor (gradebookGrid) {
    this.gradebookGrid = gradebookGrid;
  }

  initialize () {
    const { events, grid, gridData, gridSupport } = this.gradebookGrid;

    grid.onColumnsReordered.subscribe((sourceEvent, _object) => {
      const event = sourceEvent.originalEvent || sourceEvent;
      const columns = gridSupport.columns.getColumns();
      const orderChanged = (
        columns.frozen.some((column, index) => column.id !== gridData.columns.frozen[index]) ||
        columns.scrollable.some((column, index) => column.id !== gridData.columns.scrollable[index])
      );
      if (orderChanged) {
        events.onColumnsReordered.trigger(event, columns);
      }
    });

    gridSupport.events.onColumnsResized.subscribe((event, columns) => {
      for (let i = 0; i < columns.length; i++) {
        gridData.columns.definitions[columns[i].id] = columns[i];
      }

      events.onColumnsResized.trigger(event, columns);
    });
  }
}
