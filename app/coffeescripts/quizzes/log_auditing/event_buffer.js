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

import K from './constants'
import QuizEvent from './event'
import QuizEventSet from './event_set'
import debugConsole from '../../util/debugConsole'

const STORAGE_ADAPTERS = [K.EVT_STORAGE_MEMORY, K.EVT_STORAGE_LOCAL_STORAGE]

// The buffer is basically where we're storing the captured events pending
// delivery. The buffer tries to act like an array although it isn't one, but
// the API should feel familiar.
//
// The buffer could also be configured with different storage adapters; memory
// or localStorage. See #setStorageAdapter for configuring it.
export default class EventBuffer {
  static setStorageAdapter(adapter) {
    if (STORAGE_ADAPTERS.indexOf(adapter) === -1) {
      throw new Error(`\
Unsupported storage adapter "${adapter}". Available adapters are:
${STORAGE_ADAPTERS.join(', ')}\
`)
    }

    return (EventBuffer.STORAGE_ADAPTER = adapter)
  }

  // Load from localStorage on creation if available.
  constructor() {
    this.useLocalStorage = EventBuffer.STORAGE_ADAPTER === K.EVT_STORAGE_LOCAL_STORAGE
    this._events = this._load() || []

    debugConsole.debug('EventBuffer: using', this.constructor.STORAGE_ADAPTER, 'for storage')
  }

  // Add an event to the buffer and update persisted state if available.
  push(event) {
    this._events.push(event)
    return this._save()
  }

  isEmpty() {
    return this._events.length === 0
  }

  getLength() {
    return this._events.length
  }

  // @return {EventSet}
  filter(callback) {
    return new QuizEventSet(this._events.filter(callback))
  }

  // Remove events in a set from the buffer. Usually you'd use this after
  // delivering the events that were pending delivery.
  //
  // @param {EventSet} eventSet
  discard(eventSet) {
    const ids = eventSet._events.map(event => event._id)

    this._events = this._events.filter(event => ids.indexOf(event._id) === -1)

    this._save()

    return undefined
  }

  // Serialize the buffer.
  toJSON() {
    return this._events.map(event => event.toJSON())
  }

  _save() {
    if (this.useLocalStorage) {
      try {
        localStorage.setItem(K.EVT_STORAGE_KEY, JSON.stringify(this.toJSON()))
      } catch (e) {
        debugConsole.warn(`\
Unable to save to localStorage, likely because we're out of space.\
`)
      }
    }

    return undefined
  }

  _load() {
    if (this.useLocalStorage) {
      const jsonEvents = JSON.parse(localStorage.getItem(K.EVT_STORAGE_KEY) || '[]')
      return jsonEvents.map(descriptor => QuizEvent.fromJSON(descriptor))
    } else {
      return undefined
    }
  }
}
EventBuffer.STORAGE_ADAPTER = K.EVT_STORAGE_MEMORY
