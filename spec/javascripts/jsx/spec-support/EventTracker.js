/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import {getStack, logTrackers} from './logging'

const NATIVE_CODE_REGEX = /\[native code\]/

const originalFunctions = {
  addEventListener: window.addEventListener,
  removeEventListener: window.removeEventListener
}

function matchOptionsOrUseCapture(a, b) {
  if (typeof a === 'object' && typeof b === 'object') {
    return !Object.keys({...a, ...b}).some(key => a[key] !== b[key])
  }
  return a === b
}

export default class EventTracker {
  constructor(options) {
    this._options = options
    this._trackers = {
      eventListeners: []
    }

    this._options.contextTracker.onContextStart(() => {
      this.setup()
    })

    this._options.contextTracker.onContextEnd(() => {
      if (options.logUnmanagedListeners !== false || options.failOnUnmanagedListeners) {
        this.logUnmanagedListeners(this._trackers)
      }

      switch (this._options.unmanagedListenerStrategy) {
        case 'remove':
          this.removeUnmanagedListeners()
          break
        case 'fail':
          this.failOnUnmanagedListeners()
          break
        default:
      }

      this.teardown()
    })
  }

  setup() {
    window.addEventListener = this.wrapAddEventListener()
    window.removeEventListener = this.wrapRemoveEventListener()
  }

  teardown() {
    this._trackers.eventListeners = []
    window.addEventListener = originalFunctions.addEventListener
    window.removeEventListener = originalFunctions.removeEventListener
  }

  logUnmanagedListeners() {
    const eventNames = []
    this._trackers.eventListeners.forEach(listener => {
      if (eventNames.indexOf(listener.eventName) === -1) {
        eventNames.push(listener.eventName)
      }
    })
    logTrackers(this._trackers.eventListeners, (type, trackersOfType) => ({
      logType: this._options.unmanagedListenerStrategy === 'fail' ? 'error' : 'warn',
      message: [
        `${trackersOfType.length} ${type}(s) were not removed before the test completed`,
        `Event name(s): [${eventNames.join(', ')}]`
      ]
    }))
  }

  removeUnmanagedListeners() {
    const listeners = [...this._trackers.eventListeners]
    listeners.forEach(eventListener => {
      eventListener.remove()
    })
  }

  failOnUnmanagedListeners() {
    if (this._trackers.eventListeners.length > 0) {
      // If this condition is ever met, the offending code MUST be fixed.
      const [tracker] = this._trackers.eventListeners
      tracker.currentContext.addFailure(
        'Event handlers must be removed before tests complete',
        tracker
      )
      this.removeUnmanagedListeners()
    }
  }

  wrapAddEventListener() {
    const trackers = this._trackers
    const {contextTracker, debugging} = this._options

    return function trackedAddEventListener(eventName, listener, optionsOrUseCapture) {
      if (NATIVE_CODE_REGEX.test(String(listener))) {
        // Native code is not from Canvas and should be ignored
        return
      }

      const currentContext = contextTracker.getCurrentContext()

      const tracker = {
        currentContext,
        eventName,
        optionsOrUseCapture,
        originalListener: listener,
        sourceStack: debugging ? getStack(`"${eventName}" event listener`) : null,
        type: 'event listener'
      }

      tracker.listener = function(...args) {
        try {
          listener(...args)
        } catch (error) {
          tracker.currentContext.addCriticalFailure(
            `Unmanaged error in '${eventName}' event listener`,
            tracker
          )
        }
      }

      tracker.remove = () => {
        const index = trackers.eventListeners.indexOf(tracker)
        trackers.eventListeners.splice(index, 1)
        originalFunctions.removeEventListener.call(
          window,
          eventName,
          tracker.listener,
          optionsOrUseCapture
        )
      }

      trackers.eventListeners.push(tracker)
      originalFunctions.addEventListener.call(
        window,
        eventName,
        tracker.listener,
        optionsOrUseCapture
      )
    }
  }

  wrapRemoveEventListener() {
    const {eventListeners} = this._trackers

    return function trackedRemoveEventListener(eventName, listener, optionsOrUseCapture) {
      const tracker = eventListeners.find(
        eventListener =>
          eventListener.originalListener === listener &&
          eventListener.eventName === eventName &&
          matchOptionsOrUseCapture(eventListener.optionsOrUseCapture, optionsOrUseCapture)
      )

      if (tracker) {
        tracker.remove()
      }
    }
  }
}
