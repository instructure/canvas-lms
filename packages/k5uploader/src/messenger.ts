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

type EventHandler = (data: unknown) => void

// Define an interface for the expected structure of the instance
interface MessengerDecorated {
  messenger: Messenger
  addEventListener(eventName: string, method: EventHandler): void
  dispatchEvent(eventName: string, data: unknown, context: unknown): void
  removeEventListener(eventName: string, targetMethod: EventHandler): void
}

class Messenger {
  private events: {[key: string]: EventHandler[]} = {}

  killAllListeners(eventName: string): boolean {
    if (this.events[eventName]) {
      this.events[eventName] = []
      return true
    }
    return false
  }

  destroy(): void {
    this.events = {}
  }

  dispatchEvent(eventName: string, data: unknown, context: unknown): void {
    if (this.events[eventName]) {
      this.events[eventName].forEach(eventHandler => {
        eventHandler.call(context, data)
      })
    }
  }

  addEventListener(eventName: string, method: EventHandler): EventHandler | false {
    if (!method) {
      return false
    }
    if (!this.events[eventName]) {
      this.events[eventName] = []
    }
    this.events[eventName].push(method)
    return method
  }

  removeEventListener(eventName: string, targetMethod: EventHandler): void {
    if (this.events[eventName]) {
      const eventHandlers = this.events[eventName]
      const removalQueue: number[] = []
      this.events[eventName].forEach((eventHandler, index) => {
        if (eventHandler === targetMethod) {
          removalQueue.push(index)
        }
      })
      if (removalQueue.length > 0) {
        removalQueue.forEach(index => {
          eventHandlers.splice(index, 1)
        })
      }
    }
  }
}

function decorateMessenger(instance: MessengerDecorated): void {
  instance.messenger = new Messenger()
  instance.addEventListener = function (eventName: string, method: EventHandler): void {
    instance.messenger.addEventListener(eventName, method)
  }
  instance.dispatchEvent = function (eventName: string, data: unknown, context: unknown): void {
    instance.messenger.dispatchEvent(eventName, data, context)
  }
  instance.removeEventListener = function (eventName: string, targetMethod: EventHandler): void {
    instance.messenger.removeEventListener(eventName, targetMethod)
  }
}

export default Messenger
export {decorateMessenger}
