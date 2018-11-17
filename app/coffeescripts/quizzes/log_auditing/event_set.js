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

// # A convenience wrapper for an array of quiz events that allows us to operate
// # on all contained events.
// #
// # You don't create sets directly, instead, the EventBuffer API may return
// # these objects when appropriate.
export default class EventSet {
  constructor(events) {
    this._events = events
  }

  isEmpty() {
    return this._events.length === 0
  }

  markPendingDelivery() {
    return this._events.forEach(event => (event._state = K.EVT_STATE_PENDING_DELIVERY))
  }

  markBeingDelivered() {
    return this._events.forEach(event => (event._state = K.EVT_STATE_IN_DELIVERY))
  }

  // Serialize the set of events, ready for transmission to the API.
  toJSON() {
    return this._events.map(event => event.toJSON())
  }
}
