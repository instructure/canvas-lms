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
import {http, HttpResponse} from 'msw'
import {mswServer} from '../../../msw/mswServer'
import fakeENV from '@canvas/test-utils/fakeENV'

describe('Quizzes::LogAuditing::EventManager', () => {
  let evtManager

  beforeEach(() => {
    fakeENV.setup()
  })

  afterEach(() => {
    if (evtManager && evtManager.isRunning()) {
      evtManager.stop()
    }
    fakeENV.teardown()
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
  let evtManager
  let testEventFactory
  let TestEventTracker, TestPageFocusEventTracker, TestPageBlurredEventTracker
  let capturedRequests
  let server

  beforeEach(() => {
    fakeENV.setup()
    capturedRequests = []

    const handlers = [
      http.post('/events', async ({request}) => {
        const body = await request.json()
        capturedRequests.push({
          url: request.url,
          requestBody: body,
        })
        return HttpResponse.json({}, {status: 200})
      }),
    ]

    server = mswServer(handlers)
    server.listen()

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
    if (evtManager && evtManager.isRunning()) {
      evtManager.stop()
    }
    server.resetHandlers()
    server.close()
    fakeENV.teardown()
  })

  test('it should deliver events', async () => {
    evtManager = new EventManager({
      autoDeliver: false,
      deliveryUrl: '/events',
    })
    evtManager.registerTracker(TestEventTracker)
    evtManager.start()
    testEventFactory.trigger('change')
    expect(evtManager.isDirty()).toBe(true)

    const deliveryPromise = evtManager.deliver()
    await deliveryPromise

    expect(capturedRequests).toHaveLength(1)
    expect(capturedRequests[0].url).toContain('/events')
    const payload = capturedRequests[0].requestBody
    expect(payload).toHaveProperty('quiz_submission_events')
    expect(payload.quiz_submission_events[0].event_type).toBe('test_event')

    expect(evtManager.isDelivering()).toBe(false)
    expect(evtManager.isDirty()).toBe(false)
  })

  test('should ignore EVT_PAGE_FOCUSED events that are not preceded by EVT_PAGE_BLURRED', async () => {
    const consoleWarn = jest.spyOn(console, 'warn')
    consoleWarn.mockImplementation(() => {})

    evtManager = new EventManager({
      autoDeliver: false,
      deliveryUrl: '/events',
    })
    evtManager.registerTracker(TestPageFocusEventTracker)
    evtManager.registerTracker(TestPageBlurredEventTracker)
    evtManager.registerTracker(TestEventTracker)

    evtManager.start()

    testEventFactory.trigger('change')
    await evtManager.deliver()
    expect(capturedRequests).toHaveLength(1)
    let payload1 = capturedRequests[0].requestBody
    expect(payload1.quiz_submission_events[0].event_type).toBe('test_event')

    testEventFactory.trigger('focus')
    await evtManager.deliver()
    expect(capturedRequests).toHaveLength(1)
    payload1 = capturedRequests[0].requestBody
    expect(payload1.quiz_submission_events[0].event_type).toBe('test_event')

    testEventFactory.trigger('blur')
    await evtManager.deliver()
    expect(capturedRequests).toHaveLength(2)
    const payload2 = capturedRequests[1].requestBody
    expect(payload2.quiz_submission_events[0].event_type).toBe(K.EVT_PAGE_BLURRED)

    testEventFactory.trigger('focus')
    await evtManager.deliver()
    expect(capturedRequests).toHaveLength(3)
    const payload3 = capturedRequests[2].requestBody
    expect(payload3.quiz_submission_events[0].event_type).toBe(K.EVT_PAGE_FOCUSED)

    consoleWarn.mockRestore()
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
