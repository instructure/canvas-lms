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

async function ensure(tryFn, alwaysFn) {
  let error, value
  try {
    value = await tryFn()
  } catch (e) {
    error = e
  }
  await alwaysFn()
  if (error) {
    throw error
  }
  return value
}

export default class ContextTracker {
  constructor(qunit) {
    this._qunit = qunit
    this._stack = []
    this._contextCallbacks = {
      beforeContextEnd: [],
      onContextEnd: [],
      onContextStart: []
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
            message
          }))
        })
      },

      stack
    }
  }

  setup() {
    this._qunit.begin(() => {
      const {beforeContextEnd, onContextStart, onContextEnd} = this._contextCallbacks

      this._qunit.config.modules.forEach(module => {
        if (!module.parentModule) {
          module.testEnvironment = module.testEnvironment || {} // eslint-disable-line no-param-reassign
          const {testEnvironment} = module

          const beforeEach = testEnvironment.beforeEach
          const afterEach = testEnvironment.afterEach

          testEnvironment.beforeEach = async function() {
            for (let i = 0; i < onContextStart.length; i++) {
              await onContextStart[i]() // eslint-disable-line no-await-in-loop
            }
            if (beforeEach) {
              await beforeEach.call(this)
            }
          }

          testEnvironment.afterEach = async function() {
            await ensure(
              async () => {
                for (let i = 0; i < beforeContextEnd.length; i++) {
                  await beforeContextEnd[i]() // eslint-disable-line no-await-in-loop
                }
                if (afterEach) {
                  await afterEach.call(this)
                }
              },
              async () => {
                for (let i = 0; i < onContextEnd.length; i++) {
                  await onContextEnd[i]() // eslint-disable-line no-await-in-loop
                }
              }
            )
          }
        }
      })
    })

    this._qunit.moduleStart(moduleInfo => {
      this._stack.push({description: moduleInfo.name, failures: [], type: 'module'})
    })

    this._qunit.testStart(testInfo => {
      this._stack.push({description: testInfo.name, failures: [], type: 'test'})
    })

    this._qunit.testDone(() => {
      this._stack.pop()
    })

    this._qunit.moduleDone(() => {
      this._stack.pop()
    })
  }
}
