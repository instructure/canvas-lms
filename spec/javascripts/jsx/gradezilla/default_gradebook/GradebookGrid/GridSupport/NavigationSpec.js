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

QUnit.module('GridSupport Navigation', (suiteHooks) => {
  let $fixtures;
  let $activeElement;

  let bubbledEvent;
  let defaultPrevented;
  let grid;
  let gridSupport;
  let triggeredEvent;

  function onKeyDown (event) {
    bubbledEvent = event;
    // Store the value of .defaultPrevented before lingering handlers from other
    // specs have an opportunity to change it prior to assertions.
    defaultPrevented = event.defaultPrevented;
  }

  function simulateKeyDown (key, $element = $activeElement) {
    const { which, shiftKey } = keyMap[key];
    const event = new Event('keydown', { bubbles: true, cancelable: true });
    event.keyCode = which;
    event.shiftKey = shiftKey;
    event.which = which;
    $element.dispatchEvent(event);
    triggeredEvent = event;
  }

  suiteHooks.beforeEach(() => {
    // avoid spec pollution by listeners on #fixtures
    $fixtures = document.createElement('div');
    document.body.appendChild($fixtures);
    const $gridContainer = document.createElement('div');
    $gridContainer.id = 'example-grid';
    $fixtures.appendChild($gridContainer);

    grid = createGrid();
    gridSupport = new GridSupport(grid);
    gridSupport.initialize();
    document.body.addEventListener('keydown', onKeyDown, false);

    bubbledEvent = undefined;
    triggeredEvent = undefined;
  });

  suiteHooks.afterEach(() => {
    document.body.removeEventListener('keydown', onKeyDown, false);
    gridSupport.destroy();
    grid.destroy();
    $fixtures.remove();
  });

  QUnit.module('Tab into the grid', (hooks) => {
    hooks.beforeEach(() => {
      gridSupport.state.setActiveLocation('beforeGrid');
      $activeElement = gridSupport.helper.getBeforeGridNode();
    });

    test('activates the first cell of the header', () => {
      simulateKeyDown('Tab');
      const activeLocation = gridSupport.state.getActiveLocation();
      equal(activeLocation.region, 'header');
      strictEqual(activeLocation.cell, 0);
      strictEqual(typeof activeLocation.row, 'undefined');
    });

    test('triggers onNavigateNext', () => {
      const handler = sinon.spy();
      gridSupport.events.onNavigateNext.subscribe(handler);
      simulateKeyDown('Tab');
      strictEqual(handler.callCount, 1);
    });

    test('includes the event when triggering onNavigateNext', () => {
      let capturedEvent;
      gridSupport.events.onNavigateNext.subscribe((event, _activeLocation) => { capturedEvent = event });
      simulateKeyDown('Tab');
      equal(capturedEvent, triggeredEvent);
    });

    test('includes the active location when triggering onNavigateNext', () => {
      let location;
      gridSupport.events.onNavigateNext.subscribe((_event, activeLocation) => { location = activeLocation });
      simulateKeyDown('Tab');
      equal(location.region, 'header');
      equal(location.cell, 0);
      equal(typeof location.row, 'undefined');
    });

    test('prevents SlickGrid default behavior', () => {
      simulateKeyDown('Tab');
      strictEqual(triggeredEvent.skipSlickGridDefaults, true);
    });

    test('does not stop propagation of the event', () => {
      simulateKeyDown('Tab');
      equal(bubbledEvent, triggeredEvent);
    });

    test('prevents the default behavior of the event', () => {
      simulateKeyDown('Tab');
      strictEqual(defaultPrevented, true);
    });
  });

  QUnit.module('other keys on the beforeGrid region', (hooks) => {
    hooks.beforeEach(() => {
      gridSupport.state.setActiveLocation('beforeGrid');
      $activeElement = gridSupport.helper.getBeforeGridNode();
    });

    test('does not change the active location', () => {
      simulateKeyDown('RightArrow');
      const activeLocation = gridSupport.state.getActiveLocation();
      equal(activeLocation.region, 'beforeGrid');
      equal(typeof activeLocation.cell, 'undefined');
      equal(typeof activeLocation.row, 'undefined');
    });

    test('prevents SlickGrid default behavior', () => {
      simulateKeyDown('RightArrow');
      strictEqual(triggeredEvent.skipSlickGridDefaults, true);
    });

    test('does not stop propagation of the event', () => {
      simulateKeyDown('RightArrow');
      equal(bubbledEvent, triggeredEvent);
    });

    test('does not prevent the default behavior of the event', () => {
      simulateKeyDown('RightArrow');
      strictEqual(defaultPrevented, false);
    });
  });

  QUnit.module('Tab on a header cell', (hooks) => {
    hooks.beforeEach(() => {
      gridSupport.state.setActiveLocation('header', { cell: 1 });
      $activeElement = gridSupport.helper.getBeforeGridNode();
    });

    test('sets the active location to the afterGrid region', () => {
      simulateKeyDown('Tab');
      const activeLocation = gridSupport.state.getActiveLocation();
      equal(activeLocation.region, 'afterGrid');
      equal(typeof activeLocation.cell, 'undefined');
      equal(typeof activeLocation.row, 'undefined');
    });

    test('triggers onNavigateNext', () => {
      const handler = sinon.spy();
      gridSupport.events.onNavigateNext.subscribe(handler);
      simulateKeyDown('Tab');
      strictEqual(handler.callCount, 1);
    });

    test('includes the event when triggering onNavigateNext', () => {
      let capturedEvent;
      gridSupport.events.onNavigateNext.subscribe((event, _activeLocation) => { capturedEvent = event });
      simulateKeyDown('Tab');
      equal(capturedEvent, triggeredEvent);
    });

    test('includes the active location when triggering onNavigateNext', () => {
      let location;
      gridSupport.events.onNavigateNext.subscribe((_event, activeLocation) => { location = activeLocation });
      simulateKeyDown('Tab');
      equal(location.region, 'afterGrid');
      equal(typeof location.cell, 'undefined');
      equal(typeof location.row, 'undefined');
    });

    test('prevents SlickGrid default behavior', () => {
      simulateKeyDown('Tab');
      strictEqual(triggeredEvent.skipSlickGridDefaults, true);
    });

    test('does not stop propagation of the event', () => {
      simulateKeyDown('Tab');
      equal(bubbledEvent, triggeredEvent);
    });

    test('prevents the default behavior of the event', () => {
      simulateKeyDown('Tab');
      strictEqual(defaultPrevented, false);
    });

    test('activates the afterGrid region when handling keydown on a header child element', () => {
      simulateKeyDown('Tab', document.querySelectorAll('.slick-column-name')[2]);
      const activeLocation = gridSupport.state.getActiveLocation();
      equal(activeLocation.region, 'afterGrid');
      equal(typeof activeLocation.cell, 'undefined');
      equal(typeof activeLocation.row, 'undefined');
    });

    test('activates the previously-active location when followed by Shift+Tab', () => {
      simulateKeyDown('Tab');
      $activeElement = gridSupport.helper.getAfterGridNode();
      simulateKeyDown('ShiftTab');

      const activeLocation = gridSupport.state.getActiveLocation();
      equal(activeLocation.region, 'header');
      strictEqual(activeLocation.cell, 1);
    });
  });

  QUnit.module('Tab on a body cell', (hooks) => {
    hooks.beforeEach(() => {
      gridSupport.state.setActiveLocation('body', { row: 0, cell: 1 });
      $activeElement = gridSupport.state.getActiveNode();
    });

    test('sets the active location to the afterGrid region', () => {
      simulateKeyDown('Tab');
      const activeLocation = gridSupport.state.getActiveLocation();
      equal(activeLocation.region, 'afterGrid');
      equal(typeof activeLocation.cell, 'undefined');
      equal(typeof activeLocation.row, 'undefined');
    });

    test('prevents SlickGrid default behavior', () => {
      simulateKeyDown('Tab');
      strictEqual(triggeredEvent.skipSlickGridDefaults, true);
    });

    test('does not stop propagation of the event', () => {
      simulateKeyDown('Tab');
      equal(bubbledEvent, triggeredEvent);
    });

    test('does not prevent the default behavior of the event', () => {
      simulateKeyDown('Tab');
      strictEqual(defaultPrevented, false);
    });

    test('activates the previously-active location when followed by Shift+Tab', () => {
      simulateKeyDown('Tab');
      $activeElement = gridSupport.helper.getAfterGridNode();
      simulateKeyDown('ShiftTab');

      const activeLocation = gridSupport.state.getActiveLocation();
      equal(activeLocation.region, 'body');
      strictEqual(activeLocation.row, 0);
      strictEqual(activeLocation.cell, 1);
    });
  });

  QUnit.module('Tab out of the afterGrid region', (hooks) => {
    hooks.beforeEach(() => {
      gridSupport.state.setActiveLocation('afterGrid');
      $activeElement = gridSupport.helper.getAfterGridNode();
    });

    test('sets the active location to "unknown"', () => {
      simulateKeyDown('Tab');
      const activeLocation = gridSupport.state.getActiveLocation();
      equal(activeLocation.region, 'unknown');
      equal(typeof activeLocation.cell, 'undefined');
      equal(typeof activeLocation.row, 'undefined');
    });

    test('triggers onNavigateNext', () => {
      const handler = sinon.spy();
      gridSupport.events.onNavigateNext.subscribe(handler);
      simulateKeyDown('Tab');
      strictEqual(handler.callCount, 1);
    });

    test('includes the event when triggering onNavigateNext', () => {
      let capturedEvent;
      gridSupport.events.onNavigateNext.subscribe((event, _activeLocation) => { capturedEvent = event });
      simulateKeyDown('Tab');
      equal(capturedEvent, triggeredEvent);
    });

    test('includes the active location when triggering onNavigateNext', () => {
      let location;
      gridSupport.events.onNavigateNext.subscribe((_event, activeLocation) => { location = activeLocation });
      simulateKeyDown('Tab');
      equal(location.region, 'unknown');
      equal(typeof location.cell, 'undefined');
      equal(typeof location.row, 'undefined');
    });

    test('prevents SlickGrid default behavior', () => {
      simulateKeyDown('Tab');
      strictEqual(triggeredEvent.skipSlickGridDefaults, true);
    });

    test('does not stop propagation of the event', () => {
      simulateKeyDown('Tab');
      equal(bubbledEvent, triggeredEvent);
    });

    test('does not prevent the default behavior of the event', () => {
      simulateKeyDown('Tab');
      strictEqual(defaultPrevented, false);
    });
  });

  QUnit.module('other keys on the afterGrid region', (hooks) => {
    hooks.beforeEach(() => {
      gridSupport.state.setActiveLocation('afterGrid');
      $activeElement = gridSupport.helper.getAfterGridNode();
    });

    test('does not change the active location', () => {
      simulateKeyDown('LeftArrow');
      const activeLocation = gridSupport.state.getActiveLocation();
      equal(activeLocation.region, 'afterGrid');
      equal(typeof activeLocation.cell, 'undefined');
      equal(typeof activeLocation.row, 'undefined');
    });

    test('prevents SlickGrid default behavior', () => {
      simulateKeyDown('LeftArrow');
      strictEqual(triggeredEvent.skipSlickGridDefaults, true);
    });

    test('does not stop propagation of the event', () => {
      simulateKeyDown('LeftArrow');
      equal(bubbledEvent, triggeredEvent);
    });

    test('does not prevent the default behavior of the event', () => {
      simulateKeyDown('LeftArrow');
      strictEqual(defaultPrevented, false);
    });
  });

  QUnit.module('Shift+Tab back out of the beforeGrid region', (hooks) => {
    hooks.beforeEach(() => {
      gridSupport.state.setActiveLocation('beforeGrid');
      $activeElement = gridSupport.helper.getBeforeGridNode();
    });

    test('prevents SlickGrid default behavior', () => {
      simulateKeyDown('ShiftTab');
      strictEqual(triggeredEvent.skipSlickGridDefaults, true);
    });

    test('does not stop propagation of the event', () => {
      simulateKeyDown('ShiftTab');
      equal(bubbledEvent, triggeredEvent);
    });

    test('does not prevent the default behavior of the event', () => {
      simulateKeyDown('ShiftTab');
      strictEqual(defaultPrevented, false);
    });
  });

  QUnit.module('Shift+Tab on a header cell', (hooks) => {
    hooks.beforeEach(() => {
      gridSupport.state.setActiveLocation('header', { row: 0, cell: 1 });
      $activeElement = gridSupport.helper.getBeforeGridNode();
    });

    test('sets the active location to the beforeGrid region', () => {
      simulateKeyDown('ShiftTab');
      const activeLocation = gridSupport.state.getActiveLocation();
      equal(activeLocation.region, 'beforeGrid');
      equal(typeof activeLocation.cell, 'undefined');
      equal(typeof activeLocation.row, 'undefined');
    });

    test('triggers onNavigatePrev', () => {
      const handler = sinon.spy();
      gridSupport.events.onNavigatePrev.subscribe(handler);
      simulateKeyDown('ShiftTab');
      strictEqual(handler.callCount, 1);
    });

    test('includes the event when triggering onNavigatePrev', () => {
      let capturedEvent;
      gridSupport.events.onNavigatePrev.subscribe((event, _activeLocation) => { capturedEvent = event });
      simulateKeyDown('ShiftTab');
      equal(capturedEvent, triggeredEvent);
    });

    test('includes the active location when triggering onNavigatePrev', () => {
      let location;
      gridSupport.events.onNavigatePrev.subscribe((_event, activeLocation) => { location = activeLocation });
      simulateKeyDown('ShiftTab');
      equal(location.region, 'beforeGrid');
      equal(typeof location.row, 'undefined');
      equal(typeof location.cell, 'undefined');
    });

    test('prevents SlickGrid default behavior', () => {
      simulateKeyDown('ShiftTab');
      strictEqual(triggeredEvent.skipSlickGridDefaults, true);
    });

    test('does not stop propagation of the event', () => {
      simulateKeyDown('ShiftTab');
      equal(bubbledEvent, triggeredEvent);
    });

    test('does not prevent the default behavior of the event', () => {
      simulateKeyDown('ShiftTab');
      strictEqual(defaultPrevented, false);
    });

    test('activates the previously-active location when followed by Tab', () => {
      simulateKeyDown('Tab');
      $activeElement = gridSupport.helper.getAfterGridNode();
      simulateKeyDown('ShiftTab');
      const activeLocation = gridSupport.state.getActiveLocation();
      equal(activeLocation.region, 'header');
      strictEqual(activeLocation.cell, 1);
    });
  });

  QUnit.module('Shift+Tab on a body cell', (hooks) => {
    hooks.beforeEach(() => {
      gridSupport.state.setActiveLocation('body', { row: 1, cell: 1 });
      $activeElement = gridSupport.state.getActiveNode();
    });

    test('activates the beforeGrid region', () => {
      simulateKeyDown('ShiftTab');
      const activeLocation = gridSupport.state.getActiveLocation();
      equal(activeLocation.region, 'beforeGrid');
      equal(typeof activeLocation.cell, 'undefined');
      equal(typeof activeLocation.row, 'undefined');
    });

    test('triggers onNavigatePrev', () => {
      const handler = sinon.spy();
      gridSupport.events.onNavigatePrev.subscribe(handler);
      simulateKeyDown('ShiftTab');
      strictEqual(handler.callCount, 1);
    });

    test('includes the event when triggering onNavigatePrev', () => {
      let capturedEvent;
      gridSupport.events.onNavigatePrev.subscribe((event, _activeLocation) => { capturedEvent = event });
      simulateKeyDown('ShiftTab');
      equal(capturedEvent, triggeredEvent);
    });

    test('includes the active location when triggering onNavigatePrev', () => {
      let location;
      gridSupport.events.onNavigatePrev.subscribe((_event, activeLocation) => { location = activeLocation });
      simulateKeyDown('ShiftTab');
      equal(location.region, 'beforeGrid');
      equal(typeof location.cell, 'undefined');
      equal(typeof location.row, 'undefined');
    });

    test('prevents SlickGrid default behavior', () => {
      simulateKeyDown('ShiftTab');
      strictEqual(triggeredEvent.skipSlickGridDefaults, true);
    });

    test('does not stop propagation of the event', () => {
      simulateKeyDown('ShiftTab');
      equal(bubbledEvent, triggeredEvent);
    });

    test('prevents the default behavior of the event', () => {
      simulateKeyDown('ShiftTab');
      strictEqual(defaultPrevented, false);
    });

    test('activates the previously-active location when followed by Tab', () => {
      simulateKeyDown('Tab');
      $activeElement = gridSupport.helper.getAfterGridNode();
      simulateKeyDown('ShiftTab');

      const activeLocation = gridSupport.state.getActiveLocation();
      equal(activeLocation.region, 'body');
      strictEqual(activeLocation.row, 1);
      strictEqual(activeLocation.cell, 1);
    });
  });

  QUnit.module('Shift+Tab back into the grid', (hooks) => {
    hooks.beforeEach(() => {
      gridSupport.state.setActiveLocation('afterGrid');
      $activeElement = gridSupport.helper.getAfterGridNode();
    });

    test('sets the active location to the first column of the header by default', () => {
      simulateKeyDown('ShiftTab');
      const activeLocation = gridSupport.state.getActiveLocation();
      equal(activeLocation.region, 'header');
      strictEqual(activeLocation.cell, 0);
      strictEqual(typeof activeLocation.row, 'undefined');
    });

    test('triggers onNavigatePrev', () => {
      const handler = sinon.spy();
      gridSupport.events.onNavigatePrev.subscribe(handler);
      simulateKeyDown('ShiftTab');
      strictEqual(handler.callCount, 1);
    });

    test('includes the event when triggering onNavigatePrev', () => {
      let capturedEvent;
      gridSupport.events.onNavigatePrev.subscribe((event, _activeLocation) => { capturedEvent = event });
      simulateKeyDown('ShiftTab');
      equal(capturedEvent, triggeredEvent);
    });

    test('includes the active location when triggering onNavigatePrev', () => {
      let location;
      gridSupport.events.onNavigatePrev.subscribe((_event, activeLocation) => { location = activeLocation });
      simulateKeyDown('ShiftTab');
      equal(location.region, 'header');
      strictEqual(location.cell, 0);
      strictEqual(typeof location.row, 'undefined');
    });

    test('prevents SlickGrid default behavior', () => {
      simulateKeyDown('ShiftTab');
      strictEqual(triggeredEvent.skipSlickGridDefaults, true);
    });

    test('does not stop propagation of the event', () => {
      simulateKeyDown('ShiftTab');
      equal(bubbledEvent, triggeredEvent);
    });

    test('prevents the default behavior of the event', () => {
      simulateKeyDown('ShiftTab');
      strictEqual(defaultPrevented, true);
    });
  });

  QUnit.module('RightArrow between two header cells', (hooks) => {
    hooks.beforeEach(() => {
      gridSupport.state.setActiveLocation('header', { cell: 0 });
      $activeElement = gridSupport.helper.getBeforeGridNode();
    });

    test('activates the next header cell', () => {
      simulateKeyDown('RightArrow');
      const activeLocation = gridSupport.state.getActiveLocation();
      equal(activeLocation.region, 'header');
      strictEqual(activeLocation.cell, 1);
    });

    test('triggers onNavigateRight', () => {
      const handler = sinon.spy();
      gridSupport.events.onNavigateRight.subscribe(handler);
      simulateKeyDown('RightArrow');
      strictEqual(handler.callCount, 1);
    });

    test('includes the event when triggering onNavigateRight', () => {
      let capturedEvent;
      gridSupport.events.onNavigateRight.subscribe((event, _activeLocation) => { capturedEvent = event });
      simulateKeyDown('RightArrow');
      equal(capturedEvent, triggeredEvent);
    });

    test('includes the active location when triggering onNavigateRight', () => {
      let location;
      gridSupport.events.onNavigateRight.subscribe((_event, activeLocation) => { location = activeLocation });
      simulateKeyDown('RightArrow');
      equal(location.region, 'header');
      equal(location.cell, 1);
      equal(typeof location.row, 'undefined');
    });

    test('prevents SlickGrid default behavior', () => {
      simulateKeyDown('RightArrow');
      strictEqual(triggeredEvent.skipSlickGridDefaults, true);
    });

    test('does not stop propagation of the event', () => {
      simulateKeyDown('RightArrow');
      equal(bubbledEvent, triggeredEvent);
    });

    test('prevents the default behavior of the event', () => {
      simulateKeyDown('RightArrow');
      strictEqual(defaultPrevented, true);
    });
  });

  QUnit.module('RightArrow from frozen header cell to scrollable header cell', (hooks) => {
    hooks.beforeEach(() => {
      gridSupport.state.setActiveLocation('header', { cell: 1 });
      $activeElement = gridSupport.helper.getBeforeGridNode();
    });

    test('activates the next header cell', () => {
      simulateKeyDown('RightArrow');
      const activeLocation = gridSupport.state.getActiveLocation();
      equal(activeLocation.region, 'header');
      strictEqual(activeLocation.cell, 2);
    });

    test('triggers onNavigateRight', () => {
      const handler = sinon.spy();
      gridSupport.events.onNavigateRight.subscribe(handler);
      simulateKeyDown('RightArrow');
      strictEqual(handler.callCount, 1);
    });

    test('includes the event when triggering onNavigateRight', () => {
      let capturedEvent;
      gridSupport.events.onNavigateRight.subscribe((event, _activeLocation) => { capturedEvent = event });
      simulateKeyDown('RightArrow');
      equal(capturedEvent, triggeredEvent);
    });

    test('includes the active location when triggering onNavigateRight', () => {
      let location;
      gridSupport.events.onNavigateRight.subscribe((_event, activeLocation) => { location = activeLocation });
      simulateKeyDown('RightArrow');
      equal(location.region, 'header');
      equal(location.cell, 2);
      equal(typeof location.row, 'undefined');
    });

    test('prevents SlickGrid default behavior', () => {
      simulateKeyDown('RightArrow');
      strictEqual(triggeredEvent.skipSlickGridDefaults, true);
    });

    test('does not stop propagation of the event', () => {
      simulateKeyDown('RightArrow');
      equal(bubbledEvent, triggeredEvent);
    });

    test('prevents the default behavior of the event', () => {
      simulateKeyDown('RightArrow');
      strictEqual(defaultPrevented, true);
    });
  });

  QUnit.module('RightArrow on the last header cell', (hooks) => {
    hooks.beforeEach(() => {
      gridSupport.state.setActiveLocation('header', { cell: 3 });
      $activeElement = gridSupport.helper.getBeforeGridNode();
    });

    test('does not change the active location', () => {
      simulateKeyDown('RightArrow');
      const activeLocation = gridSupport.state.getActiveLocation();
      equal(activeLocation.region, 'header');
      strictEqual(activeLocation.cell, 3);
      equal(typeof activeLocation.row, 'undefined');
    });

    test('does not trigger onNavigateRight', () => {
      const handler = sinon.spy();
      gridSupport.events.onNavigateRight.subscribe(handler);
      simulateKeyDown('RightArrow');
      strictEqual(handler.callCount, 0);
    });

    test('prevents SlickGrid default behavior', () => {
      simulateKeyDown('RightArrow');
      strictEqual(triggeredEvent.skipSlickGridDefaults, true);
    });

    test('does not stop propagation of the event', () => {
      simulateKeyDown('RightArrow');
      equal(bubbledEvent, triggeredEvent);
    });

    test('does not prevent the default behavior of the event', () => {
      simulateKeyDown('RightArrow');
      strictEqual(defaultPrevented, false);
    });
  });

  QUnit.module('RightArrow between two body cells', (hooks) => {
    hooks.beforeEach(() => {
      gridSupport.state.setActiveLocation('body', { row: 0, cell: 0 });
      $activeElement = gridSupport.state.getActiveNode();
    });

    test('activates the next cell of the body row', () => {
      simulateKeyDown('RightArrow');
      const activeLocation = gridSupport.state.getActiveLocation();
      equal(activeLocation.region, 'body');
      strictEqual(activeLocation.cell, 1);
      strictEqual(activeLocation.row, 0);
    });

    test('does not prevent SlickGrid default behavior', () => {
      simulateKeyDown('RightArrow');
      equal(typeof triggeredEvent.skipSlickGridDefaults, 'undefined');
    });

    test('stops propagation of the event', () => {
      simulateKeyDown('RightArrow');
      equal(typeof bubbledEvent, 'undefined');
    });
  });

  QUnit.module('RightArrow on the last cell of a row', (hooks) => {
    hooks.beforeEach(() => {
      gridSupport.state.setActiveLocation('body', { row: 0, cell: 3 });
      $activeElement = gridSupport.state.getActiveNode();
    });

    test('does not change the active location', () => {
      simulateKeyDown('RightArrow');
      const activeLocation = gridSupport.state.getActiveLocation();
      equal(activeLocation.region, 'body');
      strictEqual(activeLocation.cell, 3);
      strictEqual(activeLocation.row, 0);
    });

    test('does not prevent SlickGrid default behavior', () => {
      simulateKeyDown('RightArrow');
      equal(typeof triggeredEvent.skipSlickGridDefaults, 'undefined');
    });

    test('does not stop propagation of the event', () => {
      simulateKeyDown('RightArrow');
      equal(bubbledEvent, triggeredEvent);
    });

    test('does not prevent the default behavior of the event', () => {
      simulateKeyDown('RightArrow');
      strictEqual(defaultPrevented, false);
    });
  });

  QUnit.module('LeftArrow between two header cells', (hooks) => {
    hooks.beforeEach(() => {
      gridSupport.state.setActiveLocation('header', { cell: 1 });
      $activeElement = gridSupport.helper.getBeforeGridNode();
    });

    test('activates the next header cell', () => {
      simulateKeyDown('LeftArrow');
      const activeLocation = gridSupport.state.getActiveLocation();
      equal(activeLocation.region, 'header');
      strictEqual(activeLocation.cell, 0);
    });

    test('triggers onNavigateLeft', () => {
      const handler = sinon.spy();
      gridSupport.events.onNavigateLeft.subscribe(handler);
      simulateKeyDown('LeftArrow');
      strictEqual(handler.callCount, 1);
    });

    test('includes the event when triggering onNavigateLeft', () => {
      let capturedEvent;
      gridSupport.events.onNavigateLeft.subscribe((event, _activeLocation) => { capturedEvent = event });
      simulateKeyDown('LeftArrow');
      equal(capturedEvent, triggeredEvent);
    });

    test('includes the active location when triggering onNavigateLeft', () => {
      let location;
      gridSupport.events.onNavigateLeft.subscribe((_event, activeLocation) => { location = activeLocation });
      simulateKeyDown('LeftArrow');
      equal(location.region, 'header');
      equal(location.cell, 0);
      equal(typeof location.row, 'undefined');
    });

    test('prevents SlickGrid default behavior', () => {
      simulateKeyDown('LeftArrow');
      strictEqual(triggeredEvent.skipSlickGridDefaults, true);
    });

    test('does not stop propagation of the event', () => {
      simulateKeyDown('LeftArrow');
      equal(bubbledEvent, triggeredEvent);
    });

    test('prevents the default behavior of the event', () => {
      simulateKeyDown('LeftArrow');
      strictEqual(defaultPrevented, true);
    });
  });

  QUnit.module('LeftArrow from scrollable header cell to frozen header cell', (hooks) => {
    hooks.beforeEach(() => {
      gridSupport.state.setActiveLocation('header', { cell: 2 });
      $activeElement = gridSupport.helper.getBeforeGridNode();
    });

    test('activates the next header cell', () => {
      simulateKeyDown('LeftArrow');
      const activeLocation = gridSupport.state.getActiveLocation();
      equal(activeLocation.region, 'header');
      strictEqual(activeLocation.cell, 1);
    });

    test('triggers onNavigateLeft', () => {
      const handler = sinon.spy();
      gridSupport.events.onNavigateLeft.subscribe(handler);
      simulateKeyDown('LeftArrow');
      strictEqual(handler.callCount, 1);
    });

    test('includes the event when triggering onNavigateLeft', () => {
      let capturedEvent;
      gridSupport.events.onNavigateLeft.subscribe((event, _activeLocation) => { capturedEvent = event });
      simulateKeyDown('LeftArrow');
      equal(capturedEvent, triggeredEvent);
    });

    test('includes the active location when triggering onNavigateLeft', () => {
      let location;
      gridSupport.events.onNavigateLeft.subscribe((_event, activeLocation) => { location = activeLocation });
      simulateKeyDown('LeftArrow');
      equal(location.region, 'header');
      equal(location.cell, 1);
      equal(typeof location.row, 'undefined');
    });

    test('prevents SlickGrid default behavior', () => {
      simulateKeyDown('LeftArrow');
      strictEqual(triggeredEvent.skipSlickGridDefaults, true);
    });

    test('does not stop propagation of the event', () => {
      simulateKeyDown('LeftArrow');
      equal(bubbledEvent, triggeredEvent);
    });

    test('prevents the default behavior of the event', () => {
      simulateKeyDown('LeftArrow');
      strictEqual(defaultPrevented, true);
    });
  });

  QUnit.module('LeftArrow on the first header cell', (hooks) => {
    hooks.beforeEach(() => {
      gridSupport.state.setActiveLocation('header', { cell: 0 });
      $activeElement = gridSupport.helper.getBeforeGridNode();
    });

    test('does not change the active location', () => {
      simulateKeyDown('LeftArrow');
      const activeLocation = gridSupport.state.getActiveLocation();
      equal(activeLocation.region, 'header');
      strictEqual(activeLocation.cell, 0);
      equal(typeof activeLocation.row, 'undefined');
    });

    test('does not trigger onNavigateLeft', () => {
      const handler = sinon.spy();
      gridSupport.events.onNavigateLeft.subscribe(handler);
      simulateKeyDown('LeftArrow');
      strictEqual(handler.callCount, 0);
    });

    test('prevents SlickGrid default behavior', () => {
      simulateKeyDown('LeftArrow');
      strictEqual(triggeredEvent.skipSlickGridDefaults, true);
    });

    test('does not stop propagation of the event', () => {
      simulateKeyDown('LeftArrow');
      equal(bubbledEvent, triggeredEvent);
    });

    test('does not prevent the default behavior of the event', () => {
      simulateKeyDown('LeftArrow');
      strictEqual(defaultPrevented, false);
    });
  });

  QUnit.module('LeftArrow between two body cells', (hooks) => {
    hooks.beforeEach(() => {
      gridSupport.state.setActiveLocation('body', { row: 0, cell: 1 });
      $activeElement = gridSupport.state.getActiveNode();
    });

    test('activates the previous cell of the body row', () => {
      simulateKeyDown('LeftArrow');
      const activeLocation = gridSupport.state.getActiveLocation();
      equal(activeLocation.region, 'body');
      strictEqual(activeLocation.cell, 0);
      strictEqual(activeLocation.row, 0);
    });

    test('does not prevent SlickGrid default behavior', () => {
      simulateKeyDown('LeftArrow');
      equal(typeof triggeredEvent.skipSlickGridDefaults, 'undefined');
    });

    test('stops propagation of the event', () => {
      simulateKeyDown('LeftArrow');
      equal(typeof bubbledEvent, 'undefined');
    });
  });

  QUnit.module('LeftArrow on the first cell of a row', (hooks) => {
    hooks.beforeEach(() => {
      gridSupport.state.setActiveLocation('body', { row: 0, cell: 0 });
      $activeElement = gridSupport.state.getActiveNode();
    });

    test('does not change the active location', () => {
      simulateKeyDown('LeftArrow');
      const activeLocation = gridSupport.state.getActiveLocation();
      equal(activeLocation.region, 'body');
      strictEqual(activeLocation.cell, 0);
      strictEqual(activeLocation.row, 0);
    });

    test('prevents SlickGrid default behavior', () => {
      simulateKeyDown('LeftArrow');
      strictEqual(triggeredEvent.skipSlickGridDefaults, true);
    });

    test('does not stop propagation of the event', () => {
      simulateKeyDown('LeftArrow');
      equal(bubbledEvent, triggeredEvent);
    });

    test('does not prevent the default behavior of the event', () => {
      simulateKeyDown('LeftArrow');
      strictEqual(defaultPrevented, false);
    });
  });

  // This addresses a bug in SlickGrid that sets the active cell to the next
  // column of the first row when navigating left on the first cell of the last
  // row.
  QUnit.module('LeftArrow on the first cell of the last row', (hooks) => {
    hooks.beforeEach(() => {
      gridSupport.state.setActiveLocation('body', { row: 1, cell: 0 });
      $activeElement = gridSupport.state.getActiveNode();
    });

    test('does not change the active location', () => {
      simulateKeyDown('LeftArrow');
      const activeLocation = gridSupport.state.getActiveLocation();
      equal(activeLocation.region, 'body');
      strictEqual(activeLocation.cell, 0);
      strictEqual(activeLocation.row, 1);
    });

    test('prevents SlickGrid default behavior', () => {
      simulateKeyDown('LeftArrow');
      strictEqual(triggeredEvent.skipSlickGridDefaults, true);
    });

    test('does not stop propagation of the event', () => {
      simulateKeyDown('LeftArrow');
      equal(bubbledEvent, triggeredEvent);
    });

    test('does not prevent the default behavior of the event', () => {
      simulateKeyDown('LeftArrow');
      strictEqual(defaultPrevented, false);
    });
  });

  QUnit.module('UpArrow on a header cell', (hooks) => {
    hooks.beforeEach(() => {
      gridSupport.state.setActiveLocation('header', { cell: 0 });
      $activeElement = gridSupport.helper.getBeforeGridNode();
    });

    test('does not change the active location', () => {
      simulateKeyDown('UpArrow');
      const activeLocation = gridSupport.state.getActiveLocation();
      equal(activeLocation.region, 'header');
      strictEqual(activeLocation.cell, 0);
      equal(typeof activeLocation.row, 'undefined');
    });

    test('does not trigger onNavigateUp', () => {
      const handler = sinon.spy();
      gridSupport.events.onNavigateUp.subscribe(handler);
      simulateKeyDown('UpArrow');
      strictEqual(handler.callCount, 0);
    });

    test('prevents SlickGrid default behavior', () => {
      simulateKeyDown('UpArrow');
      strictEqual(triggeredEvent.skipSlickGridDefaults, true);
    });

    test('does not stop propagation of the event', () => {
      simulateKeyDown('UpArrow');
      equal(bubbledEvent, triggeredEvent);
    });

    test('does not prevent the default behavior of the event', () => {
      simulateKeyDown('UpArrow');
      strictEqual(defaultPrevented, false);
    });
  });

  QUnit.module('UpArrow on a cell in the first row', (hooks) => {
    hooks.beforeEach(() => {
      gridSupport.state.setActiveLocation('body', { row: 0, cell: 0 });
      $activeElement = gridSupport.state.getActiveNode();
    });

    test('activates the related header cell', () => {
      simulateKeyDown('UpArrow');
      const activeLocation = gridSupport.state.getActiveLocation();
      equal(activeLocation.region, 'header');
      strictEqual(activeLocation.cell, 0);
      equal(typeof activeLocation.row, 'undefined');
    });

    test('triggers onNavigateUp', () => {
      const handler = sinon.spy();
      gridSupport.events.onNavigateUp.subscribe(handler);
      simulateKeyDown('UpArrow');
      strictEqual(handler.callCount, 1);
    });

    test('includes the event when triggering onNavigateUp', () => {
      let capturedEvent;
      gridSupport.events.onNavigateUp.subscribe((event, _activeLocation) => { capturedEvent = event });
      simulateKeyDown('UpArrow');
      equal(capturedEvent, triggeredEvent);
    });

    test('includes the active location when triggering onNavigateUp', () => {
      let location;
      gridSupport.events.onNavigateUp.subscribe((_event, activeLocation) => { location = activeLocation });
      simulateKeyDown('UpArrow');
      equal(location.region, 'header');
      equal(location.cell, 0);
      equal(typeof location.row, 'undefined');
    });

    test('prevents SlickGrid default behavior', () => {
      simulateKeyDown('UpArrow');
      strictEqual(triggeredEvent.skipSlickGridDefaults, true);
    });

    test('does not stop propagation of the event', () => {
      simulateKeyDown('UpArrow');
      equal(bubbledEvent, triggeredEvent);
    });

    test('prevents the default behavior of the event', () => {
      simulateKeyDown('UpArrow');
      strictEqual(defaultPrevented, true);
    });
  });

  QUnit.module('UpArrow on a cell in a row other than the first', (hooks) => {
    hooks.beforeEach(() => {
      gridSupport.state.setActiveLocation('body', { row: 1, cell: 0 });
      $activeElement = gridSupport.state.getActiveNode();
    });

    test('activates the adjacent cell of the previous row', () => {
      simulateKeyDown('UpArrow');
      const activeLocation = gridSupport.state.getActiveLocation();
      equal(activeLocation.region, 'body');
      strictEqual(activeLocation.cell, 0);
      strictEqual(activeLocation.row, 0);
    });

    test('does not prevent SlickGrid default behavior', () => {
      simulateKeyDown('UpArrow');
      equal(typeof triggeredEvent.skipSlickGridDefaults, 'undefined');
    });

    test('stops propagation of the event', () => {
      simulateKeyDown('UpArrow');
      equal(typeof bubbledEvent, 'undefined');
    });
  });

  QUnit.module('DownArrow on a header cell', (hooks) => {
    hooks.beforeEach(() => {
      gridSupport.state.setActiveLocation('header', { cell: 0 });
      $activeElement = gridSupport.helper.getBeforeGridNode();
    });

    test('activates the related cell of the first row', () => {
      simulateKeyDown('DownArrow');
      const activeLocation = gridSupport.state.getActiveLocation();
      equal(activeLocation.region, 'body');
      strictEqual(activeLocation.cell, 0);
      strictEqual(activeLocation.row, 0);
    });

    test('triggers onNavigateDown', () => {
      const handler = sinon.spy();
      gridSupport.events.onNavigateDown.subscribe(handler);
      simulateKeyDown('DownArrow');
      strictEqual(handler.callCount, 1);
    });

    test('includes the event when triggering onNavigateDown', () => {
      let capturedEvent;
      gridSupport.events.onNavigateDown.subscribe((event, _activeLocation) => { capturedEvent = event });
      simulateKeyDown('DownArrow');
      equal(capturedEvent, triggeredEvent);
    });

    test('includes the active location when triggering onNavigateDown', () => {
      let location;
      gridSupport.events.onNavigateDown.subscribe((_event, activeLocation) => { location = activeLocation });
      simulateKeyDown('DownArrow');
      equal(location.region, 'body');
      strictEqual(location.cell, 0);
      strictEqual(location.row, 0);
    });

    test('prevents SlickGrid default behavior', () => {
      simulateKeyDown('DownArrow');
      strictEqual(triggeredEvent.skipSlickGridDefaults, true);
    });

    test('does not stop propagation of the event', () => {
      simulateKeyDown('DownArrow');
      equal(bubbledEvent, triggeredEvent);
    });

    test('prevents the default behavior of the event', () => {
      simulateKeyDown('DownArrow');
      strictEqual(defaultPrevented, true);
    });
  });

  QUnit.module('DownArrow on a body cell', (hooks) => {
    hooks.beforeEach(() => {
      gridSupport.state.setActiveLocation('body', { row: 0, cell: 0 });
      $activeElement = gridSupport.state.getActiveNode();
    });

    test('activates the adjacent cell of the next row', () => {
      simulateKeyDown('DownArrow');
      const activeLocation = gridSupport.state.getActiveLocation();
      equal(activeLocation.region, 'body');
      strictEqual(activeLocation.cell, 0);
      strictEqual(activeLocation.row, 1);
    });

    test('does not prevent SlickGrid default behavior', () => {
      simulateKeyDown('DownArrow');
      equal(typeof triggeredEvent.skipSlickGridDefaults, 'undefined');
    });

    test('stops propagation of the event', () => {
      simulateKeyDown('DownArrow');
      equal(typeof bubbledEvent, 'undefined');
    });
  });

  QUnit.module('DownArrow on a cell in the last row', (hooks) => {
    hooks.beforeEach(() => {
      gridSupport.state.setActiveLocation('body', { row: 1, cell: 0 });
      $activeElement = gridSupport.state.getActiveNode();
    });

    test('activates the cell of the next column in the first row', () => {
      simulateKeyDown('DownArrow');
      const activeLocation = gridSupport.state.getActiveLocation();
      equal(activeLocation.region, 'body');
      strictEqual(activeLocation.cell, 1);
      strictEqual(activeLocation.row, 0);
    });

    test('does not prevent SlickGrid default behavior', () => {
      simulateKeyDown('DownArrow');
      equal(typeof triggeredEvent.skipSlickGridDefaults, 'undefined');
    });

    test('stops propagation of the event', () => {
      simulateKeyDown('DownArrow');
      equal(typeof bubbledEvent, 'undefined');
    });
  });

  QUnit.module('with onKeyDown GridEvent subscribers', (hooks) => {
    let handledEvent;
    let handledLocation;

    hooks.beforeEach(() => {
      gridSupport.state.setActiveLocation('header', { cell: 0 });
      gridSupport.events.onKeyDown.subscribe((event, location) => {
        handledEvent = event;
        handledLocation = location;
      });
      $activeElement = gridSupport.helper.getBeforeGridNode();

      handledEvent = null;
      handledLocation = null;
    });

    test('calls each handler with the triggered event', () => {
      simulateKeyDown('Tab');
      equal(handledEvent, triggeredEvent);
    });

    test('calls each handler with the active location', () => {
      simulateKeyDown('Tab');
      equal(handledLocation.region, 'header');
      strictEqual(handledLocation.cell, 0);
      equal(typeof handledLocation.row, 'undefined');
    });

    test('triggers the event when handling keydown on a header child element', () => {
      const spy = sinon.spy();
      gridSupport.events.onKeyDown.subscribe(spy);
      simulateKeyDown('Tab', document.querySelectorAll('.slick-column-name')[2]);
      strictEqual(spy.callCount, 1);
    });

    test('skips Navigation behavior when a handler returns false', () => {
      gridSupport.events.onKeyDown.subscribe(() => false);
      simulateKeyDown('Tab');
      const activeLocation = gridSupport.state.getActiveLocation();
      strictEqual(activeLocation.cell, 0, 'active location did not change to second header cell');
    });

    test('prevents SlickGrid default behavior when a handler returns false', () => {
      gridSupport.events.onKeyDown.subscribe(() => false);
      simulateKeyDown('Tab');
      strictEqual(triggeredEvent.skipSlickGridDefaults, true);
    });

    test('includes the columnId in the active location when handling a header cell event', () => {
      simulateKeyDown('Tab');
      equal(handledLocation.columnId, 'column1');
    });

    test('includes the columnId in the active location when handling keydown on a header child element', () => {
      simulateKeyDown('Tab', document.querySelectorAll('.slick-column-name')[1]);
      equal(handledLocation.columnId, 'column2');
    });

    test('includes the columnId in the active location when handling a body cell event', () => {
      gridSupport.state.setActiveLocation('body', { row: 0, cell: 1 });
      simulateKeyDown('Tab', gridSupport.state.getActiveNode());
      equal(handledLocation.columnId, 'column2');
    });

    test('excludes a columnId from the active location when handling a "before grid" event', () => {
      gridSupport.state.setActiveLocation('beforeGrid');
      simulateKeyDown('Tab', gridSupport.helper.getBeforeGridNode());
      equal(typeof handledLocation.columnId, 'undefined');
    });

    test('excludes a columnId from the active location when handling an "after grid" event', () => {
      gridSupport.state.setActiveLocation('afterGrid');
      simulateKeyDown('Tab', gridSupport.helper.getAfterGridNode());
      equal(typeof handledLocation.columnId, 'undefined');
    });
  });

  QUnit.module('Click on a header', () => {
    test('activates the header location being clicked', () => {
      document.querySelectorAll('.slick-header-column')[1].click();
      const activeLocation = gridSupport.state.getActiveLocation();
      equal(activeLocation.region, 'header');
      strictEqual(activeLocation.cell, 1);
      equal(typeof activeLocation.row, 'undefined');
    });

    test('activates the header location when handling click on a header child element', () => {
      document.querySelectorAll('.slick-column-name')[1].click();
      const activeLocation = gridSupport.state.getActiveLocation();
      equal(activeLocation.region, 'header');
      strictEqual(activeLocation.cell, 1);
      equal(typeof activeLocation.row, 'undefined');
    });
  });
});
