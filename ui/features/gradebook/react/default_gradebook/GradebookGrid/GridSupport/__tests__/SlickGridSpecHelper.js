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

export default class SlickGridSpecHelper {
  constructor(gradebookGrid) {
    this.grid = gradebookGrid.grid
  }

  getColumn(id) {
    return this.grid.getColumns().find(column => column.id === id)
  }

  listColumns() {
    return this.grid.getColumns()
  }

  listColumnIds() {
    return this.grid.getColumns().map(column => column.id)
  }

  listFrozenColumnIds() {
    return this.listColumnIds().slice(0, this.grid.getOptions().numberOfColumnsToFreeze)
  }

  listScrollableColumnIds() {
    return this.listColumnIds().slice(this.grid.getOptions().numberOfColumnsToFreeze)
  }

  updateColumnOrder(columnIds) {
    const columns = this.grid.getColumns()
    this.grid.setColumns(columnIds.map(id => columns.find(column => column.id === id)))
    this.grid.onColumnsReordered.notify()
  }

  getColumnHeaderNode(columnId) {
    return this.grid.getColumnHeaderNode(columnId)
  }
}
