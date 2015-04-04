define [
  'react'
  'react-router'
], (React, ReactRouter) ->
  'use strict'
  _prototypeProperties = (child, staticProps, instanceProps) ->
    if staticProps
      Object.defineProperties child, staticProps
    if instanceProps
      Object.defineProperties child.prototype, instanceProps
    return

  _classCallCheck = (instance, Constructor) ->
    if !(instance instanceof Constructor)
      throw new TypeError('Cannot call a class as a function')
    return

  invariant = ReactRouter.invariant
  LocationActions = ReactRouter.LocationActions
  History = ReactRouter.History

  ###*
  # A location that is convenient for testing and does not require a DOM.
  ###

  TestLocation = do ->
    `var TestLocation`

    TestLocation = (history) ->
      _classCallCheck this, TestLocation
      @history = history or []
      @listeners = []
      @_updateHistoryLength()
      return

    _prototypeProperties TestLocation, null,
      needsDOM:
        get: ->
          false
        configurable: true
      _updateHistoryLength:
        value: ->
          History.length = @history.length
          return
        writable: true
        configurable: true
      _notifyChange:
        value: (type) ->
          change =
            path: @getCurrentPath()
            type: type
          i = 0
          len = @listeners.length
          while i < len
            @listeners[i].call this, change
            ++i
          return
        writable: true
        configurable: true
      addChangeListener:
        value: (listener) ->
          @listeners.push listener
          return
        writable: true
        configurable: true
      removeChangeListener:
        value: (listener) ->
          @listeners = @listeners.filter((l) ->
            l != listener
          )
          return
        writable: true
        configurable: true
      push:
        value: (path) ->
          @history.push path
          @_updateHistoryLength()
          @_notifyChange LocationActions.PUSH
          return
        writable: true
        configurable: true
      replace:
        value: (path) ->
          invariant @history.length, 'You cannot replace the current path with no history'
          @history[@history.length - 1] = path
          @_notifyChange LocationActions.REPLACE
          return
        writable: true
        configurable: true
      pop:
        value: ->
          @history.pop()
          @_updateHistoryLength()
          @_notifyChange LocationActions.POP
          return
        writable: true
        configurable: true
      getCurrentPath:
        value: ->
          @history[@history.length - 1]
        writable: true
        configurable: true
      toString:
        value: ->
          '<TestLocation>'
        writable: true
        configurable: true
    TestLocation