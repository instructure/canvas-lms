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

import GridHelper from 'jsx/gradezilla/default_gradebook/slick-grid/grid-support/GridHelper';

class State {
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
    this.removeClassesForActiveLocation();

    this.activeLocation = { region, ...attr };

    this.addClassesForActiveLocation();

    if (attr.cell != null) {
      this.activeLocation.columnId = this.grid.getColumns()[attr.cell].id;
    }
  }

  addClassesForActiveLocation () {
    if (this.activeLocation.region === 'header') {
      const $activeNode = this.getActiveColumnHeaderNode();
      $activeNode.classList.add('active-header');
    }
    if (this.activeLocation.region === 'body') {
      const $activeNode = this.getActiveColumnHeaderNode();
      $activeNode.classList.add('active-column-header');
    }
  }

  removeClassesForActiveLocation () {
    if (this.activeLocation.region === 'header') {
      const $activeNode = this.getActiveColumnHeaderNode();
      $activeNode.classList.remove('active-header');
    }
    if (this.activeLocation.region === 'body') {
      const $activeNode = this.getActiveColumnHeaderNode();
      $activeNode.classList.remove('active-column-header');
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

  getActiveColumnHeaderNode () {
    if (this.activeLocation.cell != null) {
      const $gridContainer = this.grid.getContainerNode();
      const $headers = $gridContainer.querySelectorAll('.slick-header-column');
      return $headers[this.activeLocation.cell];
    }

    return null;
  }

  triggerActiveLocationChange () {
    this.gridSupport.events.onActiveLocationChanged.trigger(null, this.activeLocation);
  }
}

export default State;
