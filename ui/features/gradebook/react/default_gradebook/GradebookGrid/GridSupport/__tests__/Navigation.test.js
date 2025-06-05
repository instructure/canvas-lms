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

import '@canvas/jquery-keycodes' // used by some SlickGrid editors
import slickgrid from 'slickgrid'
import GridSupport from '../index'

const {Grid, Editors} = slickgrid

const keyMap = {
  Tab: {which: 9, shiftKey: false},
  ShiftTab: {which: 9, shiftKey: true},
  LeftArrow: {which: 37},
  RightArrow: {which: 39},
  UpArrow: {which: 38},
  DownArrow: {which: 40},
}

function createColumns() {
  return [1, 2, 3, 4].map(id => ({
    id: `column${id}`,
    field: `columnData${id}`,
    name: `Column ${id}`,
  }))
}

function createRows() {
  return ['A', 'B'].map(id => ({
    id: `row${id}`,
    columnData1: `${id}1`,
    columnData2: `${id}2`,
    columnData3: `${id}3`,
    columnData4: `${id}4`,
  }))
}

function createGrid() {
  const options = {
    autoEdit: true, // enable editing upon cell activation
    autoHeight: true, // adjusts grid to fit rendered data
    editable: true,
    editorFactory: {
      getEditor() {
        return Editors.Checkbox
      },
    },
    enableCellNavigation: true,
    enableColumnReorder: false,
    numberOfColumnsToFreeze: 2, // for possible edge cases with multiple grid viewports
  }
  return new Grid('#example-grid', createRows(), createColumns(), options)
}

describe('GradebookGrid GridSupport Navigation', () => {
  let $fixtures
  let $activeElement

  let bubbledEvent
  let defaultPrevented
  let grid
  let gridSupport
  let triggeredEvent

  function onKeyDown(event) {
    bubbledEvent = event
    // Store the value of .defaultPrevented before lingering handlers from other
    // specs have an opportunity to change it prior to assertions.
    defaultPrevented = event.defaultPrevented
  }

  function simulateKeyDown(key, element = $activeElement) {
    const {which, shiftKey} = keyMap[key]
    const event = new Event('keydown', {bubbles: true, cancelable: true})
    event.keyCode = which
    event.shiftKey = shiftKey
    event.which = which
    element.dispatchEvent(event)
    triggeredEvent = event
  }

  beforeEach(() => {
    // Setup fixture
    $fixtures = document.createElement('div')
    document.body.appendChild($fixtures)
    const $gridContainer = document.createElement('div')
    $gridContainer.id = 'example-grid'
    $fixtures.appendChild($gridContainer)

    // Initialize Grid and GridSupport
    grid = createGrid()
    gridSupport = new GridSupport(grid)
    gridSupport.initialize()

    // Add event listener
    document.body.addEventListener('keydown', onKeyDown, false)

    // Reset event tracking variables
    bubbledEvent = undefined
    triggeredEvent = undefined
  })

  afterEach(() => {
    // Cleanup event listener
    document.body.removeEventListener('keydown', onKeyDown, false)

    // Destroy GridSupport and Grid
    gridSupport.destroy()
    grid.destroy()

    // Remove fixtures
    $fixtures.remove()
  })

  describe('Tab into the grid', () => {
    beforeEach(() => {
      gridSupport.state.setActiveLocation('beforeGrid')
      $activeElement = gridSupport.helper.getBeforeGridNode()
    })

    test('activates the first cell of the header', () => {
      simulateKeyDown('Tab')
      const activeLocation = gridSupport.state.getActiveLocation()
      expect(activeLocation.region).toBe('header')
      expect(activeLocation.cell).toBe(0)
      expect(activeLocation.row).toBeUndefined()
    })

    test('triggers onNavigateNext', () => {
      const handler = jest.fn()
      gridSupport.events.onNavigateNext.subscribe(handler)
      simulateKeyDown('Tab')
      expect(handler).toHaveBeenCalledTimes(1)
    })

    test('includes the event when triggering onNavigateNext', () => {
      let capturedEvent
      gridSupport.events.onNavigateNext.subscribe((event, _activeLocation) => {
        capturedEvent = event
      })
      simulateKeyDown('Tab')
      expect(capturedEvent).toBe(triggeredEvent)
    })

    test('includes the active location when triggering onNavigateNext', () => {
      let location
      gridSupport.events.onNavigateNext.subscribe((_event, activeLocation) => {
        location = activeLocation
      })
      simulateKeyDown('Tab')
      expect(location.region).toBe('header')
      expect(location.cell).toBe(0)
      expect(location.row).toBeUndefined()
    })

    test('prevents SlickGrid default behavior', () => {
      simulateKeyDown('Tab')
      expect(triggeredEvent.skipSlickGridDefaults).toBe(true)
    })

    test('does not stop propagation of the event', () => {
      simulateKeyDown('Tab')
      expect(bubbledEvent).toBe(triggeredEvent)
    })

    test('prevents the default behavior of the event', () => {
      simulateKeyDown('Tab')
      expect(defaultPrevented).toBe(true)
    })
  })

  describe('other keys on the beforeGrid region', () => {
    beforeEach(() => {
      gridSupport.state.setActiveLocation('beforeGrid')
      $activeElement = gridSupport.helper.getBeforeGridNode()
    })

    test('does not change the active location', () => {
      simulateKeyDown('RightArrow')
      const activeLocation = gridSupport.state.getActiveLocation()
      expect(activeLocation.region).toBe('beforeGrid')
      expect(activeLocation.cell).toBeUndefined()
      expect(activeLocation.row).toBeUndefined()
    })

    test('prevents SlickGrid default behavior', () => {
      simulateKeyDown('RightArrow')
      expect(triggeredEvent.skipSlickGridDefaults).toBe(true)
    })

    test('does not stop propagation of the event', () => {
      simulateKeyDown('RightArrow')
      expect(bubbledEvent).toBe(triggeredEvent)
    })

    test('does not prevent the default behavior of the event', () => {
      simulateKeyDown('RightArrow')
      expect(defaultPrevented).toBe(false)
    })
  })

  describe('Tab on a header cell', () => {
    beforeEach(() => {
      gridSupport.state.setActiveLocation('header', {cell: 1})
      $activeElement = gridSupport.helper.getBeforeGridNode()
    })

    test('sets the active location to the afterGrid region', () => {
      simulateKeyDown('Tab')
      const activeLocation = gridSupport.state.getActiveLocation()
      expect(activeLocation.region).toBe('afterGrid')
      expect(activeLocation.cell).toBeUndefined()
      expect(activeLocation.row).toBeUndefined()
    })

    test('triggers onNavigateNext', () => {
      const handler = jest.fn()
      gridSupport.events.onNavigateNext.subscribe(handler)
      simulateKeyDown('Tab')
      expect(handler).toHaveBeenCalledTimes(1)
    })

    test('includes the event when triggering onNavigateNext', () => {
      let capturedEvent
      gridSupport.events.onNavigateNext.subscribe((event, _activeLocation) => {
        capturedEvent = event
      })
      simulateKeyDown('Tab')
      expect(capturedEvent).toBe(triggeredEvent)
    })

    test('includes the active location when triggering onNavigateNext', () => {
      let location
      gridSupport.events.onNavigateNext.subscribe((_event, activeLocation) => {
        location = activeLocation
      })
      simulateKeyDown('Tab')
      expect(location.region).toBe('afterGrid')
      expect(location.cell).toBeUndefined()
      expect(location.row).toBeUndefined()
    })

    test('prevents SlickGrid default behavior', () => {
      simulateKeyDown('Tab')
      expect(triggeredEvent.skipSlickGridDefaults).toBe(true)
    })

    test('does not stop propagation of the event', () => {
      simulateKeyDown('Tab')
      expect(bubbledEvent).toBe(triggeredEvent)
    })

    test('prevents the default behavior of the event', () => {
      simulateKeyDown('Tab')
      expect(defaultPrevented).toBe(false)
    })

    test('activates the afterGrid region when handling keydown on a header child element', () => {
      const headerChild = document.querySelectorAll('.slick-column-name')[2]
      simulateKeyDown('Tab', headerChild)
      const activeLocation = gridSupport.state.getActiveLocation()
      expect(activeLocation.region).toBe('afterGrid')
      expect(activeLocation.cell).toBeUndefined()
      expect(activeLocation.row).toBeUndefined()
    })

    test('activates the previously-active location when followed by Shift+Tab', () => {
      simulateKeyDown('Tab')
      $activeElement = gridSupport.helper.getAfterGridNode()
      simulateKeyDown('ShiftTab')

      const activeLocation = gridSupport.state.getActiveLocation()
      expect(activeLocation.region).toBe('header')
      expect(activeLocation.cell).toBe(1)
      expect(activeLocation.row).toBeUndefined()
    })
  })

  describe('Tab on a body cell', () => {
    beforeEach(() => {
      gridSupport.state.setActiveLocation('body', {row: 0, cell: 1})
      $activeElement = gridSupport.state.getActiveNode()
    })

    test('sets the active location to the afterGrid region', () => {
      simulateKeyDown('Tab')
      const activeLocation = gridSupport.state.getActiveLocation()
      expect(activeLocation.region).toBe('afterGrid')
      expect(activeLocation.cell).toBeUndefined()
      expect(activeLocation.row).toBeUndefined()
    })

    test('prevents SlickGrid default behavior', () => {
      simulateKeyDown('Tab')
      expect(triggeredEvent.skipSlickGridDefaults).toBe(true)
    })

    test('does not stop propagation of the event', () => {
      simulateKeyDown('Tab')
      expect(bubbledEvent).toBe(triggeredEvent)
    })
  })

  describe('Tab out of the afterGrid region', () => {
    beforeEach(() => {
      gridSupport.state.setActiveLocation('afterGrid')
      $activeElement = gridSupport.helper.getAfterGridNode()
    })

    test('sets the active location to "unknown"', () => {
      simulateKeyDown('Tab')
      const activeLocation = gridSupport.state.getActiveLocation()
      expect(activeLocation.region).toBe('unknown')
      expect(activeLocation.cell).toBeUndefined()
      expect(activeLocation.row).toBeUndefined()
    })

    test('triggers onNavigateNext', () => {
      const handler = jest.fn()
      gridSupport.events.onNavigateNext.subscribe(handler)
      simulateKeyDown('Tab')
      expect(handler).toHaveBeenCalledTimes(1)
    })

    test('includes the event when triggering onNavigateNext', () => {
      let capturedEvent
      gridSupport.events.onNavigateNext.subscribe((event, _activeLocation) => {
        capturedEvent = event
      })
      simulateKeyDown('Tab')
      expect(capturedEvent).toBe(triggeredEvent)
    })

    test('includes the active location when triggering onNavigateNext', () => {
      let location
      gridSupport.events.onNavigateNext.subscribe((_event, activeLocation) => {
        location = activeLocation
      })
      simulateKeyDown('Tab')
      expect(location.region).toBe('unknown')
      expect(location.cell).toBeUndefined()
      expect(location.row).toBeUndefined()
    })

    test('prevents SlickGrid default behavior', () => {
      simulateKeyDown('Tab')
      expect(triggeredEvent.skipSlickGridDefaults).toBe(true)
    })

    test('does not stop propagation of the event', () => {
      simulateKeyDown('Tab')
      expect(bubbledEvent).toBe(triggeredEvent)
    })

    test('does not prevent the default behavior of the event', () => {
      simulateKeyDown('Tab')
      expect(defaultPrevented).toBe(false)
    })
  })

  describe('other keys on the afterGrid region', () => {
    beforeEach(() => {
      gridSupport.state.setActiveLocation('afterGrid')
      $activeElement = gridSupport.helper.getAfterGridNode()
    })

    test('does not change the active location', () => {
      simulateKeyDown('LeftArrow')
      const activeLocation = gridSupport.state.getActiveLocation()
      expect(activeLocation.region).toBe('afterGrid')
      expect(activeLocation.cell).toBeUndefined()
      expect(activeLocation.row).toBeUndefined()
    })

    test('prevents SlickGrid default behavior', () => {
      simulateKeyDown('LeftArrow')
      expect(triggeredEvent.skipSlickGridDefaults).toBe(true)
    })

    test('does not stop propagation of the event', () => {
      simulateKeyDown('LeftArrow')
      expect(bubbledEvent).toBe(triggeredEvent)
    })

    test('does not prevent the default behavior of the event', () => {
      simulateKeyDown('LeftArrow')
      expect(defaultPrevented).toBe(false)
    })
  })

  describe('Shift+Tab back out of the beforeGrid region', () => {
    beforeEach(() => {
      gridSupport.state.setActiveLocation('beforeGrid')
      $activeElement = gridSupport.helper.getBeforeGridNode()
    })

    test('prevents SlickGrid default behavior', () => {
      simulateKeyDown('ShiftTab')
      expect(triggeredEvent.skipSlickGridDefaults).toBe(true)
    })

    test('does not stop propagation of the event', () => {
      simulateKeyDown('ShiftTab')
      expect(bubbledEvent).toBe(triggeredEvent)
    })

    test('does not prevent the default behavior of the event', () => {
      simulateKeyDown('ShiftTab')
      expect(defaultPrevented).toBe(false)
    })
  })

  describe('Shift+Tab on a header cell', () => {
    beforeEach(() => {
      gridSupport.state.setActiveLocation('header', {row: 0, cell: 1})
      $activeElement = gridSupport.helper.getBeforeGridNode()
    })

    test('sets the active location to the beforeGrid region', () => {
      simulateKeyDown('ShiftTab')
      const activeLocation = gridSupport.state.getActiveLocation()
      expect(activeLocation.region).toBe('beforeGrid')
      expect(activeLocation.cell).toBeUndefined()
      expect(activeLocation.row).toBeUndefined()
    })

    test('triggers onNavigatePrev', () => {
      const handler = jest.fn()
      gridSupport.events.onNavigatePrev.subscribe(handler)
      simulateKeyDown('ShiftTab')
      expect(handler).toHaveBeenCalledTimes(1)
    })

    test('includes the event when triggering onNavigatePrev', () => {
      let capturedEvent
      gridSupport.events.onNavigatePrev.subscribe((event, _activeLocation) => {
        capturedEvent = event
      })
      simulateKeyDown('ShiftTab')
      expect(capturedEvent).toBe(triggeredEvent)
    })

    test('includes the active location when triggering onNavigatePrev', () => {
      let location
      gridSupport.events.onNavigatePrev.subscribe((event, activeLocation) => {
        location = activeLocation
      })
      simulateKeyDown('ShiftTab')
      expect(location.region).toBe('beforeGrid')
      expect(location.cell).toBeUndefined()
      expect(location.row).toBeUndefined()
    })

    test('prevents SlickGrid default behavior', () => {
      simulateKeyDown('ShiftTab')
      expect(triggeredEvent.skipSlickGridDefaults).toBe(true)
    })

    test('does not stop propagation of the event', () => {
      simulateKeyDown('ShiftTab')
      expect(bubbledEvent).toBe(triggeredEvent)
    })

    test('does not prevent the default behavior of the event', () => {
      simulateKeyDown('ShiftTab')
      expect(defaultPrevented).toBe(false)
    })

    test('activates the previously-active location when followed by Tab', () => {
      simulateKeyDown('Tab')
      $activeElement = gridSupport.helper.getAfterGridNode()
      simulateKeyDown('ShiftTab')

      const activeLocation = gridSupport.state.getActiveLocation()
      expect(activeLocation.region).toBe('header')
      expect(activeLocation.cell).toBe(1)
    })
  })

  describe('Shift+Tab on a body cell', () => {
    beforeEach(() => {
      gridSupport.state.setActiveLocation('body', {row: 1, cell: 1})
      $activeElement = gridSupport.state.getActiveNode()
    })

    test('activates the beforeGrid region', () => {
      simulateKeyDown('ShiftTab')
      const activeLocation = gridSupport.state.getActiveLocation()
      expect(activeLocation.region).toBe('beforeGrid')
      expect(activeLocation.cell).toBeUndefined()
      expect(activeLocation.row).toBeUndefined()
    })

    test('triggers onNavigatePrev', () => {
      const handler = jest.fn()
      gridSupport.events.onNavigatePrev.subscribe(handler)
      simulateKeyDown('ShiftTab')
      expect(handler).toHaveBeenCalledTimes(1)
    })

    test('includes the event when triggering onNavigatePrev', () => {
      let capturedEvent
      gridSupport.events.onNavigatePrev.subscribe((event, _activeLocation) => {
        capturedEvent = event
      })
      simulateKeyDown('ShiftTab')
      expect(capturedEvent).toBe(triggeredEvent)
    })

    test('includes the active location when triggering onNavigatePrev', () => {
      let location
      gridSupport.events.onNavigatePrev.subscribe((event, activeLocation) => {
        location = activeLocation
      })
      simulateKeyDown('ShiftTab')
      expect(location.region).toBe('beforeGrid')
      expect(location.cell).toBeUndefined()
      expect(location.row).toBeUndefined()
    })

    test('prevents SlickGrid default behavior', () => {
      simulateKeyDown('ShiftTab')
      expect(triggeredEvent.skipSlickGridDefaults).toBe(true)
    })

    test('does not stop propagation of the event', () => {
      simulateKeyDown('ShiftTab')
      expect(bubbledEvent).toBe(triggeredEvent)
    })

    test('prevents the default behavior of the event', () => {
      simulateKeyDown('ShiftTab')
      expect(defaultPrevented).toBe(false)
    })

    test('activates the previously-active location when followed by Tab', () => {
      simulateKeyDown('Tab')
      $activeElement = gridSupport.helper.getAfterGridNode()
      simulateKeyDown('ShiftTab')

      const activeLocation = gridSupport.state.getActiveLocation()
      expect(activeLocation.region).toBe('body')
      expect(activeLocation.row).toBe(1)
      expect(activeLocation.cell).toBe(1)
    })
  })

  describe('RightArrow between two header cells', () => {
    beforeEach(() => {
      gridSupport.state.setActiveLocation('header', {cell: 0})
      $activeElement = gridSupport.helper.getBeforeGridNode()
    })

    test('activates the next header cell', () => {
      simulateKeyDown('RightArrow')
      const activeLocation = gridSupport.state.getActiveLocation()
      expect(activeLocation.region).toBe('header')
      expect(activeLocation.cell).toBe(1)
    })

    test('triggers onNavigateRight', () => {
      const handler = jest.fn()
      gridSupport.events.onNavigateRight.subscribe(handler)
      simulateKeyDown('RightArrow')
      expect(handler).toHaveBeenCalledTimes(1)
    })

    test('includes the event when triggering onNavigateRight', () => {
      let capturedEvent
      gridSupport.events.onNavigateRight.subscribe((event, _activeLocation) => {
        capturedEvent = event
      })
      simulateKeyDown('RightArrow')
      expect(capturedEvent).toBe(triggeredEvent)
    })

    test('includes the active location when triggering onNavigateRight', () => {
      let location
      gridSupport.events.onNavigateRight.subscribe((event, activeLocation) => {
        location = activeLocation
      })
      simulateKeyDown('RightArrow')
      expect(location.region).toBe('header')
      expect(location.cell).toBe(1)
      expect(location.row).toBeUndefined()
    })

    test('prevents SlickGrid default behavior', () => {
      simulateKeyDown('RightArrow')
      expect(triggeredEvent.skipSlickGridDefaults).toBe(true)
    })

    test('does not stop propagation of the event', () => {
      simulateKeyDown('RightArrow')
      expect(bubbledEvent).toBe(triggeredEvent)
    })

    test('prevents the default behavior of the event', () => {
      simulateKeyDown('RightArrow')
      expect(defaultPrevented).toBe(true)
    })
  })

  describe('RightArrow from frozen header cell to scrollable header cell', () => {
    beforeEach(() => {
      gridSupport.state.setActiveLocation('header', {cell: 1})
      $activeElement = gridSupport.helper.getBeforeGridNode()
    })

    test('activates the next header cell', () => {
      simulateKeyDown('RightArrow')
      const activeLocation = gridSupport.state.getActiveLocation()
      expect(activeLocation.region).toBe('header')
      expect(activeLocation.cell).toBe(2)
    })

    test('triggers onNavigateRight', () => {
      const handler = jest.fn()
      gridSupport.events.onNavigateRight.subscribe(handler)
      simulateKeyDown('RightArrow')
      expect(handler).toHaveBeenCalledTimes(1)
    })

    test('includes the event when triggering onNavigateRight', () => {
      let capturedEvent
      gridSupport.events.onNavigateRight.subscribe((event, _activeLocation) => {
        capturedEvent = event
      })
      simulateKeyDown('RightArrow')
      expect(capturedEvent).toBe(triggeredEvent)
    })

    test('includes the active location when triggering onNavigateRight', () => {
      let location
      gridSupport.events.onNavigateRight.subscribe((event, activeLocation) => {
        location = activeLocation
      })
      simulateKeyDown('RightArrow')
      expect(location.region).toBe('header')
      expect(location.cell).toBe(2)
      expect(location.row).toBeUndefined()
    })

    test('prevents SlickGrid default behavior', () => {
      simulateKeyDown('RightArrow')
      expect(triggeredEvent.skipSlickGridDefaults).toBe(true)
    })

    test('does not stop propagation of the event', () => {
      simulateKeyDown('RightArrow')
      expect(bubbledEvent).toBe(triggeredEvent)
    })

    test('prevents the default behavior of the event', () => {
      simulateKeyDown('RightArrow')
      expect(defaultPrevented).toBe(true)
    })
  })

  describe('RightArrow on the last header cell', () => {
    beforeEach(() => {
      gridSupport.state.setActiveLocation('header', {cell: 3})
      $activeElement = gridSupport.helper.getBeforeGridNode()
    })

    test('does not change the active location', () => {
      simulateKeyDown('RightArrow')
      const activeLocation = gridSupport.state.getActiveLocation()
      expect(activeLocation.region).toBe('header')
      expect(activeLocation.cell).toBe(3)
      expect(activeLocation.row).toBeUndefined()
    })

    test('does not trigger onNavigateRight', () => {
      const handler = jest.fn()
      gridSupport.events.onNavigateRight.subscribe(handler)
      simulateKeyDown('RightArrow')
      expect(handler).toHaveBeenCalledTimes(0)
    })

    test('prevents SlickGrid default behavior', () => {
      simulateKeyDown('RightArrow')
      expect(triggeredEvent.skipSlickGridDefaults).toBe(true)
    })

    test('does not stop propagation of the event', () => {
      simulateKeyDown('RightArrow')
      expect(bubbledEvent).toBe(triggeredEvent)
    })

    test('does not prevent the default behavior of the event', () => {
      simulateKeyDown('RightArrow')
      expect(defaultPrevented).toBe(false)
    })
  })

  describe('RightArrow between two body cells', () => {
    beforeEach(() => {
      gridSupport.state.setActiveLocation('body', {row: 0, cell: 0})
      $activeElement = gridSupport.state.getActiveNode()
    })

    test('activates the next cell of the body row', () => {
      simulateKeyDown('RightArrow')
      const activeLocation = gridSupport.state.getActiveLocation()
      expect(activeLocation.region).toBe('body')
      expect(activeLocation.cell).toBe(1)
      expect(activeLocation.row).toBe(0)
    })

    test('prevents SlickGrid default behavior', () => {
      simulateKeyDown('RightArrow')
      expect(triggeredEvent.skipSlickGridDefaults).toBe(true)
    })

    test('does not stop propagation of the event', () => {
      simulateKeyDown('RightArrow')
      expect(bubbledEvent).toBe(triggeredEvent)
    })
  })

  describe('RightArrow on the last cell of a row', () => {
    beforeEach(() => {
      gridSupport.state.setActiveLocation('body', {row: 0, cell: 3})
      $activeElement = gridSupport.state.getActiveNode()
    })

    test('does not change the active location', () => {
      simulateKeyDown('RightArrow')
      const activeLocation = gridSupport.state.getActiveLocation()
      expect(activeLocation.region).toBe('body')
      expect(activeLocation.cell).toBe(3)
      expect(activeLocation.row).toBe(0)
    })

    test('does not prevent SlickGrid default behavior', () => {
      simulateKeyDown('RightArrow')
      expect(triggeredEvent.skipSlickGridDefaults).toBeUndefined()
    })

    test('does not stop propagation of the event', () => {
      simulateKeyDown('RightArrow')
      expect(bubbledEvent).toBe(triggeredEvent)
    })

    test('does not prevent the default behavior of the event', () => {
      simulateKeyDown('RightArrow')
      expect(defaultPrevented).toBe(false)
    })
  })

  describe('LeftArrow between two header cells', () => {
    beforeEach(() => {
      gridSupport.state.setActiveLocation('header', {cell: 1})
      $activeElement = gridSupport.helper.getBeforeGridNode()
    })

    test('activates the previous header cell', () => {
      simulateKeyDown('LeftArrow')
      const activeLocation = gridSupport.state.getActiveLocation()
      expect(activeLocation.region).toBe('header')
      expect(activeLocation.cell).toBe(0)
    })

    test('triggers onNavigateLeft', () => {
      const handler = jest.fn()
      gridSupport.events.onNavigateLeft.subscribe(handler)
      simulateKeyDown('LeftArrow')
      expect(handler).toHaveBeenCalledTimes(1)
    })

    test('includes the event when triggering onNavigateLeft', () => {
      let capturedEvent
      gridSupport.events.onNavigateLeft.subscribe((event, _activeLocation) => {
        capturedEvent = event
      })
      simulateKeyDown('LeftArrow')
      expect(capturedEvent).toBe(triggeredEvent)
    })

    test('includes the active location when triggering onNavigateLeft', () => {
      let location
      gridSupport.events.onNavigateLeft.subscribe((event, activeLocation) => {
        location = activeLocation
      })
      simulateKeyDown('LeftArrow')
      expect(location.region).toBe('header')
      expect(location.cell).toBe(0)
      expect(location.row).toBeUndefined()
    })

    test('prevents SlickGrid default behavior', () => {
      simulateKeyDown('LeftArrow')
      expect(triggeredEvent.skipSlickGridDefaults).toBe(true)
    })

    test('does not stop propagation of the event', () => {
      simulateKeyDown('LeftArrow')
      expect(bubbledEvent).toBe(triggeredEvent)
    })

    test('prevents the default behavior of the event', () => {
      simulateKeyDown('LeftArrow')
      expect(defaultPrevented).toBe(true)
    })
  })

  describe('LeftArrow from scrollable header cell to frozen header cell', () => {
    beforeEach(() => {
      gridSupport.state.setActiveLocation('header', {cell: 2})
      $activeElement = gridSupport.helper.getBeforeGridNode()
    })

    test('activates the previous header cell', () => {
      simulateKeyDown('LeftArrow')
      const activeLocation = gridSupport.state.getActiveLocation()
      expect(activeLocation.region).toBe('header')
      expect(activeLocation.cell).toBe(1)
    })

    test('triggers onNavigateLeft', () => {
      const handler = jest.fn()
      gridSupport.events.onNavigateLeft.subscribe(handler)
      simulateKeyDown('LeftArrow')
      expect(handler).toHaveBeenCalledTimes(1)
    })

    test('includes the event when triggering onNavigateLeft', () => {
      let capturedEvent
      gridSupport.events.onNavigateLeft.subscribe((event, _activeLocation) => {
        capturedEvent = event
      })
      simulateKeyDown('LeftArrow')
      expect(capturedEvent).toBe(triggeredEvent)
    })

    test('includes the active location when triggering onNavigateLeft', () => {
      let location
      gridSupport.events.onNavigateLeft.subscribe((event, activeLocation) => {
        location = activeLocation
      })
      simulateKeyDown('LeftArrow')
      expect(location.region).toBe('header')
      expect(location.cell).toBe(1)
      expect(location.row).toBeUndefined()
    })

    test('prevents SlickGrid default behavior', () => {
      simulateKeyDown('LeftArrow')
      expect(triggeredEvent.skipSlickGridDefaults).toBe(true)
    })

    test('does not stop propagation of the event', () => {
      simulateKeyDown('LeftArrow')
      expect(bubbledEvent).toBe(triggeredEvent)
    })

    test('prevents the default behavior of the event', () => {
      simulateKeyDown('LeftArrow')
      expect(defaultPrevented).toBe(true)
    })
  })

  describe('LeftArrow on the first header cell', () => {
    beforeEach(() => {
      gridSupport.state.setActiveLocation('header', {cell: 0})
      $activeElement = gridSupport.helper.getBeforeGridNode()
    })

    test('does not change the active location', () => {
      simulateKeyDown('LeftArrow')
      const activeLocation = gridSupport.state.getActiveLocation()
      expect(activeLocation.region).toBe('header')
      expect(activeLocation.cell).toBe(0)
      expect(activeLocation.row).toBeUndefined()
    })

    test('does not trigger onNavigateLeft', () => {
      const handler = jest.fn()
      gridSupport.events.onNavigateLeft.subscribe(handler)
      simulateKeyDown('LeftArrow')
      expect(handler).toHaveBeenCalledTimes(0)
    })

    test('prevents SlickGrid default behavior', () => {
      simulateKeyDown('LeftArrow')
      expect(triggeredEvent.skipSlickGridDefaults).toBe(true)
    })

    test('does not stop propagation of the event', () => {
      simulateKeyDown('LeftArrow')
      expect(bubbledEvent).toBe(triggeredEvent)
    })

    test('does not prevent the default behavior of the event', () => {
      simulateKeyDown('LeftArrow')
      expect(defaultPrevented).toBe(false)
    })
  })

  describe('LeftArrow between two body cells', () => {
    beforeEach(() => {
      gridSupport.state.setActiveLocation('body', {row: 0, cell: 1})
      $activeElement = gridSupport.state.getActiveNode()
    })

    test('activates the previous cell of the body row', () => {
      simulateKeyDown('LeftArrow')
      const activeLocation = gridSupport.state.getActiveLocation()
      expect(activeLocation.region).toBe('body')
      expect(activeLocation.cell).toBe(0)
      expect(activeLocation.row).toBe(0)
    })

    test('prevents SlickGrid default behavior', () => {
      simulateKeyDown('LeftArrow')
      expect(triggeredEvent.skipSlickGridDefaults).toBe(true)
    })

    test('does not stop propagation of the event', () => {
      simulateKeyDown('LeftArrow')
      expect(bubbledEvent).toBe(triggeredEvent)
    })
  })

  describe('LeftArrow on the first cell of a row', () => {
    beforeEach(() => {
      gridSupport.state.setActiveLocation('body', {row: 0, cell: 0})
      $activeElement = gridSupport.state.getActiveNode()
    })

    test('does not change the active location', () => {
      simulateKeyDown('LeftArrow')
      const activeLocation = gridSupport.state.getActiveLocation()
      expect(activeLocation.region).toBe('body')
      expect(activeLocation.cell).toBe(0)
      expect(activeLocation.row).toBe(0)
    })

    test('prevents SlickGrid default behavior', () => {
      simulateKeyDown('LeftArrow')
      expect(triggeredEvent.skipSlickGridDefaults).toBe(true)
    })

    test('does not stop propagation of the event', () => {
      simulateKeyDown('LeftArrow')
      expect(bubbledEvent).toBe(triggeredEvent)
    })

    test('does not prevent the default behavior of the event', () => {
      simulateKeyDown('LeftArrow')
      expect(defaultPrevented).toBe(false)
    })
  })

  describe('LeftArrow on the first cell of the last row', () => {
    beforeEach(() => {
      gridSupport.state.setActiveLocation('body', {row: 1, cell: 0})
      $activeElement = gridSupport.state.getActiveNode()
    })

    test('does not change the active location', () => {
      simulateKeyDown('LeftArrow')
      const activeLocation = gridSupport.state.getActiveLocation()
      expect(activeLocation.region).toBe('body')
      expect(activeLocation.cell).toBe(0)
      expect(activeLocation.row).toBe(1)
    })

    test('prevents SlickGrid default behavior', () => {
      simulateKeyDown('LeftArrow')
      expect(triggeredEvent.skipSlickGridDefaults).toBe(true)
    })

    test('does not stop propagation of the event', () => {
      simulateKeyDown('LeftArrow')
      expect(bubbledEvent).toBe(triggeredEvent)
    })

    test('does not prevent the default behavior of the event', () => {
      simulateKeyDown('LeftArrow')
      expect(defaultPrevented).toBe(false)
    })
  })

  describe('UpArrow on a header cell', () => {
    beforeEach(() => {
      gridSupport.state.setActiveLocation('header', {cell: 0})
      $activeElement = gridSupport.helper.getBeforeGridNode()
    })

    test('does not change the active location', () => {
      simulateKeyDown('UpArrow')
      const activeLocation = gridSupport.state.getActiveLocation()
      expect(activeLocation.region).toBe('header')
      expect(activeLocation.cell).toBe(0)
      expect(activeLocation.row).toBeUndefined()
    })

    test('does not trigger onNavigateUp', () => {
      const handler = jest.fn()
      gridSupport.events.onNavigateUp.subscribe(handler)
      simulateKeyDown('UpArrow')
      expect(handler).toHaveBeenCalledTimes(0)
    })

    test('prevents SlickGrid default behavior', () => {
      simulateKeyDown('UpArrow')
      expect(triggeredEvent.skipSlickGridDefaults).toBe(true)
    })

    test('does not stop propagation of the event', () => {
      simulateKeyDown('UpArrow')
      expect(bubbledEvent).toBe(triggeredEvent)
    })

    test('does not prevent the default behavior of the event', () => {
      simulateKeyDown('UpArrow')
      expect(defaultPrevented).toBe(false)
    })
  })

  describe('UpArrow on a cell in the first row', () => {
    beforeEach(() => {
      gridSupport.state.setActiveLocation('body', {row: 0, cell: 0})
      $activeElement = gridSupport.state.getActiveNode()
    })

    test('activates the related header cell', () => {
      simulateKeyDown('UpArrow')
      const activeLocation = gridSupport.state.getActiveLocation()
      expect(activeLocation.region).toBe('header')
      expect(activeLocation.cell).toBe(0)
      expect(activeLocation.row).toBeUndefined()
    })

    test('triggers onNavigateUp', () => {
      const handler = jest.fn()
      gridSupport.events.onNavigateUp.subscribe(handler)
      simulateKeyDown('UpArrow')
      expect(handler).toHaveBeenCalledTimes(1)
    })

    test('includes the event when triggering onNavigateUp', () => {
      let capturedEvent
      gridSupport.events.onNavigateUp.subscribe((event, _activeLocation) => {
        capturedEvent = event
      })
      simulateKeyDown('UpArrow')
      expect(capturedEvent).toBe(triggeredEvent)
    })

    test('includes the active location when triggering onNavigateUp', () => {
      let location
      gridSupport.events.onNavigateUp.subscribe((event, activeLocation) => {
        location = activeLocation
      })
      simulateKeyDown('UpArrow')
      expect(location.region).toBe('header')
      expect(location.cell).toBe(0)
      expect(location.row).toBeUndefined()
    })

    test('prevents SlickGrid default behavior', () => {
      simulateKeyDown('UpArrow')
      expect(triggeredEvent.skipSlickGridDefaults).toBe(true)
    })

    test('does not stop propagation of the event', () => {
      simulateKeyDown('UpArrow')
      expect(bubbledEvent).toBe(triggeredEvent)
    })

    test('prevents the default behavior of the event', () => {
      simulateKeyDown('UpArrow')
      expect(defaultPrevented).toBe(true)
    })
  })

  describe('UpArrow on a cell in a row other than the first', () => {
    beforeEach(() => {
      gridSupport.state.setActiveLocation('body', {row: 1, cell: 0})
      $activeElement = gridSupport.state.getActiveNode()
    })

    test('activates the adjacent cell of the previous row', () => {
      simulateKeyDown('UpArrow')
      const activeLocation = gridSupport.state.getActiveLocation()
      expect(activeLocation.region).toBe('body')
      expect(activeLocation.cell).toBe(0)
      expect(activeLocation.row).toBe(0)
    })

    test('prevents SlickGrid default behavior', () => {
      simulateKeyDown('UpArrow')
      expect(triggeredEvent.skipSlickGridDefaults).toBe(true)
    })

    test('does not stop propagation of the event', () => {
      simulateKeyDown('UpArrow')
      expect(bubbledEvent).toBe(triggeredEvent)
    })
  })

  describe('DownArrow on a header cell', () => {
    beforeEach(() => {
      gridSupport.state.setActiveLocation('header', {cell: 0})
      $activeElement = gridSupport.helper.getBeforeGridNode()
    })

    test('activates the related cell of the first row', () => {
      simulateKeyDown('DownArrow')
      const activeLocation = gridSupport.state.getActiveLocation()
      expect(activeLocation.region).toBe('body')
      expect(activeLocation.cell).toBe(0)
      expect(activeLocation.row).toBe(0)
    })

    test('triggers onNavigateDown', () => {
      const handler = jest.fn()
      gridSupport.events.onNavigateDown.subscribe(handler)
      simulateKeyDown('DownArrow')
      expect(handler).toHaveBeenCalledTimes(1)
    })

    test('includes the event when triggering onNavigateDown', () => {
      let capturedEvent
      gridSupport.events.onNavigateDown.subscribe((event, _activeLocation) => {
        capturedEvent = event
      })
      simulateKeyDown('DownArrow')
      expect(capturedEvent).toBe(triggeredEvent)
    })

    test('includes the active location when triggering onNavigateDown', () => {
      let location
      gridSupport.events.onNavigateDown.subscribe((event, activeLocation) => {
        location = activeLocation
      })
      simulateKeyDown('DownArrow')
      expect(location.region).toBe('body')
      expect(location.cell).toBe(0)
      expect(location.row).toBe(0)
    })

    test('prevents SlickGrid default behavior', () => {
      simulateKeyDown('DownArrow')
      expect(triggeredEvent.skipSlickGridDefaults).toBe(true)
    })

    test('does not stop propagation of the event', () => {
      simulateKeyDown('DownArrow')
      expect(bubbledEvent).toBe(triggeredEvent)
    })

    test('prevents the default behavior of the event', () => {
      simulateKeyDown('DownArrow')
      expect(defaultPrevented).toBe(true)
    })
  })

  describe('DownArrow on a body cell', () => {
    beforeEach(() => {
      gridSupport.state.setActiveLocation('body', {row: 0, cell: 0})
      $activeElement = gridSupport.state.getActiveNode()
    })

    test('activates the adjacent cell of the next row', () => {
      simulateKeyDown('DownArrow')
      const activeLocation = gridSupport.state.getActiveLocation()
      expect(activeLocation.region).toBe('body')
      expect(activeLocation.cell).toBe(0)
      expect(activeLocation.row).toBe(1)
    })

    test('prevents SlickGrid default behavior', () => {
      simulateKeyDown('DownArrow')
      expect(triggeredEvent.skipSlickGridDefaults).toBe(true)
    })

    test('does not stop propagation of the event', () => {
      simulateKeyDown('DownArrow')
      expect(bubbledEvent).toBe(triggeredEvent)
    })
  })

  describe('DownArrow on a cell in the last row', () => {
    beforeEach(() => {
      gridSupport.state.setActiveLocation('body', {row: 1, cell: 0})
      $activeElement = gridSupport.state.getActiveNode()
    })

    test('activates the cell of the next column in the first row', () => {
      simulateKeyDown('DownArrow')
      const activeLocation = gridSupport.state.getActiveLocation()
      expect(activeLocation.region).toBe('body')
      expect(activeLocation.cell).toBe(1)
      expect(activeLocation.row).toBe(0)
    })

    test('prevents SlickGrid default behavior', () => {
      simulateKeyDown('DownArrow')
      expect(triggeredEvent.skipSlickGridDefaults).toBe(true)
    })

    test('does not stop propagation of the event', () => {
      simulateKeyDown('DownArrow')
      expect(bubbledEvent).toBe(triggeredEvent)
    })
  })

  describe('DownArrow on a cell in the last row of the last column', () => {
    beforeEach(() => {
      gridSupport.state.setActiveLocation('body', {row: 1, cell: 3})
      $activeElement = gridSupport.state.getActiveNode()
    })

    test('keeps the current cell selected', () => {
      simulateKeyDown('DownArrow')
      const activeLocation = gridSupport.state.getActiveLocation()
      expect(activeLocation.region).toBe('body')
      expect(activeLocation.cell).toBe(3)
      expect(activeLocation.row).toBe(1)
    })

    test('prevents SlickGrid default behavior', () => {
      simulateKeyDown('DownArrow')
      expect(triggeredEvent.skipSlickGridDefaults).toBe(true)
    })

    test('does not stop propagation of the event', () => {
      simulateKeyDown('DownArrow')
      expect(bubbledEvent).toBe(triggeredEvent)
    })
  })

  describe('with onKeyDown GridEvent subscribers', () => {
    let handledEvent
    let handledLocation

    beforeEach(() => {
      gridSupport.state.setActiveLocation('header', {cell: 0})
      gridSupport.events.onKeyDown.subscribe((event, location) => {
        handledEvent = event
        handledLocation = location
      })
      $activeElement = gridSupport.helper.getBeforeGridNode()

      handledEvent = null
      handledLocation = null
    })

    test('calls each handler with the triggered event', () => {
      simulateKeyDown('Tab')
      expect(handledEvent).toBe(triggeredEvent)
    })

    test('calls each handler with the active location', () => {
      simulateKeyDown('Tab')
      expect(handledLocation.region).toBe('header')
      expect(handledLocation.cell).toBe(0)
      expect(handledLocation.row).toBeUndefined()
    })

    test('triggers the event when handling keydown on a header child element', () => {
      const spy = jest.fn()
      gridSupport.events.onKeyDown.subscribe(spy)
      const headerChild = document.querySelectorAll('.slick-column-name')[2]
      simulateKeyDown('Tab', headerChild)
      expect(spy).toHaveBeenCalledTimes(1)
    })

    test('skips Navigation behavior when a handler returns false', () => {
      gridSupport.events.onKeyDown.subscribe(() => false)
      simulateKeyDown('Tab')
      const activeLocation = gridSupport.state.getActiveLocation()
      expect(activeLocation.cell).toBe(0) // active location did not change to second header cell
    })

    test('prevents SlickGrid default behavior when a handler returns false', () => {
      gridSupport.events.onKeyDown.subscribe(() => false)
      simulateKeyDown('Tab')
      expect(triggeredEvent.skipSlickGridDefaults).toBe(true)
    })

    test('includes the columnId in the active location when handling a header cell event', () => {
      simulateKeyDown('Tab')
      expect(handledLocation.columnId).toBe('column1')
    })

    test('includes the columnId in the active location when handling keydown on a header child element', () => {
      const headerChild = document.querySelectorAll('.slick-column-name')[1]
      simulateKeyDown('Tab', headerChild)
      expect(handledLocation.columnId).toBe('column2')
    })

    test('includes the columnId in the active location when handling a body cell event', () => {
      gridSupport.state.setActiveLocation('body', {row: 0, cell: 1})
      const bodyCell = gridSupport.state.getActiveNode()
      simulateKeyDown('Tab', bodyCell)
      expect(handledLocation.columnId).toBe('column2')
    })

    test('excludes a columnId from the active location when handling a "before grid" event', () => {
      gridSupport.state.setActiveLocation('beforeGrid')
      const beforeGridNode = gridSupport.helper.getBeforeGridNode()
      simulateKeyDown('Tab', beforeGridNode)
      expect(handledLocation.columnId).toBeUndefined()
    })

    test('excludes a columnId from the active location when handling an "after grid" event', () => {
      gridSupport.state.setActiveLocation('afterGrid')
      const afterGridNode = gridSupport.helper.getAfterGridNode()
      simulateKeyDown('Tab', afterGridNode)
      expect(handledLocation.columnId).toBeUndefined()
    })
  })

  describe('Click on a header', () => {
    test('activates the header location being clicked', () => {
      const headerColumn = document.querySelectorAll('.slick-header-column')[1]
      headerColumn.click()
      const activeLocation = gridSupport.state.getActiveLocation()
      expect(activeLocation.region).toBe('header')
      expect(activeLocation.cell).toBe(1)
      expect(activeLocation.row).toBeUndefined()
    })

    test('activates the header location when handling click on a header child element', () => {
      const headerChild = document.querySelectorAll('.slick-column-name')[1]
      headerChild.click()
      const activeLocation = gridSupport.state.getActiveLocation()
      expect(activeLocation.region).toBe('header')
      expect(activeLocation.cell).toBe(1)
      expect(activeLocation.row).toBeUndefined()
    })
  })
})
