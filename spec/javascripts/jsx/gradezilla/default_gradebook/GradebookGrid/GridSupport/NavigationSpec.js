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

import 'jquery.keycodes'; // used by some SlickGrid editors
import { Grid, Editors } from 'vendor/slickgrid';
import GridSupport from 'jsx/gradezilla/default_gradebook/GradebookGrid/GridSupport';

const keyMap = {
  Tab: { which: 9, shiftKey: false },
  ShiftTab: { which: 9, shiftKey: true },
  LeftArrow: { which: 37 },
  RightArrow: { which: 39 },
  UpArrow: { which: 38 },
  DownArrow: { which: 40 }
};

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
    autoHeight: true, // adjusts grid to fit rendered data
    editable: true,
    editorFactory: {
      getEditor () { return Editors.Checkbox }
    },
    enableCellNavigation: true,
    enableColumnReorder: false,
    numberOfColumnsToFreeze: 2 // for possible edge cases with multiple grid viewports
  };
  return new Grid('#example-grid', createRows(), createColumns(), options);
}

function simulateKeyDown ($element, keyCode, shiftKey = false) {
  const event = new Event('keydown', { bubbles: true, cancelable: true });
  event.keyCode = keyCode;
  event.shiftKey = shiftKey;
  event.which = keyCode;
  $element.dispatchEvent(event);
  return event;
}

QUnit.module('GridSupport Navigation', function (hooks) {
  let $fixtures;
  let $activeElement;

  hooks.beforeEach(function () {
    // avoid spec pollution by listeners on #fixtures
    $fixtures = document.createElement('div');
    document.body.appendChild($fixtures);
    const $gridContainer = document.createElement('div');
    $gridContainer.id = 'example-grid';
    $fixtures.appendChild($gridContainer);
    this.grid = createGrid();
    this.gridSupport = new GridSupport(this.grid);
    this.gridSupport.initialize();
    this.onKeyDown = this.onKeyDown.bind(this);
    document.body.addEventListener('keydown', this.onKeyDown, false);
  });

  this.simulateKeyDown = function (key, $element = $activeElement) {
    const { which, shiftKey } = keyMap[key];
    this.triggeredEvent = simulateKeyDown($element, which, shiftKey);
  };

  this.onKeyDown = function (event) {
    this.bubbledEvent = event;
    // Store the value of .defaultPrevented before lingering handlers from other
    // specs have an opportunity to change it prior to assertions.
    this.defaultPrevented = event.defaultPrevented;
  };

  hooks.afterEach(function () {
    document.body.removeEventListener('keydown', this.onKeyDown, false);
    this.gridSupport.destroy();
    this.grid.destroy();
    $fixtures.remove();
  });

  QUnit.module('Tab into the header', {
    setup () {
      this.gridSupport.state.setActiveLocation('beforeGrid');
      $activeElement = this.gridSupport.helper.getBeforeGridNode();
    }
  });

  test('activates the first header cell', function () {
    this.simulateKeyDown('Tab');
    const activeLocation = this.gridSupport.state.getActiveLocation();
    equal(activeLocation.region, 'header');
    strictEqual(activeLocation.cell, 0);
  });

  test('triggers onNavigateNext', function () {
    const handler = this.spy();
    this.gridSupport.events.onNavigateNext.subscribe(handler);
    this.simulateKeyDown('Tab');
    strictEqual(handler.callCount, 1);
  });

  test('includes the event when triggering onNavigateNext', function () {
    let triggeredEvent;
    this.gridSupport.events.onNavigateNext.subscribe((event, _activeLocation) => { triggeredEvent = event });
    this.simulateKeyDown('Tab');
    equal(triggeredEvent, this.triggeredEvent);
  });

  test('includes the active location when triggering onNavigateNext', function () {
    let location;
    this.gridSupport.events.onNavigateNext.subscribe((_event, activeLocation) => { location = activeLocation });
    this.simulateKeyDown('Tab');
    equal(location.region, 'header');
    equal(location.cell, 0);
    equal(typeof location.row, 'undefined');
  });

  test('prevents SlickGrid default behavior', function () {
    this.simulateKeyDown('Tab');
    strictEqual(this.triggeredEvent.skipSlickGridDefaults, true);
  });

  test('does not stop propagation of the event', function () {
    this.simulateKeyDown('Tab');
    equal(this.bubbledEvent, this.triggeredEvent);
  });

  test('prevents the default behavior of the event', function () {
    this.simulateKeyDown('Tab');
    strictEqual(this.defaultPrevented, true);
  });

  QUnit.module('other keys on the beforeGrid region', {
    setup () {
      this.gridSupport.state.setActiveLocation('beforeGrid');
      $activeElement = this.gridSupport.helper.getBeforeGridNode();
    }
  });

  test('does not change the active location', function () {
    this.simulateKeyDown('RightArrow');
    const activeLocation = this.gridSupport.state.getActiveLocation();
    equal(activeLocation.region, 'beforeGrid');
    equal(typeof activeLocation.cell, 'undefined');
    equal(typeof activeLocation.row, 'undefined');
  });

  test('prevents SlickGrid default behavior', function () {
    this.simulateKeyDown('RightArrow');
    strictEqual(this.triggeredEvent.skipSlickGridDefaults, true);
  });

  test('does not stop propagation of the event', function () {
    this.simulateKeyDown('RightArrow');
    equal(this.bubbledEvent, this.triggeredEvent);
  });

  test('does not prevent the default behavior of the event', function () {
    this.simulateKeyDown('RightArrow');
    strictEqual(this.defaultPrevented, false);
  });

  QUnit.module('Tab between two header cells', {
    setup () {
      this.gridSupport.state.setActiveLocation('header', { cell: 0 });
      $activeElement = this.gridSupport.helper.getBeforeGridNode();
    }
  });

  test('activates the next header cell', function () {
    this.simulateKeyDown('Tab');
    const activeLocation = this.gridSupport.state.getActiveLocation();
    equal(activeLocation.region, 'header');
    strictEqual(activeLocation.cell, 1);
  });

  test('triggers onNavigateNext', function () {
    const handler = this.spy();
    this.gridSupport.events.onNavigateNext.subscribe(handler);
    this.simulateKeyDown('Tab');
    strictEqual(handler.callCount, 1);
  });

  test('includes the event when triggering onNavigateNext', function () {
    let triggeredEvent;
    this.gridSupport.events.onNavigateNext.subscribe((event, _activeLocation) => { triggeredEvent = event });
    this.simulateKeyDown('Tab');
    equal(triggeredEvent, this.triggeredEvent);
  });

  test('includes the active location when triggering onNavigateNext', function () {
    let location;
    this.gridSupport.events.onNavigateNext.subscribe((_event, activeLocation) => { location = activeLocation });
    this.simulateKeyDown('Tab');
    equal(location.region, 'header');
    equal(location.cell, 1);
    equal(typeof location.row, 'undefined');
  });

  test('prevents SlickGrid default behavior', function () {
    this.simulateKeyDown('Tab');
    strictEqual(this.triggeredEvent.skipSlickGridDefaults, true);
  });

  test('does not stop propagation of the event', function () {
    this.simulateKeyDown('Tab');
    equal(this.bubbledEvent, this.triggeredEvent);
  });

  test('prevents the default behavior of the event', function () {
    this.simulateKeyDown('Tab');
    strictEqual(this.defaultPrevented, true);
  });

  test('activates the next header cell when handling keydown on a header child element', function () {
    this.simulateKeyDown('Tab', document.querySelectorAll('.slick-column-name')[2]);
    const activeLocation = this.gridSupport.state.getActiveLocation();
    equal(activeLocation.region, 'header');
    strictEqual(activeLocation.cell, 3);
  });

  QUnit.module('Tab from frozen header cell to scrollable header cell', {
    setup () {
      this.gridSupport.state.setActiveLocation('header', { cell: 1 });
      $activeElement = this.gridSupport.helper.getBeforeGridNode();
    }
  });

  test('activates the next header cell', function () {
    this.simulateKeyDown('Tab');
    const activeLocation = this.gridSupport.state.getActiveLocation();
    equal(activeLocation.region, 'header');
    strictEqual(activeLocation.cell, 2);
  });

  test('triggers onNavigateNext', function () {
    const handler = this.spy();
    this.gridSupport.events.onNavigateNext.subscribe(handler);
    this.simulateKeyDown('Tab');
    strictEqual(handler.callCount, 1);
  });

  test('includes the event when triggering onNavigateNext', function () {
    let triggeredEvent;
    this.gridSupport.events.onNavigateNext.subscribe((event, _activeLocation) => { triggeredEvent = event });
    this.simulateKeyDown('Tab');
    equal(triggeredEvent, this.triggeredEvent);
  });

  test('includes the active location when triggering onNavigateNext', function () {
    let location;
    this.gridSupport.events.onNavigateNext.subscribe((_event, activeLocation) => { location = activeLocation });
    this.simulateKeyDown('Tab');
    equal(location.region, 'header');
    equal(location.cell, 2);
    equal(typeof location.row, 'undefined');
  });

  test('prevents SlickGrid default behavior', function () {
    this.simulateKeyDown('Tab');
    strictEqual(this.triggeredEvent.skipSlickGridDefaults, true);
  });

  test('does not stop propagation of the event', function () {
    this.simulateKeyDown('Tab');
    equal(this.bubbledEvent, this.triggeredEvent);
  });

  test('prevents the default behavior of the event', function () {
    this.simulateKeyDown('Tab');
    strictEqual(this.defaultPrevented, true);
  });

  QUnit.module('Tab from last header cell to first body cell', {
    setup () {
      this.gridSupport.state.setActiveLocation('header', { cell: 3 });
      $activeElement = this.gridSupport.helper.getBeforeGridNode();
    }
  });

  test('activates the first cell of the first body row', function () {
    this.simulateKeyDown('Tab');
    const activeLocation = this.gridSupport.state.getActiveLocation();
    equal(activeLocation.region, 'body');
    strictEqual(activeLocation.cell, 0);
    strictEqual(activeLocation.row, 0);
  });

  test('triggers onNavigateNext', function () {
    const handler = this.spy();
    this.gridSupport.events.onNavigateNext.subscribe(handler);
    this.simulateKeyDown('Tab');
    strictEqual(handler.callCount, 1);
  });

  test('includes the event when triggering onNavigateNext', function () {
    let triggeredEvent;
    this.gridSupport.events.onNavigateNext.subscribe((event, _activeLocation) => { triggeredEvent = event });
    this.simulateKeyDown('Tab');
    equal(triggeredEvent, this.triggeredEvent);
  });

  test('includes the active location when triggering onNavigateNext', function () {
    let location;
    this.gridSupport.events.onNavigateNext.subscribe((_event, activeLocation) => { location = activeLocation });
    this.simulateKeyDown('Tab');
    equal(location.region, 'body');
    equal(location.cell, 0);
    equal(location.row, 0);
  });

  test('activates the first cell within the grid', function () {
    this.simulateKeyDown('Tab');
    const activeCell = this.grid.getActiveCell();
    deepEqual(activeCell, { row: 0, cell: 0 });
  });

  test('creates an editor for the cell', function () {
    this.simulateKeyDown('Tab');
    ok(this.grid.getCellEditor(), 'an editor exists for the active cell');
  });

  test('prevents SlickGrid default behavior', function () {
    this.simulateKeyDown('Tab');
    strictEqual(this.triggeredEvent.skipSlickGridDefaults, true);
  });

  test('does not stop propagation of the event', function () {
    this.simulateKeyDown('Tab');
    equal(this.bubbledEvent, this.triggeredEvent);
  });

  test('prevents the default behavior of the event', function () {
    this.simulateKeyDown('Tab');
    strictEqual(this.defaultPrevented, true);
  });

  QUnit.module('Tab between two body cells', {
    setup () {
      this.gridSupport.state.setActiveLocation('body', { row: 0, cell: 0 });
      $activeElement = this.gridSupport.state.getActiveNode();
    }
  });

  test('activates the next cell of the body row', function () {
    this.simulateKeyDown('Tab');
    const activeLocation = this.gridSupport.state.getActiveLocation();
    equal(activeLocation.region, 'body');
    strictEqual(activeLocation.cell, 1);
    strictEqual(activeLocation.row, 0);
  });

  test('activates the cell within the grid', function () {
    this.simulateKeyDown('Tab');
    const activeCell = this.grid.getActiveCell();
    deepEqual(activeCell, { row: 0, cell: 1 });
  });

  test('creates an editor for the cell', function () {
    this.simulateKeyDown('Tab');
    ok(this.grid.getCellEditor(), 'an editor exists for the active cell');
  });

  test('does not prevent SlickGrid default behavior', function () {
    this.simulateKeyDown('Tab');
    equal(typeof this.triggeredEvent.skipSlickGridDefaults, 'undefined');
  });

  test('stops propagation of the event', function () {
    this.simulateKeyDown('Tab');
    equal(typeof this.bubbledEvent, 'undefined');
  });

  QUnit.module('Tab from frozen body cell to scrollable body cell', {
    setup () {
      this.gridSupport.state.setActiveLocation('body', { row: 0, cell: 1 });
      $activeElement = this.gridSupport.state.getActiveNode();
    }
  });

  test('activates the next cell of the body row', function () {
    this.simulateKeyDown('Tab');
    const activeLocation = this.gridSupport.state.getActiveLocation();
    equal(activeLocation.region, 'body');
    strictEqual(activeLocation.cell, 2);
    strictEqual(activeLocation.row, 0);
  });

  test('activates the cell within the grid', function () {
    this.simulateKeyDown('Tab');
    const activeCell = this.grid.getActiveCell();
    deepEqual(activeCell, { row: 0, cell: 2 });
  });

  test('creates an editor for the cell', function () {
    this.simulateKeyDown('Tab');
    ok(this.grid.getCellEditor(), 'an editor exists for the active cell');
  });

  test('does not prevent SlickGrid default behavior', function () {
    this.simulateKeyDown('Tab');
    equal(typeof this.triggeredEvent.skipSlickGridDefaults, 'undefined');
  });

  test('stops propagation of the event', function () {
    this.simulateKeyDown('Tab');
    equal(typeof this.bubbledEvent, 'undefined');
  });

  QUnit.module('Tab from last row cell to first cell of next row', {
    setup () {
      this.gridSupport.state.setActiveLocation('body', { row: 0, cell: 3 });
      $activeElement = this.gridSupport.state.getActiveNode();
    }
  });

  test('activates the first cell of the next body row', function () {
    this.simulateKeyDown('Tab');
    const activeLocation = this.gridSupport.state.getActiveLocation();
    equal(activeLocation.region, 'body');
    strictEqual(activeLocation.cell, 0);
    strictEqual(activeLocation.row, 1);
  });

  test('activates the cell within the grid', function () {
    this.simulateKeyDown('Tab');
    const activeCell = this.grid.getActiveCell();
    deepEqual(activeCell, { row: 1, cell: 0 });
  });

  test('creates an editor for the cell', function () {
    this.simulateKeyDown('Tab');
    ok(this.grid.getCellEditor(), 'an editor exists for the active cell');
  });

  test('does not prevent SlickGrid default behavior', function () {
    this.simulateKeyDown('Tab');
    equal(typeof this.triggeredEvent.skipSlickGridDefaults, 'undefined');
  });

  test('stops propagation of the event', function () {
    this.simulateKeyDown('Tab');
    equal(typeof this.bubbledEvent, 'undefined');
  });

  QUnit.module('Tab into the afterGrid region', {
    setup () {
      this.gridSupport.state.setActiveLocation('body', { row: 1, cell: 3 });
      $activeElement = this.gridSupport.state.getActiveNode();
    }
  });

  test('sets the active location to the afterGrid region', function () {
    this.simulateKeyDown('Tab');
    const activeLocation = this.gridSupport.state.getActiveLocation();
    equal(activeLocation.region, 'afterGrid');
    equal(typeof activeLocation.cell, 'undefined');
    equal(typeof activeLocation.row, 'undefined');
  });

  test('prevents SlickGrid default behavior', function () {
    this.simulateKeyDown('Tab');
    strictEqual(this.triggeredEvent.skipSlickGridDefaults, true);
  });

  test('does not stop propagation of the event', function () {
    this.simulateKeyDown('Tab');
    equal(this.bubbledEvent, this.triggeredEvent);
  });

  test('does not prevent the default behavior of the event', function () {
    this.simulateKeyDown('Tab');
    strictEqual(this.defaultPrevented, false);
  });

  QUnit.module('Tab out of the afterGrid region', {
    setup () {
      this.gridSupport.state.setActiveLocation('afterGrid');
      $activeElement = this.gridSupport.helper.getAfterGridNode();
    }
  });

  test('sets the active location to "unknown"', function () {
    this.simulateKeyDown('Tab');
    const activeLocation = this.gridSupport.state.getActiveLocation();
    equal(activeLocation.region, 'unknown');
    equal(typeof activeLocation.cell, 'undefined');
    equal(typeof activeLocation.row, 'undefined');
  });

  test('triggers onNavigateNext', function () {
    const handler = this.spy();
    this.gridSupport.events.onNavigateNext.subscribe(handler);
    this.simulateKeyDown('Tab');
    strictEqual(handler.callCount, 1);
  });

  test('includes the event when triggering onNavigateNext', function () {
    let triggeredEvent;
    this.gridSupport.events.onNavigateNext.subscribe((event, _activeLocation) => { triggeredEvent = event });
    this.simulateKeyDown('Tab');
    equal(triggeredEvent, this.triggeredEvent);
  });

  test('includes the active location when triggering onNavigateNext', function () {
    let location;
    this.gridSupport.events.onNavigateNext.subscribe((_event, activeLocation) => { location = activeLocation });
    this.simulateKeyDown('Tab');
    equal(location.region, 'unknown');
    equal(typeof location.cell, 'undefined');
    equal(typeof location.row, 'undefined');
  });

  test('prevents SlickGrid default behavior', function () {
    this.simulateKeyDown('Tab');
    strictEqual(this.triggeredEvent.skipSlickGridDefaults, true);
  });

  test('does not stop propagation of the event', function () {
    this.simulateKeyDown('Tab');
    equal(this.bubbledEvent, this.triggeredEvent);
  });

  test('does not prevent the default behavior of the event', function () {
    this.simulateKeyDown('Tab');
    strictEqual(this.defaultPrevented, false);
  });

  QUnit.module('other keys on the afterGrid region', {
    setup () {
      this.gridSupport.state.setActiveLocation('afterGrid');
      $activeElement = this.gridSupport.helper.getAfterGridNode();
    }
  });

  test('does not change the active location', function () {
    this.simulateKeyDown('LeftArrow');
    const activeLocation = this.gridSupport.state.getActiveLocation();
    equal(activeLocation.region, 'afterGrid');
    equal(typeof activeLocation.cell, 'undefined');
    equal(typeof activeLocation.row, 'undefined');
  });

  test('prevents SlickGrid default behavior', function () {
    this.simulateKeyDown('LeftArrow');
    strictEqual(this.triggeredEvent.skipSlickGridDefaults, true);
  });

  test('does not stop propagation of the event', function () {
    this.simulateKeyDown('LeftArrow');
    equal(this.bubbledEvent, this.triggeredEvent);
  });

  test('does not prevent the default behavior of the event', function () {
    this.simulateKeyDown('LeftArrow');
    strictEqual(this.defaultPrevented, false);
  });

  QUnit.module('Shift+Tab back out of the beforeGrid region', {
    setup () {
      this.gridSupport.state.setActiveLocation('beforeGrid');
      $activeElement = this.gridSupport.helper.getBeforeGridNode();
    }
  });

  test('prevents SlickGrid default behavior', function () {
    this.simulateKeyDown('ShiftTab');
    strictEqual(this.triggeredEvent.skipSlickGridDefaults, true);
  });

  test('does not stop propagation of the event', function () {
    this.simulateKeyDown('ShiftTab');
    equal(this.bubbledEvent, this.triggeredEvent);
  });

  test('does not prevent the default behavior of the event', function () {
    this.simulateKeyDown('ShiftTab');
    strictEqual(this.defaultPrevented, false);
  });

  QUnit.module('Shift+Tab back out of the header', {
    setup () {
      this.gridSupport.state.setActiveLocation('header', { cell: 0 });
      $activeElement = this.gridSupport.helper.getBeforeGridNode();
    }
  });

  test('sets the active location to the beforeGrid region', function () {
    this.simulateKeyDown('ShiftTab');
    const activeLocation = this.gridSupport.state.getActiveLocation();
    equal(activeLocation.region, 'beforeGrid');
    equal(typeof activeLocation.cell, 'undefined');
    equal(typeof activeLocation.row, 'undefined');
  });

  test('triggers onNavigatePrev', function () {
    const handler = this.spy();
    this.gridSupport.events.onNavigatePrev.subscribe(handler);
    this.simulateKeyDown('ShiftTab');
    strictEqual(handler.callCount, 1);
  });

  test('includes the event when triggering onNavigatePrev', function () {
    let triggeredEvent;
    this.gridSupport.events.onNavigatePrev.subscribe((event, _activeLocation) => { triggeredEvent = event });
    this.simulateKeyDown('ShiftTab');
    equal(triggeredEvent, this.triggeredEvent);
  });

  test('includes the active location when triggering onNavigatePrev', function () {
    let location;
    this.gridSupport.events.onNavigatePrev.subscribe((_event, activeLocation) => { location = activeLocation });
    this.simulateKeyDown('ShiftTab');
    equal(location.region, 'beforeGrid');
    equal(typeof location.row, 'undefined');
    equal(typeof location.cell, 'undefined');
  });

  test('prevents SlickGrid default behavior', function () {
    this.simulateKeyDown('ShiftTab');
    strictEqual(this.triggeredEvent.skipSlickGridDefaults, true);
  });

  test('does not stop propagation of the event', function () {
    this.simulateKeyDown('ShiftTab');
    equal(this.bubbledEvent, this.triggeredEvent);
  });

  test('does not prevent the default behavior of the event', function () {
    this.simulateKeyDown('ShiftTab');
    strictEqual(this.defaultPrevented, false);
  });

  QUnit.module('Shift+Tab between two header cells', {
    setup () {
      this.gridSupport.state.setActiveLocation('header', { cell: 1 });
      $activeElement = this.gridSupport.helper.getBeforeGridNode();
    }
  });

  test('activates the previous header cell', function () {
    this.simulateKeyDown('ShiftTab');
    const activeLocation = this.gridSupport.state.getActiveLocation();
    equal(activeLocation.region, 'header');
    strictEqual(activeLocation.cell, 0);
  });

  test('triggers onNavigatePrev', function () {
    const handler = this.spy();
    this.gridSupport.events.onNavigatePrev.subscribe(handler);
    this.simulateKeyDown('ShiftTab');
    strictEqual(handler.callCount, 1);
  });

  test('includes the event when triggering onNavigatePrev', function () {
    let triggeredEvent;
    this.gridSupport.events.onNavigatePrev.subscribe((event, _activeLocation) => { triggeredEvent = event });
    this.simulateKeyDown('ShiftTab');
    equal(triggeredEvent, this.triggeredEvent);
  });

  test('includes the active location when triggering onNavigatePrev', function () {
    let location;
    this.gridSupport.events.onNavigatePrev.subscribe((_event, activeLocation) => { location = activeLocation });
    this.simulateKeyDown('ShiftTab');
    equal(location.region, 'header');
    equal(location.cell, 0);
    equal(typeof location.row, 'undefined');
  });

  test('prevents SlickGrid default behavior', function () {
    this.simulateKeyDown('ShiftTab');
    strictEqual(this.triggeredEvent.skipSlickGridDefaults, true);
  });

  test('does not stop propagation of the event', function () {
    this.simulateKeyDown('ShiftTab');
    equal(this.bubbledEvent, this.triggeredEvent);
  });

  test('prevents the default behavior of the event', function () {
    this.simulateKeyDown('ShiftTab');
    strictEqual(this.defaultPrevented, true);
  });

  QUnit.module('Shift+Tab from scrollable header cell to frozen header cell', {
    setup () {
      this.gridSupport.state.setActiveLocation('header', { cell: 2 });
      $activeElement = this.gridSupport.helper.getBeforeGridNode();
    }
  });

  test('activates the previous header cell', function () {
    this.simulateKeyDown('ShiftTab');
    const activeLocation = this.gridSupport.state.getActiveLocation();
    equal(activeLocation.region, 'header');
    strictEqual(activeLocation.cell, 1);
  });

  test('triggers onNavigatePrev', function () {
    const handler = this.spy();
    this.gridSupport.events.onNavigatePrev.subscribe(handler);
    this.simulateKeyDown('ShiftTab');
    strictEqual(handler.callCount, 1);
  });

  test('includes the event when triggering onNavigatePrev', function () {
    let triggeredEvent;
    this.gridSupport.events.onNavigatePrev.subscribe((event, _activeLocation) => { triggeredEvent = event });
    this.simulateKeyDown('ShiftTab');
    equal(triggeredEvent, this.triggeredEvent);
  });

  test('includes the active location when triggering onNavigatePrev', function () {
    let location;
    this.gridSupport.events.onNavigatePrev.subscribe((_event, activeLocation) => { location = activeLocation });
    this.simulateKeyDown('ShiftTab');
    equal(location.region, 'header');
    equal(location.cell, 1);
    equal(typeof location.row, 'undefined');
  });

  test('prevents SlickGrid default behavior', function () {
    this.simulateKeyDown('ShiftTab');
    strictEqual(this.triggeredEvent.skipSlickGridDefaults, true);
  });

  test('does not stop propagation of the event', function () {
    this.simulateKeyDown('ShiftTab');
    equal(this.bubbledEvent, this.triggeredEvent);
  });

  test('prevents the default behavior of the event', function () {
    this.simulateKeyDown('ShiftTab');
    strictEqual(this.defaultPrevented, true);
  });

  QUnit.module('Shift+Tab from first body cell to last header cell', {
    setup () {
      this.gridSupport.state.setActiveLocation('body', { row: 0, cell: 0 });
      $activeElement = this.gridSupport.state.getActiveNode();
    }
  });

  test('activates the last header cell', function () {
    this.simulateKeyDown('ShiftTab');
    const activeLocation = this.gridSupport.state.getActiveLocation();
    equal(activeLocation.region, 'header');
    strictEqual(activeLocation.cell, 3);
    equal(typeof activeLocation.row, 'undefined');
  });

  test('triggers onNavigatePrev', function () {
    const handler = this.spy();
    this.gridSupport.events.onNavigatePrev.subscribe(handler);
    this.simulateKeyDown('ShiftTab');
    strictEqual(handler.callCount, 1);
  });

  test('includes the event when triggering onNavigatePrev', function () {
    let triggeredEvent;
    this.gridSupport.events.onNavigatePrev.subscribe((event, _activeLocation) => { triggeredEvent = event });
    this.simulateKeyDown('ShiftTab');
    equal(triggeredEvent, this.triggeredEvent);
  });

  test('includes the active location when triggering onNavigatePrev', function () {
    let location;
    this.gridSupport.events.onNavigatePrev.subscribe((_event, activeLocation) => { location = activeLocation });
    this.simulateKeyDown('ShiftTab');
    equal(location.region, 'header');
    strictEqual(location.cell, 3);
    equal(typeof location.row, 'undefined');
  });

  test('prevents SlickGrid default behavior', function () {
    this.simulateKeyDown('ShiftTab');
    strictEqual(this.triggeredEvent.skipSlickGridDefaults, true);
  });

  test('does not stop propagation of the event', function () {
    this.simulateKeyDown('ShiftTab');
    equal(this.bubbledEvent, this.triggeredEvent);
  });

  test('prevents the default behavior of the event', function () {
    this.simulateKeyDown('ShiftTab');
    strictEqual(this.defaultPrevented, true);
  });

  QUnit.module('Shift+Tab between two body cells', {
    setup () {
      this.gridSupport.state.setActiveLocation('body', { row: 0, cell: 1 });
      $activeElement = this.gridSupport.state.getActiveNode();
    }
  });

  test('activates the previous body cell', function () {
    this.simulateKeyDown('ShiftTab');
    const activeLocation = this.gridSupport.state.getActiveLocation();
    equal(activeLocation.region, 'body');
    strictEqual(activeLocation.cell, 0);
    strictEqual(activeLocation.row, 0);
  });

  test('activates the cell within the grid', function () {
    this.simulateKeyDown('ShiftTab');
    const activeCell = this.grid.getActiveCell();
    deepEqual(activeCell, { row: 0, cell: 0 });
  });

  test('creates an editor for the cell', function () {
    this.simulateKeyDown('ShiftTab');
    ok(this.grid.getCellEditor(), 'an editor exists for the active cell');
  });

  test('does not prevent SlickGrid default behavior', function () {
    this.simulateKeyDown('ShiftTab');
    equal(typeof this.triggeredEvent.skipSlickGridDefaults, 'undefined');
  });

  test('stops propagation of the event', function () {
    this.simulateKeyDown('ShiftTab');
    equal(typeof this.bubbledEvent, 'undefined');
  });

  QUnit.module('Shift+Tab from scrollable body cell to frozen body cell', {
    setup () {
      this.gridSupport.state.setActiveLocation('body', { row: 0, cell: 2 });
      $activeElement = this.gridSupport.state.getActiveNode();
    }
  });

  test('activates the next cell of the body row', function () {
    this.simulateKeyDown('ShiftTab');
    const activeLocation = this.gridSupport.state.getActiveLocation();
    equal(activeLocation.region, 'body');
    strictEqual(activeLocation.cell, 1);
    strictEqual(activeLocation.row, 0);
  });

  test('activates the cell within the grid', function () {
    this.simulateKeyDown('ShiftTab');
    const activeCell = this.grid.getActiveCell();
    deepEqual(activeCell, { row: 0, cell: 1 });
  });

  test('creates an editor for the cell', function () {
    this.simulateKeyDown('ShiftTab');
    ok(this.grid.getCellEditor(), 'an editor exists for the active cell');
  });

  test('does not prevent SlickGrid default behavior', function () {
    this.simulateKeyDown('ShiftTab');
    equal(typeof this.triggeredEvent.skipSlickGridDefaults, 'undefined');
  });

  test('stops propagation of the event', function () {
    this.simulateKeyDown('ShiftTab');
    equal(typeof this.bubbledEvent, 'undefined');
  });

  QUnit.module('Shift+Tab from first row cell to last cell of previous row', {
    setup () {
      this.gridSupport.state.setActiveLocation('body', { row: 1, cell: 0 });
      $activeElement = this.gridSupport.state.getActiveNode();
    }
  });

  test('activates the first cell of the next body row', function () {
    this.simulateKeyDown('ShiftTab');
    const activeLocation = this.gridSupport.state.getActiveLocation();
    equal(activeLocation.region, 'body');
    strictEqual(activeLocation.cell, 3);
    strictEqual(activeLocation.row, 0);
  });

  test('activates the cell within the grid', function () {
    this.simulateKeyDown('ShiftTab');
    const activeCell = this.grid.getActiveCell();
    deepEqual(activeCell, { row: 0, cell: 3 });
  });

  test('creates an editor for the cell', function () {
    this.simulateKeyDown('ShiftTab');
    ok(this.grid.getCellEditor(), 'an editor exists for the active cell');
  });

  test('does not prevent SlickGrid default behavior', function () {
    this.simulateKeyDown('ShiftTab');
    equal(typeof this.triggeredEvent.skipSlickGridDefaults, 'undefined');
  });

  test('stops propagation of the event', function () {
    this.simulateKeyDown('ShiftTab');
    equal(typeof this.bubbledEvent, 'undefined');
  });

  QUnit.module('Shift+Tab back into the body', {
    setup () {
      this.gridSupport.state.setActiveLocation('afterGrid');
      $activeElement = this.gridSupport.helper.getAfterGridNode();
    }
  });

  test('sets the active location to the last cell of the last row', function () {
    this.simulateKeyDown('ShiftTab');
    const activeLocation = this.gridSupport.state.getActiveLocation();
    equal(activeLocation.region, 'body');
    strictEqual(activeLocation.cell, 3);
    strictEqual(activeLocation.row, 1);
  });

  test('triggers onNavigatePrev', function () {
    const handler = this.spy();
    this.gridSupport.events.onNavigatePrev.subscribe(handler);
    this.simulateKeyDown('ShiftTab');
    strictEqual(handler.callCount, 1);
  });

  test('includes the event when triggering onNavigatePrev', function () {
    let triggeredEvent;
    this.gridSupport.events.onNavigatePrev.subscribe((event, _activeLocation) => { triggeredEvent = event });
    this.simulateKeyDown('ShiftTab');
    equal(triggeredEvent, this.triggeredEvent);
  });

  test('includes the active location when triggering onNavigatePrev', function () {
    let location;
    this.gridSupport.events.onNavigatePrev.subscribe((_event, activeLocation) => { location = activeLocation });
    this.simulateKeyDown('ShiftTab');
    equal(location.region, 'body');
    strictEqual(location.cell, 3);
    strictEqual(location.row, 1);
  });

  test('activates the cell within the grid', function () {
    this.simulateKeyDown('ShiftTab');
    const activeCell = this.grid.getActiveCell();
    deepEqual(activeCell, { row: 1, cell: 3 });
  });

  test('creates an editor for the cell', function () {
    this.simulateKeyDown('ShiftTab');
    ok(this.grid.getCellEditor(), 'an editor exists for the active cell');
  });

  test('prevents SlickGrid default behavior', function () {
    this.simulateKeyDown('ShiftTab');
    strictEqual(this.triggeredEvent.skipSlickGridDefaults, true);
  });

  test('does not stop propagation of the event', function () {
    this.simulateKeyDown('ShiftTab');
    equal(this.bubbledEvent, this.triggeredEvent);
  });

  test('prevents the default behavior of the event', function () {
    this.simulateKeyDown('ShiftTab');
    strictEqual(this.defaultPrevented, true);
  });

  QUnit.module('RightArrow between two header cells', {
    setup () {
      this.gridSupport.state.setActiveLocation('header', { cell: 0 });
      $activeElement = this.gridSupport.helper.getBeforeGridNode();
    }
  });

  test('activates the next header cell', function () {
    this.simulateKeyDown('RightArrow');
    const activeLocation = this.gridSupport.state.getActiveLocation();
    equal(activeLocation.region, 'header');
    strictEqual(activeLocation.cell, 1);
  });

  test('triggers onNavigateRight', function () {
    const handler = this.spy();
    this.gridSupport.events.onNavigateRight.subscribe(handler);
    this.simulateKeyDown('RightArrow');
    strictEqual(handler.callCount, 1);
  });

  test('includes the event when triggering onNavigateRight', function () {
    let triggeredEvent;
    this.gridSupport.events.onNavigateRight.subscribe((event, _activeLocation) => { triggeredEvent = event });
    this.simulateKeyDown('RightArrow');
    equal(triggeredEvent, this.triggeredEvent);
  });

  test('includes the active location when triggering onNavigateRight', function () {
    let location;
    this.gridSupport.events.onNavigateRight.subscribe((_event, activeLocation) => { location = activeLocation });
    this.simulateKeyDown('RightArrow');
    equal(location.region, 'header');
    equal(location.cell, 1);
    equal(typeof location.row, 'undefined');
  });

  test('prevents SlickGrid default behavior', function () {
    this.simulateKeyDown('RightArrow');
    strictEqual(this.triggeredEvent.skipSlickGridDefaults, true);
  });

  test('does not stop propagation of the event', function () {
    this.simulateKeyDown('RightArrow');
    equal(this.bubbledEvent, this.triggeredEvent);
  });

  test('prevents the default behavior of the event', function () {
    this.simulateKeyDown('RightArrow');
    strictEqual(this.defaultPrevented, true);
  });

  QUnit.module('RightArrow from frozen header cell to scrollable header cell', {
    setup () {
      this.gridSupport.state.setActiveLocation('header', { cell: 1 });
      $activeElement = this.gridSupport.helper.getBeforeGridNode();
    }
  });

  test('activates the next header cell', function () {
    this.simulateKeyDown('RightArrow');
    const activeLocation = this.gridSupport.state.getActiveLocation();
    equal(activeLocation.region, 'header');
    strictEqual(activeLocation.cell, 2);
  });

  test('triggers onNavigateRight', function () {
    const handler = this.spy();
    this.gridSupport.events.onNavigateRight.subscribe(handler);
    this.simulateKeyDown('RightArrow');
    strictEqual(handler.callCount, 1);
  });

  test('includes the event when triggering onNavigateRight', function () {
    let triggeredEvent;
    this.gridSupport.events.onNavigateRight.subscribe((event, _activeLocation) => { triggeredEvent = event });
    this.simulateKeyDown('RightArrow');
    equal(triggeredEvent, this.triggeredEvent);
  });

  test('includes the active location when triggering onNavigateRight', function () {
    let location;
    this.gridSupport.events.onNavigateRight.subscribe((_event, activeLocation) => { location = activeLocation });
    this.simulateKeyDown('RightArrow');
    equal(location.region, 'header');
    equal(location.cell, 2);
    equal(typeof location.row, 'undefined');
  });

  test('prevents SlickGrid default behavior', function () {
    this.simulateKeyDown('RightArrow');
    strictEqual(this.triggeredEvent.skipSlickGridDefaults, true);
  });

  test('does not stop propagation of the event', function () {
    this.simulateKeyDown('RightArrow');
    equal(this.bubbledEvent, this.triggeredEvent);
  });

  test('prevents the default behavior of the event', function () {
    this.simulateKeyDown('RightArrow');
    strictEqual(this.defaultPrevented, true);
  });

  QUnit.module('RightArrow on the last header cell', {
    setup () {
      this.gridSupport.state.setActiveLocation('header', { cell: 3 });
      $activeElement = this.gridSupport.helper.getBeforeGridNode();
    }
  });

  test('does not change the active location', function () {
    this.simulateKeyDown('RightArrow');
    const activeLocation = this.gridSupport.state.getActiveLocation();
    equal(activeLocation.region, 'header');
    strictEqual(activeLocation.cell, 3);
    equal(typeof activeLocation.row, 'undefined');
  });

  test('does not trigger onNavigateRight', function () {
    const handler = this.spy();
    this.gridSupport.events.onNavigateRight.subscribe(handler);
    this.simulateKeyDown('RightArrow');
    strictEqual(handler.callCount, 0);
  });

  test('prevents SlickGrid default behavior', function () {
    this.simulateKeyDown('RightArrow');
    strictEqual(this.triggeredEvent.skipSlickGridDefaults, true);
  });

  test('does not stop propagation of the event', function () {
    this.simulateKeyDown('RightArrow');
    equal(this.bubbledEvent, this.triggeredEvent);
  });

  test('does not prevent the default behavior of the event', function () {
    this.simulateKeyDown('RightArrow');
    strictEqual(this.defaultPrevented, false);
  });

  QUnit.module('RightArrow between two body cells', {
    setup () {
      this.gridSupport.state.setActiveLocation('body', { row: 0, cell: 0 });
      $activeElement = this.gridSupport.state.getActiveNode();
    }
  });

  test('activates the next cell of the body row', function () {
    this.simulateKeyDown('RightArrow');
    const activeLocation = this.gridSupport.state.getActiveLocation();
    equal(activeLocation.region, 'body');
    strictEqual(activeLocation.cell, 1);
    strictEqual(activeLocation.row, 0);
  });

  test('does not prevent SlickGrid default behavior', function () {
    this.simulateKeyDown('RightArrow');
    equal(typeof this.triggeredEvent.skipSlickGridDefaults, 'undefined');
  });

  test('stops propagation of the event', function () {
    this.simulateKeyDown('RightArrow');
    equal(typeof this.bubbledEvent, 'undefined');
  });

  QUnit.module('RightArrow on the last cell of a row', {
    setup () {
      this.gridSupport.state.setActiveLocation('body', { row: 0, cell: 3 });
      $activeElement = this.gridSupport.state.getActiveNode();
    }
  });

  test('does not change the active location', function () {
    this.simulateKeyDown('RightArrow');
    const activeLocation = this.gridSupport.state.getActiveLocation();
    equal(activeLocation.region, 'body');
    strictEqual(activeLocation.cell, 3);
    strictEqual(activeLocation.row, 0);
  });

  test('does not prevent SlickGrid default behavior', function () {
    this.simulateKeyDown('RightArrow');
    equal(typeof this.triggeredEvent.skipSlickGridDefaults, 'undefined');
  });

  test('does not stop propagation of the event', function () {
    this.simulateKeyDown('RightArrow');
    equal(this.bubbledEvent, this.triggeredEvent);
  });

  test('does not prevent the default behavior of the event', function () {
    this.simulateKeyDown('RightArrow');
    strictEqual(this.defaultPrevented, false);
  });

  QUnit.module('LeftArrow between two header cells', {
    setup () {
      this.gridSupport.state.setActiveLocation('header', { cell: 1 });
      $activeElement = this.gridSupport.helper.getBeforeGridNode();
    }
  });

  test('activates the next header cell', function () {
    this.simulateKeyDown('LeftArrow');
    const activeLocation = this.gridSupport.state.getActiveLocation();
    equal(activeLocation.region, 'header');
    strictEqual(activeLocation.cell, 0);
  });

  test('triggers onNavigateLeft', function () {
    const handler = this.spy();
    this.gridSupport.events.onNavigateLeft.subscribe(handler);
    this.simulateKeyDown('LeftArrow');
    strictEqual(handler.callCount, 1);
  });

  test('includes the event when triggering onNavigateLeft', function () {
    let triggeredEvent;
    this.gridSupport.events.onNavigateLeft.subscribe((event, _activeLocation) => { triggeredEvent = event });
    this.simulateKeyDown('LeftArrow');
    equal(triggeredEvent, this.triggeredEvent);
  });

  test('includes the active location when triggering onNavigateLeft', function () {
    let location;
    this.gridSupport.events.onNavigateLeft.subscribe((_event, activeLocation) => { location = activeLocation });
    this.simulateKeyDown('LeftArrow');
    equal(location.region, 'header');
    equal(location.cell, 0);
    equal(typeof location.row, 'undefined');
  });

  test('prevents SlickGrid default behavior', function () {
    this.simulateKeyDown('LeftArrow');
    strictEqual(this.triggeredEvent.skipSlickGridDefaults, true);
  });

  test('does not stop propagation of the event', function () {
    this.simulateKeyDown('LeftArrow');
    equal(this.bubbledEvent, this.triggeredEvent);
  });

  test('prevents the default behavior of the event', function () {
    this.simulateKeyDown('LeftArrow');
    strictEqual(this.defaultPrevented, true);
  });

  QUnit.module('LeftArrow from scrollable header cell to frozen header cell', {
    setup () {
      this.gridSupport.state.setActiveLocation('header', { cell: 2 });
      $activeElement = this.gridSupport.helper.getBeforeGridNode();
    }
  });

  test('activates the next header cell', function () {
    this.simulateKeyDown('LeftArrow');
    const activeLocation = this.gridSupport.state.getActiveLocation();
    equal(activeLocation.region, 'header');
    strictEqual(activeLocation.cell, 1);
  });

  test('triggers onNavigateLeft', function () {
    const handler = this.spy();
    this.gridSupport.events.onNavigateLeft.subscribe(handler);
    this.simulateKeyDown('LeftArrow');
    strictEqual(handler.callCount, 1);
  });

  test('includes the event when triggering onNavigateLeft', function () {
    let triggeredEvent;
    this.gridSupport.events.onNavigateLeft.subscribe((event, _activeLocation) => { triggeredEvent = event });
    this.simulateKeyDown('LeftArrow');
    equal(triggeredEvent, this.triggeredEvent);
  });

  test('includes the active location when triggering onNavigateLeft', function () {
    let location;
    this.gridSupport.events.onNavigateLeft.subscribe((_event, activeLocation) => { location = activeLocation });
    this.simulateKeyDown('LeftArrow');
    equal(location.region, 'header');
    equal(location.cell, 1);
    equal(typeof location.row, 'undefined');
  });

  test('prevents SlickGrid default behavior', function () {
    this.simulateKeyDown('LeftArrow');
    strictEqual(this.triggeredEvent.skipSlickGridDefaults, true);
  });

  test('does not stop propagation of the event', function () {
    this.simulateKeyDown('LeftArrow');
    equal(this.bubbledEvent, this.triggeredEvent);
  });

  test('prevents the default behavior of the event', function () {
    this.simulateKeyDown('LeftArrow');
    strictEqual(this.defaultPrevented, true);
  });

  QUnit.module('LeftArrow on the first header cell', {
    setup () {
      this.gridSupport.state.setActiveLocation('header', { cell: 0 });
      $activeElement = this.gridSupport.helper.getBeforeGridNode();
    }
  });

  test('does not change the active location', function () {
    this.simulateKeyDown('LeftArrow');
    const activeLocation = this.gridSupport.state.getActiveLocation();
    equal(activeLocation.region, 'header');
    strictEqual(activeLocation.cell, 0);
    equal(typeof activeLocation.row, 'undefined');
  });

  test('does not trigger onNavigateLeft', function () {
    const handler = this.spy();
    this.gridSupport.events.onNavigateLeft.subscribe(handler);
    this.simulateKeyDown('LeftArrow');
    strictEqual(handler.callCount, 0);
  });

  test('prevents SlickGrid default behavior', function () {
    this.simulateKeyDown('LeftArrow');
    strictEqual(this.triggeredEvent.skipSlickGridDefaults, true);
  });

  test('does not stop propagation of the event', function () {
    this.simulateKeyDown('LeftArrow');
    equal(this.bubbledEvent, this.triggeredEvent);
  });

  test('does not prevent the default behavior of the event', function () {
    this.simulateKeyDown('LeftArrow');
    strictEqual(this.defaultPrevented, false);
  });

  QUnit.module('LeftArrow between two body cells', {
    setup () {
      this.gridSupport.state.setActiveLocation('body', { row: 0, cell: 1 });
      $activeElement = this.gridSupport.state.getActiveNode();
    }
  });

  test('activates the previous cell of the body row', function () {
    this.simulateKeyDown('LeftArrow');
    const activeLocation = this.gridSupport.state.getActiveLocation();
    equal(activeLocation.region, 'body');
    strictEqual(activeLocation.cell, 0);
    strictEqual(activeLocation.row, 0);
  });

  test('does not prevent SlickGrid default behavior', function () {
    this.simulateKeyDown('LeftArrow');
    equal(typeof this.triggeredEvent.skipSlickGridDefaults, 'undefined');
  });

  test('stops propagation of the event', function () {
    this.simulateKeyDown('LeftArrow');
    equal(typeof this.bubbledEvent, 'undefined');
  });

  QUnit.module('LeftArrow on the first cell of a row', {
    setup () {
      this.gridSupport.state.setActiveLocation('body', { row: 0, cell: 0 });
      $activeElement = this.gridSupport.state.getActiveNode();
    }
  });

  test('does not change the active location', function () {
    this.simulateKeyDown('LeftArrow');
    const activeLocation = this.gridSupport.state.getActiveLocation();
    equal(activeLocation.region, 'body');
    strictEqual(activeLocation.cell, 0);
    strictEqual(activeLocation.row, 0);
  });

  test('prevents SlickGrid default behavior', function () {
    this.simulateKeyDown('LeftArrow');
    strictEqual(this.triggeredEvent.skipSlickGridDefaults, true);
  });

  test('does not stop propagation of the event', function () {
    this.simulateKeyDown('LeftArrow');
    equal(this.bubbledEvent, this.triggeredEvent);
  });

  test('does not prevent the default behavior of the event', function () {
    this.simulateKeyDown('LeftArrow');
    strictEqual(this.defaultPrevented, false);
  });

  // This addresses a bug in SlickGrid that sets the active cell to the next
  // column of the first row when navigating left on the first cell of the last
  // row.
  QUnit.module('LeftArrow on the first cell of the last row', {
    setup () {
      this.gridSupport.state.setActiveLocation('body', { row: 1, cell: 0 });
      $activeElement = this.gridSupport.state.getActiveNode();
    }
  });

  test('does not change the active location', function () {
    this.simulateKeyDown('LeftArrow');
    const activeLocation = this.gridSupport.state.getActiveLocation();
    equal(activeLocation.region, 'body');
    strictEqual(activeLocation.cell, 0);
    strictEqual(activeLocation.row, 1);
  });

  test('prevents SlickGrid default behavior', function () {
    this.simulateKeyDown('LeftArrow');
    strictEqual(this.triggeredEvent.skipSlickGridDefaults, true);
  });

  test('does not stop propagation of the event', function () {
    this.simulateKeyDown('LeftArrow');
    equal(this.bubbledEvent, this.triggeredEvent);
  });

  test('does not prevent the default behavior of the event', function () {
    this.simulateKeyDown('LeftArrow');
    strictEqual(this.defaultPrevented, false);
  });

  QUnit.module('UpArrow on a header cell', {
    setup () {
      this.gridSupport.state.setActiveLocation('header', { cell: 0 });
      $activeElement = this.gridSupport.helper.getBeforeGridNode();
    }
  });

  test('does not change the active location', function () {
    this.simulateKeyDown('UpArrow');
    const activeLocation = this.gridSupport.state.getActiveLocation();
    equal(activeLocation.region, 'header');
    strictEqual(activeLocation.cell, 0);
    equal(typeof activeLocation.row, 'undefined');
  });

  test('does not trigger onNavigateUp', function () {
    const handler = this.spy();
    this.gridSupport.events.onNavigateUp.subscribe(handler);
    this.simulateKeyDown('UpArrow');
    strictEqual(handler.callCount, 0);
  });

  test('prevents SlickGrid default behavior', function () {
    this.simulateKeyDown('UpArrow');
    strictEqual(this.triggeredEvent.skipSlickGridDefaults, true);
  });

  test('does not stop propagation of the event', function () {
    this.simulateKeyDown('UpArrow');
    equal(this.bubbledEvent, this.triggeredEvent);
  });

  test('does not prevent the default behavior of the event', function () {
    this.simulateKeyDown('UpArrow');
    strictEqual(this.defaultPrevented, false);
  });

  QUnit.module('UpArrow on a cell in the first row', {
    setup () {
      this.gridSupport.state.setActiveLocation('body', { row: 0, cell: 0 });
      $activeElement = this.gridSupport.state.getActiveNode();
    }
  });

  test('activates the related header cell', function () {
    this.simulateKeyDown('UpArrow');
    const activeLocation = this.gridSupport.state.getActiveLocation();
    equal(activeLocation.region, 'header');
    strictEqual(activeLocation.cell, 0);
    equal(typeof activeLocation.row, 'undefined');
  });

  test('triggers onNavigateUp', function () {
    const handler = this.spy();
    this.gridSupport.events.onNavigateUp.subscribe(handler);
    this.simulateKeyDown('UpArrow');
    strictEqual(handler.callCount, 1);
  });

  test('includes the event when triggering onNavigateUp', function () {
    let triggeredEvent;
    this.gridSupport.events.onNavigateUp.subscribe((event, _activeLocation) => { triggeredEvent = event });
    this.simulateKeyDown('UpArrow');
    equal(triggeredEvent, this.triggeredEvent);
  });

  test('includes the active location when triggering onNavigateUp', function () {
    let location;
    this.gridSupport.events.onNavigateUp.subscribe((_event, activeLocation) => { location = activeLocation });
    this.simulateKeyDown('UpArrow');
    equal(location.region, 'header');
    equal(location.cell, 0);
    equal(typeof location.row, 'undefined');
  });

  test('prevents SlickGrid default behavior', function () {
    this.simulateKeyDown('UpArrow');
    strictEqual(this.triggeredEvent.skipSlickGridDefaults, true);
  });

  test('does not stop propagation of the event', function () {
    this.simulateKeyDown('UpArrow');
    equal(this.bubbledEvent, this.triggeredEvent);
  });

  test('prevents the default behavior of the event', function () {
    this.simulateKeyDown('UpArrow');
    strictEqual(this.defaultPrevented, true);
  });

  QUnit.module('UpArrow on a cell in a row other than the first', {
    setup () {
      this.gridSupport.state.setActiveLocation('body', { row: 1, cell: 0 });
      $activeElement = this.gridSupport.state.getActiveNode();
    }
  });

  test('activates the adjacent cell of the previous row', function () {
    this.simulateKeyDown('UpArrow');
    const activeLocation = this.gridSupport.state.getActiveLocation();
    equal(activeLocation.region, 'body');
    strictEqual(activeLocation.cell, 0);
    strictEqual(activeLocation.row, 0);
  });

  test('does not prevent SlickGrid default behavior', function () {
    this.simulateKeyDown('UpArrow');
    equal(typeof this.triggeredEvent.skipSlickGridDefaults, 'undefined');
  });

  test('stops propagation of the event', function () {
    this.simulateKeyDown('UpArrow');
    equal(typeof this.bubbledEvent, 'undefined');
  });

  QUnit.module('DownArrow on a header cell', {
    setup () {
      this.gridSupport.state.setActiveLocation('header', { cell: 0 });
      $activeElement = this.gridSupport.helper.getBeforeGridNode();
    }
  });

  test('activates the related cell of the first row', function () {
    this.simulateKeyDown('DownArrow');
    const activeLocation = this.gridSupport.state.getActiveLocation();
    equal(activeLocation.region, 'body');
    strictEqual(activeLocation.cell, 0);
    strictEqual(activeLocation.row, 0);
  });

  test('triggers onNavigateDown', function () {
    const handler = this.spy();
    this.gridSupport.events.onNavigateDown.subscribe(handler);
    this.simulateKeyDown('DownArrow');
    strictEqual(handler.callCount, 1);
  });

  test('includes the event when triggering onNavigateDown', function () {
    let triggeredEvent;
    this.gridSupport.events.onNavigateDown.subscribe((event, _activeLocation) => { triggeredEvent = event });
    this.simulateKeyDown('DownArrow');
    equal(triggeredEvent, this.triggeredEvent);
  });

  test('includes the active location when triggering onNavigateDown', function () {
    let location;
    this.gridSupport.events.onNavigateDown.subscribe((_event, activeLocation) => { location = activeLocation });
    this.simulateKeyDown('DownArrow');
    equal(location.region, 'body');
    strictEqual(location.cell, 0);
    strictEqual(location.row, 0);
  });

  test('prevents SlickGrid default behavior', function () {
    this.simulateKeyDown('DownArrow');
    strictEqual(this.triggeredEvent.skipSlickGridDefaults, true);
  });

  test('does not stop propagation of the event', function () {
    this.simulateKeyDown('DownArrow');
    equal(this.bubbledEvent, this.triggeredEvent);
  });

  test('prevents the default behavior of the event', function () {
    this.simulateKeyDown('DownArrow');
    strictEqual(this.defaultPrevented, true);
  });

  QUnit.module('DownArrow on a body cell', {
    setup () {
      this.gridSupport.state.setActiveLocation('body', { row: 0, cell: 0 });
      $activeElement = this.gridSupport.state.getActiveNode();
    }
  });

  test('activates the adjacent cell of the next row', function () {
    this.simulateKeyDown('DownArrow');
    const activeLocation = this.gridSupport.state.getActiveLocation();
    equal(activeLocation.region, 'body');
    strictEqual(activeLocation.cell, 0);
    strictEqual(activeLocation.row, 1);
  });

  test('does not prevent SlickGrid default behavior', function () {
    this.simulateKeyDown('DownArrow');
    equal(typeof this.triggeredEvent.skipSlickGridDefaults, 'undefined');
  });

  test('stops propagation of the event', function () {
    this.simulateKeyDown('DownArrow');
    equal(typeof this.bubbledEvent, 'undefined');
  });

  QUnit.module('DownArrow on a cell in the last row', {
    setup () {
      this.gridSupport.state.setActiveLocation('body', { row: 1, cell: 0 });
      $activeElement = this.gridSupport.state.getActiveNode();
    }
  });

  test('activates the cell of the next column in the first row', function () {
    this.simulateKeyDown('DownArrow');
    const activeLocation = this.gridSupport.state.getActiveLocation();
    equal(activeLocation.region, 'body');
    strictEqual(activeLocation.cell, 1);
    strictEqual(activeLocation.row, 0);
  });

  test('does not prevent SlickGrid default behavior', function () {
    this.simulateKeyDown('DownArrow');
    equal(typeof this.triggeredEvent.skipSlickGridDefaults, 'undefined');
  });

  test('stops propagation of the event', function () {
    this.simulateKeyDown('DownArrow');
    equal(typeof this.bubbledEvent, 'undefined');
  });

  QUnit.module('with onKeyDown GridEvent subscribers', {
    setup () {
      this.gridSupport.state.setActiveLocation('header', { cell: 0 });
      this.gridSupport.events.onKeyDown.subscribe((event, location) => {
        this.handledEvent = event;
        this.handledLocation = location;
      });
      $activeElement = this.gridSupport.helper.getBeforeGridNode();
    }
  });

  test('calls each handler with the triggered event', function () {
    this.simulateKeyDown('Tab');
    equal(this.handledEvent, this.triggeredEvent);
  });

  test('calls each handler with the active location', function () {
    this.simulateKeyDown('Tab');
    equal(this.handledLocation.region, 'header');
    strictEqual(this.handledLocation.cell, 0);
    equal(typeof this.handledLocation.row, 'undefined');
  });

  test('triggers the event when handling keydown on a header child element', function () {
    const spy = this.spy();
    this.gridSupport.events.onKeyDown.subscribe(spy);
    this.simulateKeyDown('Tab', document.querySelectorAll('.slick-column-name')[2]);
    strictEqual(spy.callCount, 1);
  });

  test('skips Navigation behavior when a handler returns false', function () {
    this.gridSupport.events.onKeyDown.subscribe(() => false);
    this.simulateKeyDown('Tab');
    const activeLocation = this.gridSupport.state.getActiveLocation();
    strictEqual(activeLocation.cell, 0, 'active location did not change to second header cell');
  });

  test('prevents SlickGrid default behavior when a handler returns false', function () {
    this.gridSupport.events.onKeyDown.subscribe(() => false);
    this.simulateKeyDown('Tab');
    strictEqual(this.triggeredEvent.skipSlickGridDefaults, true);
  });

  test('includes the columnId in the active location when handling a header cell event', function () {
    this.simulateKeyDown('Tab');
    equal(this.handledLocation.columnId, 'column1');
  });

  test('includes the columnId in the active location when handling keydown on a header child element', function () {
    this.simulateKeyDown('Tab', document.querySelectorAll('.slick-column-name')[1]);
    equal(this.handledLocation.columnId, 'column2');
  });

  test('includes the columnId in the active location when handling a body cell event', function () {
    this.gridSupport.state.setActiveLocation('body', { row: 0, cell: 1 });
    this.simulateKeyDown('Tab', this.gridSupport.state.getActiveNode());
    equal(this.handledLocation.columnId, 'column2');
  });

  test('excludes a columnId from the active location when handling a "before grid" event', function () {
    this.gridSupport.state.setActiveLocation('beforeGrid');
    this.simulateKeyDown('Tab', this.gridSupport.helper.getBeforeGridNode());
    equal(typeof this.handledLocation.columnId, 'undefined');
  });

  test('excludes a columnId from the active location when handling an "after grid" event', function () {
    this.gridSupport.state.setActiveLocation('afterGrid');
    this.simulateKeyDown('Tab', this.gridSupport.helper.getAfterGridNode());
    equal(typeof this.handledLocation.columnId, 'undefined');
  });

  QUnit.module('Click on a header');

  test('activates the header location being clicked', function () {
    document.querySelectorAll('.slick-header-column')[1].click();
    const activeLocation = this.gridSupport.state.getActiveLocation();
    equal(activeLocation.region, 'header');
    strictEqual(activeLocation.cell, 1);
    equal(typeof activeLocation.row, 'undefined');
  });

  test('activates the header location when handling click on a header child element', function () {
    document.querySelectorAll('.slick-column-name')[1].click();
    const activeLocation = this.gridSupport.state.getActiveLocation();
    equal(activeLocation.region, 'header');
    strictEqual(activeLocation.cell, 1);
    equal(typeof activeLocation.row, 'undefined');
  });
});
