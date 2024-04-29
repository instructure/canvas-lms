/*!
 * jQuery UI Touch Punch 1.1.5 as modified by RWAP Software
 * based on original touchpunch v0.2.3 which has not been updated since 2014
 *
 * Updates by RWAP Software to take account of various suggested changes on the original code issues
 *
 * Original: https://github.com/furf/jquery-ui-touch-punch
 * Copyright 2011–2014, Dave Furfero
 * Dual licensed under the MIT or GPL Version 2 licenses.
 *
 * Fork: https://github.com/RWAP/jquery-ui-touch-punch
 *
 * Depends:
 * jquery.ui.widget.js
 * jquery.ui.mouse.js
 */

;(function (factory) {
  if (typeof define === 'function' && define.amd) {
    // AMD. Register as an anonymous module.
    define(['jquery', 'jquery-ui'], factory)
  } else {
    // Browser globals
    factory(jQuery)
  }
})(function ($) {
  // Detect touch support - Windows Surface devices and other touch devices
  $.mspointer = window.navigator.msPointerEnabled
  $.touch =
    'ontouchstart' in document ||
    'ontouchstart' in window ||
    window.TouchEvent ||
    (window.DocumentTouch && document instanceof DocumentTouch) ||
    navigator.maxTouchPoints > 0 ||
    navigator.msMaxTouchPoints > 0

  // Ignore browsers without touch or mouse support
  if ((!$.touch && !$.mspointer) || !$.ui.mouse) {
    return
  }

  let mouseProto = $.ui.mouse.prototype,
    _mouseInit = mouseProto._mouseInit,
    _mouseDestroy = mouseProto._mouseDestroy,
    touchHandled,
    lastClickTime = 0

  /**
   * Get the x,y position of a touch event
   * @param {Object} event A touch event
   */
  function getTouchCoords(event) {
    return {
      x: event.originalEvent.changedTouches[0].pageX,
      y: event.originalEvent.changedTouches[0].pageY,
    }
  }

  /**
   * Simulate a mouse event based on a corresponding touch event
   * @param {Object} event A touch event
   * @param {String} simulatedType The corresponding mouse event
   */
  function simulateMouseEvent(event, simulatedType) {
    // Ignore multi-touch events
    if (event.originalEvent.touches.length > 1) {
      return
    }

    // Ignore input or textarea elements so user can still enter text
    if ($(event.target).is('input') || $(event.target).is('textarea')) {
      return
    }

    // Prevent "Ignored attempt to cancel a touchmove event with cancelable=false" errors
    if (event.cancelable) {
      event.preventDefault()
    }

    const touch = event.originalEvent.changedTouches[0],
      simulatedEvent = new MouseEvent(simulatedType, {
        bubbles: true,
        cancelable: true,
        view: window,
        screenX: touch.screenX,
        screenY: touch.screenY,
        clientX: touch.clientX,
        clientY: touch.clientY,
      })

    // Dispatch the simulated event to the target element
    event.target.dispatchEvent(simulatedEvent)
  }

  /**
   * Handle the jQuery UI widget's touchstart events
   * @param {Object} event The widget element's touchstart event
   */
  mouseProto._touchStart = function (event) {
    const self = this

    // Interaction time
    this._startedMove = event.timeStamp

    // Track movement to determine if interaction was a click
    self._startPos = getTouchCoords(event)

    // Ignore the event if another widget is already being handled
    if (touchHandled || !self._mouseCapture(event.originalEvent.changedTouches[0])) {
      return
    }

    // Set the flag to prevent other widgets from inheriting the touch event
    touchHandled = true

    // Track movement to determine if interaction was a click
    self._touchMoved = false

    // Simulate the mouseover event
    simulateMouseEvent(event, 'mouseover')

    // Simulate the mousemove event
    simulateMouseEvent(event, 'mousemove')

    // Simulate the mousedown event
    simulateMouseEvent(event, 'mousedown')
  }

  /**
   * Handle the jQuery UI widget's touchmove events
   * @param {Object} event The document's touchmove event
   */
  mouseProto._touchMove = function (event) {
    // Ignore event if not handled
    if (!touchHandled) {
      return
    }

    // Interaction was moved
    this._touchMoved = true

    // Simulate the mousemove event
    simulateMouseEvent(event, 'mousemove')
  }

  /**
   * Handle the jQuery UI widget's touchend events
   * @param {Object} event The document's touchend event
   */
  mouseProto._touchEnd = function (event) {
    // Ignore event if not handled
    if (!touchHandled) {
      return
    }

    // Simulate the mouseup event
    simulateMouseEvent(event, 'mouseup')

    // Simulate the mouseout event
    simulateMouseEvent(event, 'mouseout')

    // If the touch interaction did not move, it should trigger a click
    // Check for this in two ways - length of time of simulation and distance moved
    // Allow for Apple Stylus to be used also
    const timeMoving = event.timeStamp - this._startedMove
    if (!this._touchMoved || timeMoving < 500) {
      // Simulate the click event
      if (event.timeStamp - lastClickTime < 400) simulateMouseEvent(event, 'dblclick')
      else simulateMouseEvent(event, 'click')
      lastClickTime = event.timeStamp
    } else {
      const endPos = getTouchCoords(event)
      if (
        Math.abs(endPos.x - this._startPos.x) < 10 &&
        Math.abs(endPos.y - this._startPos.y) < 10
      ) {
        // If the touch interaction did not move, it should trigger a click
        if (!this._touchMoved || event.originalEvent.changedTouches[0].touchType === 'stylus') {
          // Simulate the click event
          simulateMouseEvent(event, 'click')
        }
      }
    }

    // Unset the flag to determine the touch movement stopped
    this._touchMoved = false

    // Unset the flag to allow other widgets to inherit the touch event
    touchHandled = false
  }

  let _touchStartBound
  let _touchMoveBound
  let _touchEndBound

  /**
   * A duck punch of the $.ui.mouse _mouseInit method to support touch events.
   * This method extends the widget with bound touch event handlers that
   * translate touch events to mouse events and pass them to the widget's
   * original mouse event handling methods.
   */
  mouseProto._mouseInit = function () {
    const self = this

    // Microsoft Surface Support = remove original touch Action
    if ($.support.mspointer) {
      self.element[0].style.msTouchAction = 'none'
    }

    _touchStartBound = mouseProto._touchStart.bind(self)
    _touchMoveBound = mouseProto._touchMove.bind(self)
    _touchEndBound = mouseProto._touchEnd.bind(self)

    // Delegate the touch handlers to the widget's element
    self.element.on({
      touchstart: _touchStartBound,
      touchmove: _touchMoveBound,
      touchend: _touchEndBound,
    })

    // Call the original $.ui.mouse init method
    _mouseInit.call(self)
  }

  /**
   * Remove the touch event handlers
   */
  mouseProto._mouseDestroy = function () {
    const self = this

    // Delegate the touch handlers to the widget's element
    self.element.off({
      touchstart: _touchStartBound,
      touchmove: _touchMoveBound,
      touchend: _touchEndBound,
    })

    // Call the original $.ui.mouse destroy method
    _mouseDestroy.call(self)
  }
})
