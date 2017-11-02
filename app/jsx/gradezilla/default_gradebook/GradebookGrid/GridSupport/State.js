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

import GridHelper from './GridHelper';

function getItemMetadata (data, rowIndex) {
  const classes = [];

  if (rowIndex === 0) {
    classes.push('first-row');
  }

  if (rowIndex === data.length - 1) {
    classes.push('last-row');
  }

  if (data[rowIndex].cssClass) {
    classes.push(data[rowIndex].cssClass);
  }

  return {
    cssClasses: classes.join(' ')
  };
}

export default class State {
  activeLocation = { region: 'unknown' };

  constructor (grid, gridSupport) {
    this.grid = grid;
    this.gridSupport = gridSupport;
    this.helper = new GridHelper(grid);
  }

  initialize () {
    this.grid.onActiveCellChanged.subscribe((_event, activeCell) => {
      if (activeCell && activeCell.row != null) {
        this.setActiveLocationInternal('body', { row: activeCell.row, cell: activeCell.cell });
        this.triggerActiveLocationChange();
      }
    });

    const data = this.grid.getData();
    data.getItemMetadata = rowIndex => getItemMetadata(data, rowIndex);
  }

  getActiveLocation () {
    return this.activeLocation;
  }

  setActiveLocation (region, attr = {}) {
    this.helper.commitCurrentEdit();
    this.setActiveLocationInternal(region, attr);

    if (region === 'body') {
      this.grid.gotoCell(attr.row, attr.cell, true);
      this.triggerActiveLocationChange();
      return;
    }

    if (this.grid.getActiveCell()) {
      this.grid.resetActiveCell();
    }

    if (region === 'header' || region === 'beforeGrid') {
      this.helper.getBeforeGridNode().focus();
    } else if (region === 'afterGrid') {
      this.helper.getAfterGridNode().focus();
    }

    this.triggerActiveLocationChange();
  }

  resetActiveLocation () {
    this.setActiveLocation('beforeGrid');
  }

  setActiveLocationInternal (region, attr = {}) {
    this.activeLocation = { region, ...attr };

    if (attr.cell != null) {
      this.activeLocation.columnId = this.grid.getColumns()[attr.cell].id;
    }
  }

  blur () {
    // deactivate, then clear all activity state
    this.grid.getEditorLock().commitCurrentEdit();
    this.grid.resetActiveCell();
    this.setActiveLocationInternal('unknown');
    this.triggerActiveLocationChange();
  }

  getActiveNode () {
    if (this.activeLocation.region === 'header') {
      return this.getActiveColumnHeaderNode();
    }

    if (this.activeLocation.region === 'body') {
      return this.grid.getActiveCellNode();
    }

    return null;
  }

  getEditingNode () {
    if (this.grid.getEditorLock().isActive()) {
      return this.getActiveNode();
    }

    return null;
  }

  getColumnHeaderNode (cell) {
    const $gridContainer = this.grid.getContainerNode();
    const $headers = $gridContainer.querySelectorAll('.slick-header-column');

    return $headers[cell];
  }

  getActiveColumnHeaderNode () {
    if (this.activeLocation.cell != null) {
      return this.getColumnHeaderNode(this.activeLocation.cell);
    }

    return null;
  }

  triggerActiveLocationChange () {
    this.gridSupport.events.onActiveLocationChanged.trigger(null, this.activeLocation);
  }
}
