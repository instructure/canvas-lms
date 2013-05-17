#
# * jquery.simulate - simulate browser mouse and keyboard events
# *
# * Copyright 2011, AUTHORS.txt (http://jqueryui.com/about)
# * Dual licensed under the MIT or GPL Version 2 licenses.
# * http://jquery.org/license
# *
# * converted to coffeescript by instructure
define ["jquery"], ($) ->
  $.fn.extend simulate: (type, options) ->
    @each ->
      opt = $.extend({}, $.simulate.defaults, options)
      new $.simulate(this, type, opt)

  $.simulate = (el, type, options) ->
    @target = el
    @options = options
    if type is "drag"
      this[type].apply this, [@target, options]
    else if type is "focus" or type is "blur"
      this[type]()
    else
      @simulateEvent el, type, options

  $.extend $.simulate::,
    simulateEvent: (el, type, options) ->
      evt = @createEvent(type, options)
      @dispatchEvent el, type, evt, options
      evt

    createEvent: (type, options) ->
      if /^mouse(over|out|down|up|move)|(dbl)?click$/.test(type)
        @mouseEvent type, options
      else @keyboardEvent type, options  if /^key(up|down|press)$/.test(type)

    mouseEvent: (type, options) ->
      evt = undefined
      e = $.extend(
        bubbles: true
        cancelable: (type isnt "mousemove")
        view: window
        detail: 0
        screenX: 0
        screenY: 0
        clientX: 0
        clientY: 0
        ctrlKey: false
        altKey: false
        shiftKey: false
        metaKey: false
        button: 0
        relatedTarget: `undefined`
      , options)
      relatedTarget = $(e.relatedTarget)[0]
      if $.isFunction(document.createEvent)
        evt = document.createEvent("MouseEvents")
        evt.initMouseEvent type, e.bubbles, e.cancelable, e.view, e.detail, e.screenX, e.screenY, e.clientX, e.clientY, e.ctrlKey, e.altKey, e.shiftKey, e.metaKey, e.button, e.relatedTarget or document.body.parentNode
      else if document.createEventObject
        evt = document.createEventObject()
        $.extend evt, e
        evt.button = {0:1, 1:4, 2: 2}[evt.button] or evt.button
      evt

    keyboardEvent: (type, options) ->
      evt = undefined
      e = $.extend(
        bubbles: true
        cancelable: true
        view: window
        ctrlKey: false
        altKey: false
        shiftKey: false
        metaKey: false
        keyCode: 0
        charCode: `undefined`
      , options)
      if $.isFunction(document.createEvent)
        try
          evt = document.createEvent("KeyEvents")
          evt.initKeyEvent type, e.bubbles, e.cancelable, e.view, e.ctrlKey, e.altKey, e.shiftKey, e.metaKey, e.keyCode, e.charCode
        catch err
          evt = document.createEvent("Events")
          evt.initEvent type, e.bubbles, e.cancelable
          $.extend evt,
            view: e.view
            ctrlKey: e.ctrlKey
            altKey: e.altKey
            shiftKey: e.shiftKey
            metaKey: e.metaKey
            keyCode: e.keyCode
            charCode: e.charCode

      else if document.createEventObject
        evt = document.createEventObject()
        $.extend evt, e
      if $.browser.msie or $.browser.opera
        evt.keyCode = (if (e.charCode > 0) then e.charCode else e.keyCode)
        evt.charCode = `undefined`
      evt

    dispatchEvent: (el, type, evt) ->
      if el.dispatchEvent
        el.dispatchEvent evt
      else el.fireEvent "on" + type, evt  if el.fireEvent
      evt

    drag: (el) ->
      self = this
      center = @findCenter(@target)
      options = @options
      x = Math.floor(center.x)
      y = Math.floor(center.y)
      dx = options.dx or 0
      dy = options.dy or 0
      target = @target
      coord =
        clientX: x
        clientY: y

      @simulateEvent target, "mousedown", coord
      coord =
        clientX: x + 1
        clientY: y + 1

      @simulateEvent document, "mousemove", coord
      coord =
        clientX: x + dx
        clientY: y + dy

      @simulateEvent document, "mousemove", coord
      @simulateEvent document, "mousemove", coord
      @simulateEvent target, "mouseup", coord
      @simulateEvent target, "click", coord

    findCenter: (el) ->
      el = $(@target)
      o = el.offset()
      d = $(document)
      x: o.left + el.outerWidth() / 2 - d.scrollLeft()
      y: o.top + el.outerHeight() / 2 - d.scrollTop()

    focus: ->
      trigger = ->
        triggered = true
      focusinEvent = undefined
      triggered = false
      element = $(@target)
      element.bind "focus", trigger
      element[0].focus()
      unless triggered
        focusinEvent = $.Event("focusin")
        focusinEvent.preventDefault()
        element.trigger focusinEvent
        element.triggerHandler "focus"
      element.unbind "focus", trigger

    blur: ->
      trigger = ->
        triggered = true
      focusoutEvent = undefined
      triggered = false
      element = $(@target)
      element.bind "blur", trigger
      element[0].blur()

      # blur events are async in IE
      setTimeout (->

        # IE won't let the blur occur if the window is inactive
        element[0].ownerDocument.body.focus()  if element[0].ownerDocument.activeElement is element[0]

        # Firefox won't trigger events if the window is inactive
        # IE doesn't trigger events if we had to manually focus the body
        unless triggered
          focusoutEvent = $.Event("focusout")
          focusoutEvent.preventDefault()
          element.trigger focusoutEvent
          element.triggerHandler "blur"
        element.unbind "blur", trigger
      ), 1

  $.extend $.simulate,
    defaults:
      speed: "sync"

    VK_TAB: 9
    VK_ENTER: 13
    VK_ESC: 27
    VK_PGUP: 33
    VK_PGDN: 34
    VK_END: 35
    VK_HOME: 36
    VK_LEFT: 37
    VK_UP: 38
    VK_RIGHT: 39
    VK_DOWN: 40

