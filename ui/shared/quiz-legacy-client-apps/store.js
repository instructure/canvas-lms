/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {assignIn} from 'lodash'

const Store = function (key, proto, Dispatcher) {
  const emitChange = this.emitChange.bind(this)

  assignIn(this, proto || {})

  this._key = key
  this.__reset__()

  Object.keys(this.actions).forEach(
    function (action) {
      const handler = this.actions[action].bind(this)
      const scopedAction = [key, action].join(':')

      Dispatcher.register(scopedAction, function (params, resolve, reject) {
        try {
          handler(
            params,
            function onChange(rc) {
              resolve(rc)
              emitChange()
            },
            reject
          )
        } catch (e) {
          reject(e)
        }
      })
    }.bind(this)
  )

  return this
}

assignIn(Store.prototype, {
  actions: {},
  addChangeListener(callback) {
    this._callbacks.push(callback)
  },

  removeChangeListener(callback) {
    const index = this._callbacks.indexOf(callback)
    if (index > -1) {
      this._callbacks.splice(index, 1)
    }
  },

  emitChange() {
    this._callbacks.forEach(function (callback) {
      callback()
    })
  },

  /**
   * @private
   *
   * A hook for tests to reset the Store to its initial state. Override this
   * to restore any side-effects.
   *
   * Usually during the life-time of the app, we will never have to reset a
   * Store, but in tests we do.
   */
  __reset__() {
    this._callbacks = []
    this.state = this.getInitialState()
  },

  getInitialState() {
    return {}
  },

  setState(newState) {
    assignIn(this.state, newState)
    this.emitChange()
  },
})

export default Store
