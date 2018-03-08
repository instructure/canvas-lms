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
  var RSVP = require('rsvp')
  var singleton
  var callbacks = {}
  var gActionIndex = 0

  var Dispatcher = function(inputConfig) {
    this.config = inputConfig
  }

  Dispatcher.prototype.dispatch = function(action, params) {
    var service = RSVP.defer()
    var actionIndex = ++gActionIndex
    var callback = callbacks[action]

    if (callback) {
      callback(params, service.resolve, service.reject)
    } else {
      console.assert(false, 'No action handler registered to:', action)
      this.config.onError('No action handler registered to:', action)
      service.reject('Unknown action "' + action + '"')
    }

    return {
      promise: service.promise,
      index: actionIndex
    }
  }

  Dispatcher.prototype.register = function(action, callback) {
    if (callbacks[action]) {
      throw new Error("A handler is already registered to '" + action + "'")
    }

    callbacks[action] = callback
  }

  return Dispatcher
})
