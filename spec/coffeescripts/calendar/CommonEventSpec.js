/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import CommonEvent from '@canvas/calendar/jquery/CommonEvent/CommonEvent'
import commonEventFactory from '@canvas/calendar/jquery/CommonEvent/index'
import fakeENV from 'helpers/fakeENV'

QUnit.module('CommonEvent', {
  setup() {},
  teardown() {}
})

test('CommonEvent: should prevent assignment-due events from wrapping to the next day', () => {
  const event = commonEventFactory({assignment: {due_at: '2016-02-25T23:30:00Z'}}, ['course_1'])
  equal(event.end.date(), 26)
  equal(event.end.hours(), 0)
  equal(event.end.minutes(), 0)
})

test('CommonEvent: should expand assignments to occupy 30 minutes so they are readable', () => {
  const event = commonEventFactory({assignment: {due_at: '2016-02-25T23:59:00Z'}}, ['course_1'])
  equal(event.start.date(), 25)
  equal(event.start.hours(), 23)
  equal(event.start.minutes(), 30)
  equal(event.end.date(), 26)
  equal(event.end.hours(), 0)
  equal(event.end.minutes(), 0)
})

test('CommonEvent: should leave events with defined end times alone', () => {
  const event = commonEventFactory(
    {
      title: 'Not an assignment',
      start_at: '2016-02-25T23:30:00Z',
      end_at: '2016-02-26T00:30:00Z'
    },
    ['course_1']
  )
  equal(event.end.date(), 26)
  equal(event.end.hours(), 0)
  equal(event.end.minutes(), 30)
})

test('CommonEvent: isOnCalendar', () => {
  const event = commonEventFactory(
    {
      title: 'blah',
      start_at: '2016-02-25T23:30:00Z',
      all_context_codes: 'course_1,course_23'
    },
    ['course_1', 'course_23']
  )
  ok(event.isOnCalendar('course_1'))
  ok(event.isOnCalendar('course_23'))
  notOk(event.isOnCalendar('course_2'))
})

test('commonEventFactory: finds a context for multi-context events', () => {
  const event = commonEventFactory(
    {
      title: 'Another Dang Thing',
      start_at: '2016-10-02T10:00:00Z',
      type: 'event',
      effective_context_code: 'course_2,course_4',
      context_code: 'user_2',
      all_context_codes: 'course_2,course_4',
      parent_event_id: '172',
      appointment_group_id: '2',
      appointment_group_url: 'http://localhost:3000/api/v1/appointment_groups/2',
      own_reservation: true
    },
    [{asset_string: 'course_2'}]
  )
  notEqual(event, null)
})

QUnit.module('CommonEvent#iconType', {
  setup() {
    fakeENV.setup({CALENDAR: {SHOW_SCHEDULER: true}})
  },
  teardown() {
    fakeENV.teardown()
  }
})

test('Returns "calendar-add" for non-filled groups', () => {
  const event = commonEventFactory(
    {
      title: 'some title',
      start_at: '2016-12-01T12:30:00Z',
      appointment_group_url: 'http://some_url'
    },
    ['course_1']
  )
  equal(event.iconType(), 'calendar-add')
})

test('Returns "calendar-reserved" for filled groups', () => {
  const event = commonEventFactory(
    {
      title: 'some title',
      start_at: '2016-12-01T12:30:00Z',
      appointment_group_url: 'http://some_url',
      child_events: [{}]
    },
    ['course_1']
  )
  equal(event.iconType(), 'calendar-reserved')
})

test('Returns "calendar-reserved" when the appointmentGroupEventStatus is "Reserved"', () => {
  const event = commonEventFactory(
    {
      title: 'some title',
      start_at: '2016-12-01T12:30:00Z',
      appointment_group_url: 'http://some_url'
    },
    ['course_1']
  )
  event.appointmentGroupEventStatus = 'Reserved'
  equal(event.iconType(), 'calendar-reserved')
})

test('Returns "calendar-month" for other situations', () => {
  const event = commonEventFactory(
    {
      title: 'some title',
      start_at: '2016-12-01T12:30:00Z'
    },
    ['course_1']
  )
  equal(event.iconType(), 'calendar-month')
})

test('Returns "discussion" for ungraded discussion objects with todo dates', () => {
  const event = commonEventFactory(
    {
      context_code: 'course_1',
      plannable_type: 'discussion_topic',
      plannable: {id: '123', title: 'some title', todo_date: '2016-12-01T12:30:00Z'}
    },
    [{asset_string: 'course_1', can_update_discussion_topic: false, can_update_todo_date: false}]
  )
  equal(event.iconType(), 'discussion')
  equal(event.can_edit, false)
  equal(event.can_delete, false)
  equal(event.can_change_context, false)
})

test('Returns "document" for wiki pages with todo dates', () => {
  const event = commonEventFactory(
    {
      context_code: 'course_1',
      plannable_type: 'wiki_page',
      plannable: {url: 'some_title', title: 'some title', todo_date: '2016-12-01T12:30:00Z'}
    },
    [{asset_string: 'course_1', can_update_wiki_page: false, can_update_todo_date: false}]
  )
  equal(event.iconType(), 'document')
  equal(event.can_edit, false)
  equal(event.can_delete, false)
  equal(event.can_change_context, false)
})

test('sets can_edit/can_delete/fullDetailsURL/readableType on discussion_topics', () => {
  const event = commonEventFactory(
    {
      context_code: 'course_1',
      plannable_type: 'discussion_topic',
      html_url: 'http://example.org/courses/1/discussion_topics/123',
      plannable: {id: '123', title: 'some title', todo_date: '2016-12-01T12:30:00Z'}
    },
    [{asset_string: 'course_1', can_update_discussion_topic: true, can_update_todo_date: true}]
  )
  equal(event.can_edit, true)
  equal(event.can_delete, true)
  equal(event.can_change_context, false)
  equal(event.fullDetailsURL(), 'http://example.org/courses/1/discussion_topics/123')
  equal(event.readableType(), 'Discussion')
})

test('sets can_edit/can_delete/fullDetailsURL/readableType on wiki pages', () => {
  const event = commonEventFactory(
    {
      context_code: 'course_1',
      plannable_type: 'wiki_page',
      html_url: 'http://example.org/courses/1/pages/some-page',
      plannable: {url: 'some_page', title: 'some page', todo_date: '2016-12-01T12:30:00Z'}
    },
    [{asset_string: 'course_1', can_update_wiki_page: true, can_update_todo_date: true}]
  )
  equal(event.iconType(), 'document')
  equal(event.can_edit, true)
  equal(event.can_delete, true)
  equal(event.can_change_context, false)
  equal(event.fullDetailsURL(), 'http://example.org/courses/1/pages/some-page')
  equal(event.readableType(), 'Page')
})
