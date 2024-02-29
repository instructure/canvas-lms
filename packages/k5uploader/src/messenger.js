/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

Messenger.decorate = function (instance) {
  instance.messenger = new Messenger()
  instance.addEventListener = function (eventName, method) {
    instance.messenger.addEventListener(eventName, method)
  }
  instance.dispatchEvent = function (eventName, data, context) {
    instance.messenger.dispatchEvent(eventName, data, context)
  }
  instance.removeEventListener = function (eventName, targetMethod) {
    instance.messenger.removeEventListener(eventName, targetMethod)
  }
}

function Messenger() {
  this.events = {}
}

Messenger.prototype.killAllListeners = function (eventName) {
  if (this.events[eventName]) {
    this.events[eventName] = []
  } else {
    return false
  }
}

Messenger.prototype.destroy = function () {
  this.events = {}
}

Messenger.prototype.dispatchEvent = function (eventName, data, context) {
  if (this.events[eventName]) {
    this.events[eventName].forEach(eventHandler => {
      eventHandler.call(context, data)
    })
  }
}

Messenger.prototype.addEventListener = function (eventName, method) {
  if (!method) {
    return false
  }
  if (!this.events[eventName]) {
    this.events[eventName] = []
  }
  this.events[eventName].push(method)
  return method
}

Messenger.prototype.removeEventListener = function (eventName, targetMethod) {
  if (this.events[eventName]) {
    const eventHandlers = this.events[eventName]
    const removalQueue = []
    this.events[eventName].forEach((eventHandler, index) => {
      if (eventHandler === targetMethod) {
        removalQueue.push(index)
      }
    })
    if (removalQueue.length > 0) {
      removalQueue.forEach(element => {
        eventHandlers.splice(element, 1)
      })
    }
  }
}

export default Messenger
