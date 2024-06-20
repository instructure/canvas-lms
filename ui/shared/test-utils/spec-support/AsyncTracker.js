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

import {getStack, logCurrentContext, logTrackers} from './logging'

const SLOW_SPEC_LIMIT = 1500

const originalFunctions = {
  clearTimeout: window.clearTimeout,
  setTimeout: window.setTimeout,
}

export default class AsyncTracker {
  constructor(options) {
    this._options = options
    this._trackers = []
    this._currentContextTimer = null

    this._options.contextTracker.onContextStart(() => {
      this.setup()
    })

    this._options.contextTracker.onContextEnd(async () => {
      if (this._options.logUnmanagedBehavior !== false || this._options.failOnUnmanagedBehavior) {
        this.logUnmanagedBehavior()
      }

      switch (this._options.unmanagedBehaviorStrategy) {
        case 'wait':
          await this.behaviorResolved()
          break
        case 'hurry':
          await this.hurryUnmanagedBehavior()
          break
        case 'clear':
          this.clearUnmanagedBehavior()
          break
        case 'fail':
          this.failOnUnmanagedBehavior()
          break
        default:
      }

      this.teardown()
    })
  }

  setup() {
    const {contextTracker, debugging, unmanagedBehaviorStrategy} = this._options

    this._currentContextTimer = {}

    this._currentContextTimer.timeoutId = originalFunctions.setTimeout.call(
      window,
      () => {
        logTrackers(this._trackers, (type, trackersOfType) => ({
          logType: 'warn',
          message: `${trackersOfType.length} ${type}(s) have not yet resolved`,
        }))
      },
      SLOW_SPEC_LIMIT
    )

    this._currentContextTimer.clear = () => {
      originalFunctions.clearTimeout.call(window, this._currentContextTimer.timeoutId)
      this._currentContextTimer = null
    }

    const addTimeoutTracker = tracker => {
      this._trackers.push(tracker)
    }

    const removeTimeoutTracker = tracker => {
      this._trackers = this._trackers.filter(item => item !== tracker)
    }

    window.setTimeout = (callback, duration) => {
      const tracker = {
        currentContext: contextTracker.getCurrentContext(),
        duration,
        sourceStack: debugging ? getStack('setTimeout') : null,
        type: 'setTimeout',
      }

      addTimeoutTracker(tracker)

      const trackerCallback = () => {
        try {
          if (typeof callback !== 'function') {
            // TODO: remove this after figuring out why it is happening
            logCurrentContext(tracker.currentContext, {
              message: 'callback is not a function',
              sourceStack: tracker.sourceStack,
            })
          } else {
            callback()
          }
        } catch (e) {
          if (unmanagedBehaviorStrategy === 'wait' || unmanagedBehaviorStrategy === 'hurry') {
            tracker.currentContext.addCriticalFailure(
              'Unmanaged error in setTimeout callback',
              tracker
            )
          }
          throw e
        }
        removeTimeoutTracker(tracker)
      }

      tracker.clear = () => {
        originalFunctions.clearTimeout.call(window, tracker.timeoutId)
      }

      tracker.hurry = () => {
        originalFunctions.clearTimeout.call(window, tracker.timeoutId)
        try {
          trackerCallback()
        } catch (e) {
          // Any errors have already been dealt with, but might have been re-thrown.
        }
      }

      tracker.timeoutId = originalFunctions.setTimeout.call(window, trackerCallback, duration)

      return tracker.timeoutId
    }

    window.clearTimeout = timeoutId => {
      originalFunctions.clearTimeout.call(window, timeoutId)
      this._trackers = this._trackers.filter(tracker => tracker.timeoutId !== timeoutId)
    }
  }

  teardown() {
    window.clearTimeout = originalFunctions.clearTimeout
    window.setTimeout = originalFunctions.setTimeout
    this._trackers = []
    this._currentContextTimer.clear()
  }

  logUnmanagedBehavior() {
    logTrackers(this._trackers, (type, trackersOfType) => ({
      logType: this._options.unmanagedBehaviorStrategy === 'fail' ? 'error' : 'warn',
      message: `${trackersOfType.length} ${type}(s) did not resolve before the test completed`,
    }))
  }

  failOnUnmanagedBehavior() {
    if (this._trackers.length > 0) {
      // If this condition is ever met, the offending code MUST be fixed.
      const [tracker] = this._trackers
      tracker.currentContext.addFailure(
        'Async behavior must resolve before tests complete',
        tracker
      )
      this.clearUnmanagedBehavior()
    }
  }

  async hurryUnmanagedBehavior() {
    return new Promise(resolve => {
      const waits = []

      const maybeResolve = () => {
        if (this._trackers.length === 0) {
          resolve()
          return
        }

        if (waits.length > 2) {
          // Something keeps adding more timeouts. We have waited long enough.
          this.clearUnmanagedBehavior()
          resolve()
          return
        }

        // Sort the timeouts so that the shortest are handled first.
        const sortedTrackers = [...this._trackers].sort((a, b) => a.duration - b.duration)
        sortedTrackers.forEach(tracker => tracker.hurry())
        originalFunctions.setTimeout.call(window, maybeResolve, 0)
      }

      maybeResolve()
    })
  }

  clearUnmanagedBehavior() {
    this._trackers.forEach(tracker => {
      tracker.clear()
    })
    this._trackers = []
  }

  async behaviorResolved() {
    return new Promise(resolve => {
      const waits = []

      const maybeResolve = () => {
        if (this._trackers.length === 0) {
          resolve()
          return
        }

        if (waits.length > 2) {
          // Something keeps adding more timeouts. We have waited long enough.
          this.clearUnmanagedBehavior()
          resolve()
          return
        }

        const durations = this._trackers.map(tracker => tracker.duration)
        const highestDuration = Math.max(...durations)
        waits.push(highestDuration)
        const totalWait = waits.reduce((sum, duration) => sum + duration, 0)

        if (totalWait >= 1000) {
          // These timeouts are huge. Ain't nobody got time for that.
          this.clearUnmanagedBehavior()
          resolve()
          return
        }

        // Keep waiting to see if these async calls resolve.
        originalFunctions.setTimeout.call(window, maybeResolve, highestDuration)
      }

      maybeResolve()
    })
  }
}

// TODO: detect when the method has been swapped and not restored
// TODO: detect ajax
