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
import {isRTL} from '../../../../shared/helpers/rtlHelper';


function isLeftArrow (event) {
  return event.which === 37;
}

function isRightArrow (event) {
  return event.which === 39;
}

// RTL aware methods that "flip" left and right so arrows do the right thing in RTL
const isNextArrow = (event) => (isRTL(event.target) ? isLeftArrow : isRightArrow)(event)
const isPrevArrow = (event) => (isRTL(event.target) ? isRightArrow : isLeftArrow)(event)

function isUpArrow (event) {
  return event.which === 38;
}

function isDownArrow (event) {
  return event.which === 40;
}

function isTab (event) {
  return event.which === 9 && !event.shiftKey;
}

function isShiftTab (event) {
  return event.which === 9 && event.shiftKey;
}

function skipSlickGridDefaults (event) {
  (event.originalEvent || event).skipSlickGridDefaults = true; // eslint-disable-line no-param-reassign
}

export default class Navigation {
  constructor (grid, gridSupport) {
    this.grid = grid;
    this.gridSupport = gridSupport;
    this.helper = new GridHelper(grid);
  }

  initialize () {
    this.grid.onKeyDown.subscribe(this.handleKeyDown);

    const $gridContainer = this.grid.getContainerNode();
    const $headers = $gridContainer.querySelectorAll('.slick-header');
    Array.prototype.forEach.call($headers, ($header) => {
      $header.addEventListener('click', this.handleClick, false);
      $header.addEventListener('keydown', this.handleKeyDown, false);
    });
  }

  handleClick = (event) => {
    const { region, ...location } = this.getEventLocation(event);
    this.gridSupport.state.setActiveLocation(region, location);
  };

  handleKeyDown = (sourceEvent, obj = {}) => {
    const event = sourceEvent.originalEvent || sourceEvent;
    const location = this.getEventLocation(event, obj);

    const continueHandling = this.gridSupport.events.onKeyDown.trigger(event, location);

    if (continueHandling === false) {
      // prevent SlickGrid behavior to prevent interference with handler behavior
      skipSlickGridDefaults(event);
    } else if (location.region === 'header') {
      this.handleHeaderKeyDown(event, location);
    } else if (location.region === 'body') {
      this.handleBodyKeyDown(event, location);
    } else if (location.region === 'beforeGrid') {
      this.handleBeforeGridKeyDown(event, location);
    } else if (location.region === 'afterGrid') {
      this.handleAfterGridKeyDown(event, location);
    }

    this.helper.syncScrollPositions();
  };

  handleHeaderKeyDown (event, location) {
    if (isTab(event)) {
      // Tab out of the grid: Activate the "after grid" region.
      this.gridSupport.state.setActiveLocation('afterGrid');
      this.trigger('onNavigateNext', event);

      // prevent SlickGrid behavior, but allow default browser behavior
    }

    if (isShiftTab(event)) {
      // Shift+Tab out of the grid: Activate the "before grid" region.
      this.gridSupport.state.setActiveLocation('beforeGrid');
      this.trigger('onNavigatePrev', event);

      // prevent SlickGrid behavior, but allow default browser behavior
    }

    if (isPrevArrow(event)) {
      if (location.cell !== 0) {
        // Left Arrow within the header: Activate the previous cell.
        this.gridSupport.state.setActiveLocation('header', { cell: location.cell - 1 });
        this.trigger('onNavigateLeft', event);

        // prevent both SlickGrid and default browser behavior
        event.preventDefault();
      }
    }

    if (isNextArrow(event)) {
      const columns = this.grid.getColumns();
      const lastCell = columns.length - 1;

      if (location.cell !== lastCell) {
        // Right Arrow within the header: Activate the next cell.
        this.gridSupport.state.setActiveLocation('header', { cell: location.cell + 1 });
        this.trigger('onNavigateRight', event);

        // prevent both SlickGrid and default browser behavior
        event.preventDefault();
      }
    }

    // Up Arrow in within the header: No change.
    // * prevent SlickGrid behavior, but allow default browser behavior

    if (isDownArrow(event)) {
      // Down Arrow within header: Activate the related cell of the first row.
      this.gridSupport.state.setActiveLocation('body', { row: 0, cell: location.cell });
      this.trigger('onNavigateDown', event);

      // prevent both SlickGrid and default browser behavior
      event.preventDefault();
    }

    // prevent SlickGrid behavior for all header cells
    skipSlickGridDefaults(event);
  }

  handleBodyKeyDown (event, location) {
    if (isShiftTab(event)) {
      // Shift+Tab out of the grid: Activate the "before grid" region.
      this.gridSupport.state.setActiveLocation('beforeGrid');
      this.trigger('onNavigatePrev', event);

      // prevent SlickGrid behavior, but allow default browser behavior
      skipSlickGridDefaults(event);
    }

    if (isTab(event)) {
      // Tab out of the grid: Activate the "after grid" region.
      this.gridSupport.state.setActiveLocation('afterGrid');

      // prevent SlickGrid behavior, but allow default browser behavior
      skipSlickGridDefaults(event);
    }

    if (isPrevArrow(event)) {
      if (location.cell === 0) {
        // Left Arrow in first cell of a row: Commit any edits
        // * this preserves focus for cells without an editor
        // * this also prevents a bug in SlickGrid when in the last row
        this.helper.commitCurrentEdit();

        // prevent SlickGrid behavior, but allow default browser behavior
        skipSlickGridDefaults(event);
      }

      // Left Arrow within the body: Activate the previous cell.
      // * this is handled by SlickGrid
    }

    if (isUpArrow(event)) {
      if (location.row === 0) {
        // Up Arrow in top row of body: Activate the related header cell.
        this.gridSupport.state.setActiveLocation('header', { cell: location.cell });
        this.trigger('onNavigateUp', event);

        // prevent both SlickGrid and default browser behavior
        event.preventDefault();
        skipSlickGridDefaults(event);
      }

      // Up Arrow within the body: Activate the adjacent cell of the previous row.
      // * this is handled by SlickGrid
    }

    // All other keys are either handled by SlickGrid or altogether ignored.
  }

  handleBeforeGridKeyDown (event, _location) {
    if (isTab(event)) {
      // Tab into the header: Activate the first cell.
      this.gridSupport.state.restorePreviousLocation();
      this.trigger('onNavigateNext', event);

      // prevent both SlickGrid and default browser behavior
      event.preventDefault();
    }

    // prevent SlickGrid behavior for all other keys
    skipSlickGridDefaults(event);
  }

  handleAfterGridKeyDown (event, _location) {
    if (isShiftTab(event)) {
      // Shift+Tab back into the body: Activate the first cell.
      this.gridSupport.state.restorePreviousLocation();
      this.trigger('onNavigatePrev', event);

      // prevent both SlickGrid and default browser behavior
      event.preventDefault();
    }

    if (isTab(event)) {
      // Tab away from the grid: No change.
      this.gridSupport.state.setActiveLocation('unknown');
      this.trigger('onNavigateNext', event);

      // prevent SlickGrid behavior, but allow default browser behavior
    }

    // prevent SlickGrid behavior for all other keys
    skipSlickGridDefaults(event);
  }

  trigger (handlerName, event) {
    const gridEvent = this.gridSupport.events[handlerName];
    if (gridEvent) {
      return gridEvent.trigger(event.originalEvent || event, this.gridSupport.state.getActiveLocation());
    }

    /* istanbul ignore next */
    return undefined;
  }

  getEventLocation (event, obj = {}) {
    const columns = this.grid.getColumns();

    if (typeof obj.row === 'number' && typeof obj.cell === 'number') {
      return { region: 'body', row: obj.row, cell: obj.cell, columnId: columns[obj.cell].id };
    }

    const index = columns.findIndex((column) => {
      const $headerNode = this.helper.getColumnHeaderNode(column.id);
      return $headerNode === event.target || $headerNode.contains(event.target);
    });

    if (index !== -1) {
      return { region: 'header', cell: index, columnId: columns[index].id };
    }

    const activeLocation = this.gridSupport.state.getActiveLocation();

    const $beforeGrid = this.helper.getBeforeGridNode();
    const $afterGrid = this.helper.getAfterGridNode();

    if (event.target === $beforeGrid || event.target === $afterGrid) {
      if (activeLocation.region === 'header' || activeLocation.region === 'body') {
        return activeLocation;
      }

      return { region: event.target === $beforeGrid ? 'beforeGrid' : 'afterGrid' };
    }

    /* istanbul ignore next */
    return { region: 'unknown' };
  }
}
