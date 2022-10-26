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

import {logTrackers} from './logging'

// this will exhaustively run every fn in arrayOfFunctions one at a time,
// waiting for the previous to fulfill if it is a promise
function runAllOneAtATime(arrayOfFunctions) {
  function run(i) {
    if (i < arrayOfFunctions.length) {
      return Promise.resolve(arrayOfFunctions[i]()).then(() => run(i + 1))
    } else {
      return Promise.resolve()
    }
  }
  return run(0)
}

export default class ContextTracker {
  constructor(qunit) {
    this._qunit = qunit
    this._stack = []
    this._contextCallbacks = {
      beforeContextEnd: [],
      onContextEnd: [],
      onContextStart: [],
    }
  }

  beforeContextEnd(callback) {
    this._contextCallbacks.beforeContextEnd.push(callback)
  }

  onContextStart(callback) {
    this._contextCallbacks.onContextStart.push(callback)
  }

  onContextEnd(callback) {
    this._contextCallbacks.onContextEnd.push(callback)
  }

  getCurrentContextStack() {
    return this._stack.map(entry => ({...entry}))
  }

  getCurrentContext() {
    const test = this._qunit.config.current
    const stack = this._stack.map(entry => ({...entry}))

    const maybeAddFailure = (message, sourceStack, callback = () => {}) => {
      const top = stack[stack.length - 1]
      if (!top.failures.some(failure => failure.message === message)) {
        top.failures.push({message, sourceStack})
        test.pushFailure(message, sourceStack)

        callback()
      }
    }

    return {
      addFailure(message, tracker) {
        maybeAddFailure(message, tracker.sourceStack)
      },

      addCriticalFailure(message, tracker) {
        maybeAddFailure(message, tracker.sourceStack, () => {
          logTrackers([tracker], () => ({
            logType: 'error',
            message,
          }))
        })
      },

      getTimeElapsed() {
        return stack.length ? new Date() - stack[0].startTime : 0
      },

      stack,
    }
  }

  setup() {
    this._qunit.begin(() => {
      const {beforeContextEnd, onContextStart, onContextEnd} = this._contextCallbacks

      this._qunit.config.modules.forEach(module => {
        if (!module.parentModule) {
          module.testEnvironment = module.testEnvironment || {}
          const {testEnvironment} = module

          const {beforeEach, afterEach} = testEnvironment

          testEnvironment.beforeEach = function () {
            return runAllOneAtATime(onContextStart).then(() => {
              if (beforeEach) return beforeEach.call(this)
            })
          }

          testEnvironment.afterEach = function () {
            return runAllOneAtATime(beforeContextEnd)
              .then(() => {
                if (afterEach) return afterEach.call(this)
              })
              .finally(() => runAllOneAtATime(onContextEnd))
          }
        }
      })
    })

    this._qunit.moduleStart(moduleInfo => {
      this._stack.push({
        description: moduleInfo.name,
        failures: [],
        startTime: new Date(),
        type: 'module',
      })
    })

    this._qunit.testStart(testInfo => {
      this._stack.push({
        description: testInfo.name,
        failures: [],
        startTime: new Date(),
        type: 'test',
      })
    })

    this._qunit.testDone(() => {
      this._stack.pop()
    })

    this._qunit.moduleDone(() => {
      this._stack.pop()
    })
  }
}
