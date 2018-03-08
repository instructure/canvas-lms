/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

define(function(require) {
  var _ = require('lodash')
  var extend = _.extend

  var Store = function(key, proto, Dispatcher) {
    var emitChange = this.emitChange.bind(this)

    extend(this, proto || {})

    this._key = key
    this.__reset__()

    Object.keys(this.actions).forEach(
      function(action) {
        var handler = this.actions[action].bind(this)
        var scopedAction = [key, action].join(':')

        // console.debug('Store action:', scopedAction);

        Dispatcher.register(scopedAction, function(params, resolve, reject) {
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

  extend(Store.prototype, {
    actions: {},
    addChangeListener: function(callback) {
      this._callbacks.push(callback)
    },

    removeChangeListener: function(callback) {
      var index = this._callbacks.indexOf(callback)
      if (index > -1) {
        this._callbacks.splice(index, 1)
      }
    },

    emitChange: function() {
      this._callbacks.forEach(function(callback) {
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
    __reset__: function() {
      this._callbacks = []
      this.state = this.getInitialState()
    },

    getInitialState: function() {
      return {}
    },

    setState: function(newState) {
      extend(this.state, newState)
      this.emitChange()
    }
  })

  return Store
})
