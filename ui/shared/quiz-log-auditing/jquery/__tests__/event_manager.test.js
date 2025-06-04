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
import $ from 'jquery'

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
  let evtManager
  let testEventFactory
  let TestEventTracker, TestPageFocusEventTracker, TestPageBlurredEventTracker
  let capturedRequests = []
  let originalAjax

  beforeEach(() => {
    capturedRequests = []
    originalAjax = $.ajax

    // Mock jQuery ajax
    $.ajax = jest.fn(options => {
      capturedRequests.push({
        url: options.url,
        requestBody: JSON.parse(options.data),
      })

      const deferred = $.Deferred()

      // Simulate async response
      setTimeout(() => {
        deferred.resolve()
      }, 0)

      return deferred.promise()
    })

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
    $.ajax = originalAjax
    if (evtManager && evtManager.isRunning()) {
      evtManager.stop()
    }
  })

  test('it should deliver events', async () => {
    jest.useFakeTimers()
    evtManager = new EventManager({
      autoDeliver: false,
      deliveryUrl: '/events',
    })
    evtManager.registerTracker(TestEventTracker)
    evtManager.start()
    testEventFactory.trigger('change')
    expect(evtManager.isDirty()).toBe(true)
    evtManager.deliver()

    // Wait for the async request to complete
    await jest.runAllTimersAsync()

    expect(capturedRequests).toHaveLength(1)
    expect(capturedRequests[0].url).toBe('/events')
    const payload = capturedRequests[0].requestBody
    expect(payload).toHaveProperty('quiz_submission_events')
    expect(payload.quiz_submission_events[0].event_type).toBe('test_event')

    expect(evtManager.isDelivering()).toBe(false)
    expect(evtManager.isDirty()).toBe(false)
    jest.useRealTimers()
  })

  test('should ignore EVT_PAGE_FOCUSED events that are not preceded by EVT_PAGE_BLURRED', async () => {
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
    await new Promise(resolve => setTimeout(resolve, 0))
    expect(capturedRequests).toHaveLength(1)
    let payload1 = capturedRequests[0].requestBody
    expect(payload1.quiz_submission_events[0].event_type).toBe('test_event')

    testEventFactory.trigger('focus')
    evtManager.deliver()
    await new Promise(resolve => setTimeout(resolve, 0))
    expect(capturedRequests).toHaveLength(1)
    payload1 = capturedRequests[0].requestBody
    expect(payload1.quiz_submission_events[0].event_type).toBe('test_event')

    testEventFactory.trigger('blur')
    evtManager.deliver()
    await new Promise(resolve => setTimeout(resolve, 0))
    expect(capturedRequests).toHaveLength(2)
    const payload2 = capturedRequests[1].requestBody
    expect(payload2.quiz_submission_events[0].event_type).toBe(K.EVT_PAGE_BLURRED)

    testEventFactory.trigger('focus')
    evtManager.deliver()
    await new Promise(resolve => setTimeout(resolve, 0))
    expect(capturedRequests).toHaveLength(3)
    const payload3 = capturedRequests[2].requestBody
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
