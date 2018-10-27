/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import {has, isEmpty} from 'lodash'
import CourseActivitySummaryStore from 'jsx/dashboard_card/CourseActivitySummaryStore'

QUnit.module('CourseActivitySummaryStore', {
  setup() {
    CourseActivitySummaryStore.setState({streams: {}})
    this.server = sinon.fakeServer.create()
    this.stream = [
      {
        type: 'DiscussionTopic',
        unread_count: 2,
        count: 7
      },
      {
        type: 'Conversation',
        unread_count: 0,
        count: 3
      }
    ]
  },
  teardown() {
    return this.server.restore()
  }
})

test('getStateForCourse', function() {
  ok(
    has(CourseActivitySummaryStore.getStateForCourse(), 'streams'),
    'should return root state object when no courseId is provided'
  )
  const spy = sandbox.stub(CourseActivitySummaryStore, '_fetchForCourse').returns(true)
  ok(
    isEmpty(CourseActivitySummaryStore.getStateForCourse(1)),
    'should return empty object for course id not already in state'
  )
  ok(spy.called, 'should call _fetchForCourse to fetch stream info for course')
  CourseActivitySummaryStore.setState({streams: {1: {stream: this.stream}}})
  deepEqual(
    CourseActivitySummaryStore.getStateForCourse(1),
    {stream: this.stream},
    'should return stream if present'
  )
})

test('_fetchForCourse', function() {
  ok(isEmpty(CourseActivitySummaryStore.getState().streams[1]), 'precondition')
  this.server.respondWith('GET', '/api/v1/courses/1/activity_stream/summary', [
    200,
    {'Content-Type': 'application/json'},
    JSON.stringify(this.stream)
  ])
  CourseActivitySummaryStore._fetchForCourse(1)
  this.server.respond()
  deepEqual(
    CourseActivitySummaryStore.getState().streams[1].stream,
    this.stream,
    'should populate state based on API response'
  )
})
