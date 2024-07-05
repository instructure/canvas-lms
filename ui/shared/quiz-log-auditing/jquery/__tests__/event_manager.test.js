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

import K from '../constants'
import EventManager from '../event_manager'
import EventTracker from '../event_tracker'
import Backbone from 'node_modules-version-of-backbone'
import sinon from 'sinon'

describe('Quizzes::LogAuditing::EventManager', () => {
  let evtManager

  afterEach(() => {
    if (evtManager && evtManager.isRunning()) {
      evtManager.stop()
    }
  })

  test('#start and #stop: should work', () => {
    evtManager = new EventManager()
    evtManager.start()
    expect(evtManager.isRunning()).toBe(true)
    evtManager.stop()
    expect(evtManager.isRunning()).toBe(false)
  })
})

describe('Quizzes::LogAuditing::EventManager - Event delivery', () => {
  let server
  let evtManager
  let testEventFactory
  let TestEventTracker, TestPageFocusEventTracker, TestPageBlurredEventTracker

  beforeEach(() => {
    server = sinon.fakeServer.create()

    class _TestEventTracker extends EventTracker {
      static initClass() {
        this.prototype.eventType = 'test_event'
      }

      install(deliver) {
        return testEventFactory.on('change', deliver)
      }
    }
    _TestEventTracker.initClass()
    TestEventTracker = _TestEventTracker

    class _TestPageFocusEventTracker extends EventTracker {
      static initClass() {
        this.prototype.eventType = K.EVT_PAGE_FOCUSED
      }

      install(deliver) {
        return testEventFactory.on('focus', deliver)
      }
    }
    _TestPageFocusEventTracker.initClass()
    TestPageFocusEventTracker = _TestPageFocusEventTracker

    class _TestPageBlurredEventTracker extends EventTracker {
      static initClass() {
        this.prototype.eventType = K.EVT_PAGE_BLURRED
      }

      install(deliver) {
        return testEventFactory.on('blur', deliver)
      }
    }
    _TestPageBlurredEventTracker.initClass()
    TestPageBlurredEventTracker = _TestPageBlurredEventTracker

    testEventFactory = new Backbone.Model()
  })

  afterEach(() => {
    server.restore()
    if (evtManager && evtManager.isRunning()) {
      evtManager.stop()
    }
  })

  test('it should deliver events', () => {
    const clock = sinon.useFakeTimers()
    evtManager = new EventManager({
      autoDeliver: false,
      deliveryUrl: '/events',
    })
    evtManager.registerTracker(TestEventTracker)
    evtManager.start()
    testEventFactory.trigger('change')
    expect(evtManager.isDirty()).toBe(true)
    evtManager.deliver()
    expect(server.requests.length).toBe(1)
    expect(server.requests[0].url).toBe('/events')
    const payload = JSON.parse(server.requests[0].requestBody)
    expect(payload).toHaveProperty('quiz_submission_events')
    expect(payload.quiz_submission_events[0].event_type).toBe('test_event')
    expect(evtManager.isDelivering()).toBe(true)
    server.requests[0].respond(204)
    clock.tick(1)
    expect(evtManager.isDelivering()).toBe(false)
    expect(evtManager.isDirty()).toBe(false)
    clock.restore()
  })

  test('should ignore EVT_PAGE_FOCUSED events that are not preceded by EVT_PAGE_BLURRED', () => {
    const consoleWarn = jest.spyOn(global.console, 'warn')
    consoleWarn.mockImplementation(() => {}) // keep it from actually logging

    evtManager = new EventManager({
      autoDeliver: false,
      deliveryUrl: '/events',
    })
    evtManager.registerTracker(TestPageFocusEventTracker)
    evtManager.registerTracker(TestPageBlurredEventTracker)
    evtManager.registerTracker(TestEventTracker)

    evtManager.start()

    testEventFactory.trigger('change')
    evtManager.deliver()
    expect(server.requests.length).toBe(1)
    let payload1 = JSON.parse(server.requests[0].requestBody)
    expect(payload1.quiz_submission_events[0].event_type).toBe('test_event')

    testEventFactory.trigger('focus')
    evtManager.deliver()
    expect(server.requests.length).toBe(1)
    payload1 = JSON.parse(server.requests[0].requestBody)
    expect(payload1.quiz_submission_events[0].event_type).toBe('test_event')

    testEventFactory.trigger('blur')
    evtManager.deliver()
    expect(server.requests.length).toBe(2)
    const payload2 = JSON.parse(server.requests[1].requestBody)
    expect(payload2.quiz_submission_events[0].event_type).toBe(K.EVT_PAGE_BLURRED)

    testEventFactory.trigger('focus')
    evtManager.deliver()
    expect(server.requests.length).toBe(3)
    const payload3 = JSON.parse(server.requests[2].requestBody)
    expect(payload3.quiz_submission_events[0].event_type).toBe(K.EVT_PAGE_FOCUSED)
  })

  test('it should drop trackers', () => {
    evtManager = new EventManager({
      autoDeliver: false,
      deliveryUrl: '/events',
    })
    evtManager.start()
    evtManager.registerTracker(TestEventTracker)
    evtManager.unregisterAllTrackers()
    testEventFactory.trigger('change')
    expect(evtManager.isDirty()).toBe(false)
  })
})
