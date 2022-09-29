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

const callbacks = {}
let gActionIndex = 0

const Dispatcher = function (inputConfig) {
  this.config = inputConfig
}

Dispatcher.prototype.dispatch = function (action, params) {
  return new Promise((resolve, reject) => {
    const actionIndex = ++gActionIndex
    const callback = callbacks[action]

    if (callback) {
      callback(params, resolve, reject)
    } else {
      reject(new Error('Unknown action "' + action + '"'))
    }

    return actionIndex
  })
}

Dispatcher.prototype.register = function (action, callback) {
  if (callbacks[action]) {
    throw new Error("A handler is already registered to '" + action + "'")
  }

  callbacks[action] = callback

  return callback
}

Dispatcher.prototype.clear = function () {
  for (const action of Object.keys(callbacks)) {
    callbacks[action] = null
  }
}

export default Dispatcher
