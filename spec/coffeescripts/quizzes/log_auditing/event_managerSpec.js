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

import K from '@canvas/quiz-log-auditing/jquery/constants'
import QuizEvent from '@canvas/quiz-log-auditing/jquery/event'
import EventManager from '@canvas/quiz-log-auditing/jquery/event_manager'
import EventTracker from '@canvas/quiz-log-auditing/jquery/event_tracker'
import Backbone from 'node_modules-version-of-backbone'
import sinon from 'sinon'

QUnit.module('Quizzes::LogAuditing::EventManager', {
  teardown() {
    if (this.evtManager && this.evtManager.isRunning()) {
      return this.evtManager.stop()
    }
  },
})

test('#start and #stop: should work', function () {
  this.evtManager = new EventManager()
  this.evtManager.start()
  ok(this.evtManager.isRunning())
  this.evtManager.stop()
  ok(!this.evtManager.isRunning())
})

QUnit.module('Quizzes::LogAuditing::EventManager - Event delivery', {
  setup() {
    this.server = sinon.fakeServer.create()
    const specThis = this
    class TestEventTracker extends EventTracker {
      static initClass() {
        this.prototype.eventType = 'test_event'
      }

      install(deliver) {
        return specThis.testEventFactory.on('change', deliver)
      }
    }
    TestEventTracker.initClass()
    this.TestEventTracker = TestEventTracker

    class TestPageFocusEventTracker extends EventTracker {
      static initClass() {
        this.prototype.eventType = K.EVT_PAGE_FOCUSED
      }

      install(deliver) {
        return specThis.testEventFactory.on('focus', deliver)
      }
    }
    TestPageFocusEventTracker.initClass()
    this.TestPageFocusEventTracker = TestPageFocusEventTracker

    class TestPageBlurredEventTracker extends EventTracker {
      static initClass() {
        this.prototype.eventType = K.EVT_PAGE_BLURRED
      }

      install(deliver) {
        return specThis.testEventFactory.on('blur', deliver)
      }
    }
    TestPageBlurredEventTracker.initClass()
    this.TestPageBlurredEventTracker = TestPageBlurredEventTracker

    this.testEventFactory = new Backbone.Model()
  },
  teardown() {
    this.server.restore()
    if (this.evtManager && this.evtManager.isRunning()) {
      return this.evtManager.stop()
    }
  },
})

test('it should deliver events', function () {
  const clock = sinon.useFakeTimers()
  this.evtManager = new EventManager({
    autoDeliver: false,
    deliveryUrl: '/events',
  })
  this.evtManager.registerTracker(this.TestEventTracker)
  this.evtManager.start()
  this.testEventFactory.trigger('change')
  ok(this.evtManager.isDirty(), 'it correctly reports whether it has any events pending delivery')
  this.evtManager.deliver()
  equal(this.server.requests.length, 1)
  equal(this.server.requests[0].url, '/events', 'it respects the delivery URL')
  const payload = JSON.parse(this.server.requests[0].requestBody)
  ok(
    payload.hasOwnProperty('quiz_submission_events'),
    'it scopes event payload with "quiz_submission_events"'
  )
  equal(
    payload.quiz_submission_events[0].event_type,
    'test_event',
    'it includes the serialized events'
  )
  ok(this.evtManager.isDelivering(), 'it correctly reports whether a delivery is in progress')
  this.server.requests[0].respond(204)
  clock.tick(1)
  ok(!this.evtManager.isDelivering(), "it untracks the delivery once it's synced with the server")
  ok(!this.evtManager.isDirty(), 'it flushes its buffer when sync is complete')
  clock.restore()
})

test('should ignore EVT_PAGE_FOCUSED events that are not preceded by EVT_PAGE_BLURRED', function () {
  this.evtManager = new EventManager({
    autoDeliver: false,
    deliveryUrl: '/events',
  })
  this.evtManager.registerTracker(this.TestPageFocusEventTracker)
  this.evtManager.registerTracker(this.TestPageBlurredEventTracker)
  this.evtManager.registerTracker(this.TestEventTracker)

  this.evtManager.start()

  this.testEventFactory.trigger('change')
  this.evtManager.deliver()
  equal(this.server.requests.length, 1)
  let payload1 = JSON.parse(this.server.requests[0].requestBody)
  equal(payload1.quiz_submission_events[0].event_type, 'test_event')

  this.testEventFactory.trigger('focus')
  this.evtManager.deliver()

  equal(this.server.requests.length, 1)
  payload1 = JSON.parse(this.server.requests[0].requestBody)
  equal(payload1.quiz_submission_events[0].event_type, 'test_event')

  this.testEventFactory.trigger('blur')
  this.evtManager.deliver()

  equal(this.server.requests.length, 2)
  const payload2 = JSON.parse(this.server.requests[1].requestBody)
  equal(payload2.quiz_submission_events[0].event_type, K.EVT_PAGE_BLURRED)

  this.testEventFactory.trigger('focus')
  this.evtManager.deliver()

  equal(this.server.requests.length, 3)
  const payload3 = JSON.parse(this.server.requests[2].requestBody)
  equal(payload3.quiz_submission_events[0].event_type, K.EVT_PAGE_FOCUSED)
})

test('it should drop trackers', function () {
  this.evtManager = new EventManager({
    autoDeliver: false,
    deliveryUrl: '/events',
  })
  this.evtManager.start()
  this.evtManager.registerTracker(this.TestEventTracker)
  this.evtManager.unregisterAllTrackers()
  this.testEventFactory.trigger('change')
  ok(!this.evtManager.isDirty(), "it doesn't have any active trackers")
})
