/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

type EventType = 'message'
type Callback = (event: {data: any}) => void

let messageListeners: Callback[] = []

export default class MockBroadcastChannel {
  private channel: string

  private listeners: Callback[]

  constructor(channel: string) {
    this.channel = channel
    this.listeners = []
  }

  postMessage(message: any): void {
    this.listeners.forEach(listener => listener({data: message}))
  }

  onmessage: Callback | null = null

  addEventListener(type: EventType, callback: Callback): void {
    if (type === 'message') {
      this.listeners.push(callback)
      messageListeners.push(callback)
    }
  }

  removeEventListener(type: EventType, callback: Callback): void {
    if (type === 'message') {
      this.listeners = this.listeners.filter(listener => listener !== callback)
      messageListeners = messageListeners.filter(listener => listener !== callback)
    }
  }

  close(): void {
    this.listeners.forEach(listener => {
      const index = messageListeners.indexOf(listener)
      if (index !== -1) {
        messageListeners.splice(index, 1)
      }
    })

    this.listeners = []
  }
}
