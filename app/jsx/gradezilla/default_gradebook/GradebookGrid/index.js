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

import { Grid } from 'vendor/slickgrid';
import 'jqueryui/sortable';
import GridSupport from './GridSupport';

export default class GradebookGrid {
  constructor (options) {
    this.gridData = options.data;
    this.options = options;
  }

  initialize () {
    const options = {
      autoEdit: true, // whether to go into edit-mode as soon as you tab to a cell
      change_grade_url: this.options.change_grade_url, // used by SubmissionCell
      editable: this.options.editable,
      editorFactory: this.options.editorFactory,
      enableCellNavigation: true,
      enableColumnReorder: true,
      formatterFactory: this.options.formatterFactory,
      headerHeight: 38,
      numberOfColumnsToFreeze: this.gridData.columns.frozen.length,
      rowHeight: 35,
      syncColumnCellResize: true
    };

    const columns = [...this.gridData.columns.frozen, ...this.gridData.columns.scrollable].map((columnId) => (
      this.gridData.columns.definitions[columnId]
    ));

    this.grid = new Grid(this.options.$container, this.gridData.rows, columns, options);
    this.grid.setSortColumn('student');

    const gridSupportOptions = {
      activeBorderColor: this.options.activeBorderColor,
      activeHeaderBackground: this.options.activeHeaderBackground,
      columnHeaderRenderer: this.options.columnHeaderRenderer,
      rows: this.gridData.rows
    };
    this.gridSupport = new GridSupport(this.grid, gridSupportOptions);
  }

  invalidate () {
    if (this.grid) {
      this.grid.invalidate();
    }
  }

  invalidateRow (index) {
    if (this.grid) {
      this.grid.invalidateRow(index);
    }
  }

  render () {
    if (this.grid) {
      this.grid.render();
    }
  }
}
