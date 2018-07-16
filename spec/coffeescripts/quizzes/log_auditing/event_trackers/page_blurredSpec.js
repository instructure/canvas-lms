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

import Subject from 'compiled/quizzes/log_auditing/event_trackers/page_blurred'
import K from 'compiled/quizzes/log_auditing/constants'
import $ from 'jquery'

QUnit.module('Quizzes::LogAuditing::EventTrackers::PageBlurred')

test('#constructor: it sets up the proper context', () => {
  const tracker = new Subject()
  equal(tracker.eventType, K.EVT_PAGE_BLURRED)
  equal(tracker.priority, K.EVT_PRIORITY_LOW)
})

test('capturing: it works', function() {
  const tracker = new Subject()
  const capture = sinon.stub()
  tracker.install(capture)
  $(window).blur()
  ok(capture.called, 'it captures page blur')
})

test('capturing: it doesnt send events if in iframe (for RCE focusing)', function() {
  const tracker = new Subject()
  const capture = sinon.stub()
  tracker.install(capture)
  const iframe = $('<iframe>')
    .appendTo('body')
    .focus()
  $(window).blur()
  ok(capture.notCalled, 'it does not mark iframe focus as page blur')
  return iframe.remove()
})

test('capturing: it throttles captures', function() {
  const capture = sinon.spy()
  const tracker = new Subject()
  tracker.install(capture)
  $(window).blur()
  $(window).focus()
  $(window).blur()
  $(window).focus()
  $(window).blur()
  equal(capture.callCount, 1, 'it ignores rapidly repetitive blurs')
})
