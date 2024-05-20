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
import EventBuffer from './event_buffer'
import {ajax, when as jWhen} from 'jquery'
import eraseFromArray from '@canvas/array-erase'
import debugConsole from './util/debugConsole'

const JSON_HEADERS = {
  Accept: 'application/json; charset=UTF-8',
  'Content-Type': 'application/json; charset=UTF-8',
}

export default class EventManager {
  constructor(options = {}) {
    this.options = {...EventManager.options, ...options}
    this._trackerFactories = []
    this._state = {
      trackers: [],
      buffer: null,
      deliveryAgent: null,
      deliveries: [],
      lastEventType: null,
    }
  }

  registerTracker(trackerFactory) {
    return this._trackerFactories.push(trackerFactory)
  }

  // Install all the event trackers and start the event buffer consumer.
  //
  // EventTracker instances will be provided with a deliveryCallback that
  // enqueues events for delivery via this module.

  unregisterAllTrackers() {
    return (this._trackerFactories = [])
  }

  start() {
    const state = this._state
    state.buffer = new EventBuffer()
    const {options} = this
    const enqueue = this._enqueue.bind(this)

    function deliveryCallback(tracker, eventData) {
      const event = new QuizEvent(tracker.getEventType(), eventData)
      return enqueue(event, tracker.getDeliveryPriority())
    }

    // generate tracker instances
    state.trackers = this._trackerFactories.map(Factory => {
      const tracker = new Factory()
      tracker.install(deliveryCallback.bind(null, tracker))
      return tracker
    })

    if (options.autoDeliver) {
      return this._startDeliveryAgent()
    }
  }

  // Are we collecting and delivering events?
  isRunning() {
    return !!this._state.buffer
  }

  // Are there any events pending delivery?
  isDirty() {
    return this.isRunning() && !this._state.buffer.isEmpty()
  }

  // Are there any events currently being delivered?
  isDelivering() {
    return this._state.deliveries.length > 0
  }

  // Deliver newly tracked events to the backend.
  //
  // @return {$.Deferred}
  //   Resolves when the delivery of the current batch of pending events is
  //   done.
  deliver() {
    const {buffer} = this._state
    const {deliveries} = this._state
    const {options} = this

    const eventSet = buffer.filter(event => event.isPendingDelivery())

    if (eventSet.isEmpty()) {
      return jWhen()
    }

    eventSet.markBeingDelivered()

    const delivery = ajax({
      url: options.deliveryUrl,
      type: 'POST',
      global: false, // don't whine to the user if this fails
      headers: JSON_HEADERS,
      data: JSON.stringify({
        quiz_submission_events: eventSet.toJSON(),
      }),
      error: options.errorHandler,
    })

    delivery.then(
      () =>
        // remove the events we delivered from the buffer
        buffer.discard(eventSet),

      () =>
        // reset the events state, we'll try to deliver them again with the next
        // batch:
        eventSet.markPendingDelivery()
    )

    const untrackDelivery = () => eraseFromArray(deliveries, delivery)

    delivery.then(untrackDelivery, untrackDelivery)
    deliveries.push(delivery)

    return delivery
  }

  // Undo what #start() did.
  //
  // QuizLogAuditing stops existing once this is called.
  stop(force = false) {
    const state = this._state

    if (this.isDelivering() && !force) {
      console.warn(
        'You are attempting to stop the QuizLogAuditing module while a delivery is in progress.'
      )

      return jWhen(state.deliveries).done(this.stop.bind(this, true))
    }

    state.buffer = null

    if (state.deliveryAgent) {
      this._stopDeliveryAgent()
    }

    state.trackers.forEach(tracker => tracker.uninstall())

    state.trackers = []

    return jWhen()
  }

  _startDeliveryAgent() {
    return (this._state.deliveryAgent = setInterval(
      this.deliver.bind(this),
      this.options.autoDeliveryFrequency
    ))
  }

  // Queue an event for delivery.
  //
  // This is what the deliveryCallback will end up calling.
  //
  // @param {Event} event
  // @param {Number} [priority=0]
  _enqueue(event, priority) {
    // ignore unnecessary consecutive page_focused events.
    if (event.type === K.EVT_PAGE_FOCUSED && this._state.lastEventType !== K.EVT_PAGE_BLURRED) {
      return false
    }

    this._state.buffer.push(event)
    this._state.lastEventType = event.type

    debugConsole.log(`Enqueuing ${event} for delivery.`)

    if (priority === K.EVT_PRIORITY_HIGH) {
      if (!this.isDelivering()) {
        return this.deliver()
      } else {
        return jWhen(this._state.deliveries).done(this.deliver.bind(this))
      }
    }
  }

  _stopDeliveryAgent() {
    return (this._state.deliveryAgent = clearInterval(this._state.deliveryAgent))
  }
}
EventManager.options = {
  autoDeliver: true,
  autoDeliveryFrequency: 15000, // milliseconds
  deliveryUrl: '/quiz_submission_events',
}
