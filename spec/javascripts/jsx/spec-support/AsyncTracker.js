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

const originalFunctions = {
  clearTimeout: window.clearTimeout,
  setTimeout: window.setTimeout
}

export default class AsyncTracker {
  constructor(options) {
    this._options = options
    this._trackers = []

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
        type: 'setTimeout'
      }

      addTimeoutTracker(tracker)

      tracker.clear = () => {
        originalFunctions.clearTimeout.call(window, tracker.timeoutId)
      }

      tracker.hurry = () => {
        originalFunctions.clearTimeout.call(window, tracker.timeoutId)
        tracker.listener()
      }

      tracker.timeoutId = originalFunctions.setTimeout.call(
        window,
        function() {
          try {
            if (typeof callback !== 'function') {
              // TODO: remove this after figuring out why it is happening
              logCurrentContext(tracker.currentContext, {
                message: 'callback is not a function',
                sourceStack: tracker.sourceStack
              })
            } else {
              callback()
            }
          } catch (e) {
            if (unmanagedBehaviorStrategy === 'wait') {
              tracker.currentContext.addCriticalFailure(
                'Unmanaged error in setTimeout callback',
                tracker
              )
            }
          }
          removeTimeoutTracker(tracker)
        },
        duration
      )

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
  }

  logUnmanagedBehavior() {
    logTrackers(this._trackers, (type, trackersOfType) => ({
      logType: this._options.unmanagedBehaviorStrategy === 'fail' ? 'error' : 'warn',
      message: `${trackersOfType.length} ${type}(s) did not resolve before the test completed`
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
      const maybeResolve = () => {
        if (this._trackers.length === 0) {
          resolve()
        } else {
          const sortedTrackers = [...this._trackers].sort((a, b) => a.duration - b.duration)
          sortedTrackers.forEach(tracker => tracker.hurry())
        }
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
      const maybeResolve = () => {
        if (this._trackers.length === 0) {
          resolve()
        } else {
          const durations = this._trackers.map(tracker => tracker.duration)
          const highestDuration = Math.max(...durations)
          originalFunctions.setTimeout.call(window, maybeResolve, highestDuration)
        }
      }
      maybeResolve()
    })
  }
}

// TODO: detect when the method has been swapped and not restored
// TODO: detect ajax
