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

import commonEventFactory from '../index'
import fakeENV from '@canvas/test-utils/fakeENV'

describe('CommonEvent', () => {
  beforeEach(() => {
    // Jest doesn't have explicit setup/teardown for modules like QUnit
    fakeENV.setup({CALENDAR: {SHOW_SCHEDULER: true}})
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  test('should prevent assignment-due events from wrapping to the next day', () => {
    const event = commonEventFactory({assignment: {due_at: '2016-02-25T23:30:00Z'}}, ['course_1'])
    expect(event.end.date()).toBe(26)
    expect(event.end.hours()).toBe(0)
    expect(event.end.minutes()).toBe(0)
  })

  test('should expand assignments to occupy 30 minutes so they are readable', () => {
    const event = commonEventFactory({assignment: {due_at: '2016-02-25T23:59:00Z'}}, ['course_1'])
    expect(event.start.date()).toBe(25)
    expect(event.start.hours()).toBe(23)
    expect(event.start.minutes()).toBe(30)
    expect(event.end.date()).toBe(26)
    expect(event.end.hours()).toBe(0)
    expect(event.end.minutes()).toBe(0)
  })

  test('should leave events with defined end times alone', () => {
    const event = commonEventFactory(
      {
        title: 'Not an assignment',
        start_at: '2016-02-25T23:30:00Z',
        end_at: '2016-02-26T00:30:00Z',
      },
      ['course_1'],
    )
    expect(event.end.date()).toBe(26)
    expect(event.end.hours()).toBe(0)
    expect(event.end.minutes()).toBe(30)
  })

  test('isOnCalendar', () => {
    const event = commonEventFactory(
      {
        title: 'blah',
        start_at: '2016-02-25T23:30:00Z',
        all_context_codes: 'course_1,course_23',
      },
      ['course_1', 'course_23'],
    )
    expect(event.isOnCalendar('course_1')).toBeTruthy()
    expect(event.isOnCalendar('course_23')).toBeTruthy()
    expect(event.isOnCalendar('course_2')).toBeFalsy()
  })

  test('isOnCalendar with cross-shard global IDs', () => {
    const event = commonEventFactory(
      {
        title: 'cross-shard appointment',
        start_at: '2026-01-26T18:00:00Z',
        all_context_codes: 'course_97700000000059053',
      },
      ['course_97700000000059053'],
    )
    expect(event.isOnCalendar('course_97700000000059053')).toBeTruthy()
    expect(event.isOnCalendar('course_59053')).toBeFalsy()
    expect(event.isOnCalendar('course_59054')).toBeFalsy()
    expect(event.isOnCalendar('course_590')).toBeFalsy()
  })

  test('finds a context for multi-context events', () => {
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
        own_reservation: true,
      },
      [{asset_string: 'course_2'}],
    )
    expect(event).not.toBeNull()
  })

  test('matches context when API returns consistent IDs', () => {
    const event = commonEventFactory(
      {
        title: 'Cross-shard appointment',
        start_at: '2026-01-26T18:00:00Z',
        effective_context_code: 'course_97700000000059053',
        context_code: 'course_97700000000059053',
        all_context_codes: 'course_97700000000059053',
        appointment_group_id: '2',
        appointment_group_url: 'http://localhost:3000/api/v1/appointment_groups/2',
      },
      [{asset_string: 'course_97700000000059053', can_create_calendar_events: true}],
    )
    expect(event).not.toBeNull()
    expect(event.contextCode()).toBe('course_97700000000059053')
  })

  test('matches context in multi-context events', () => {
    const event = commonEventFactory(
      {
        title: 'Multi-context',
        start_at: '2026-01-26T18:00:00Z',
        effective_context_code: 'course_97700000000059053,course_97700000000059054',
        context_code: 'user_2',
        all_context_codes: 'course_97700000000059053,course_97700000000059054',
      },
      [{asset_string: 'course_97700000000059053'}, {asset_string: 'course_97700000000059054'}],
    )
    expect(event).not.toBeNull()
  })

  test('returns null when context cannot be matched', () => {
    const event = commonEventFactory(
      {
        title: 'Unmatched context',
        start_at: '2026-01-26T18:00:00Z',
        effective_context_code: 'course_99999',
        all_context_codes: 'course_99999',
      },
      [{asset_string: 'course_59053'}],
    )
    expect(event).toBeNull()
  })
})

describe('CommonEvent#iconType', () => {
  beforeEach(() => {
    fakeENV.setup({CALENDAR: {SHOW_SCHEDULER: true}})
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  test('Returns "calendar-add" for non-filled groups', () => {
    const event = commonEventFactory(
      {
        title: 'some title',
        start_at: '2016-12-01T12:30:00Z',
        appointment_group_url: 'http://some_url',
      },
      ['course_1'],
    )
    expect(event.iconType()).toBe('calendar-add')
  })

  test('Returns "calendar-reserved" for filled groups', () => {
    const event = commonEventFactory(
      {
        title: 'some title',
        start_at: '2016-12-01T12:30:00Z',
        appointment_group_url: 'http://some_url',
        child_events: [{}],
      },
      ['course_1'],
    )
    expect(event.iconType()).toBe('calendar-reserved')
  })

  test('Returns "calendar-reserved" when the appointmentGroupEventStatus is "Reserved"', () => {
    const event = commonEventFactory(
      {
        title: 'some title',
        start_at: '2016-12-01T12:30:00Z',
        appointment_group_url: 'http://some_url',
      },
      ['course_1'],
    )
    event.appointmentGroupEventStatus = 'Reserved'
    expect(event.iconType()).toBe('calendar-reserved')
  })

  test('Returns "calendar-month" for other situations', () => {
    const event = commonEventFactory(
      {
        title: 'some title',
        start_at: '2016-12-01T12:30:00Z',
      },
      ['course_1'],
    )
    expect(event.iconType()).toBe('calendar-month')
  })

  test('Returns "discussion" for ungraded discussion objects with todo dates', () => {
    const event = commonEventFactory(
      {
        context_code: 'course_1',
        plannable_type: 'discussion_topic',
        plannable: {id: '123', title: 'some title', todo_date: '2016-12-01T12:30:00Z'},
      },
      [{asset_string: 'course_1', can_update_discussion_topic: false, can_update_todo_date: false}],
    )
    expect(event.iconType()).toBe('discussion')
    expect(event.can_edit).toBe(false)
    expect(event.can_delete).toBe(false)
    expect(event.can_change_context).toBe(false)
  })

  test('Returns "document" for wiki pages with todo dates', () => {
    const event = commonEventFactory(
      {
        context_code: 'course_1',
        plannable_type: 'wiki_page',
        plannable: {url: 'some_title', title: 'some title', todo_date: '2016-12-01T12:30:00Z'},
      },
      [{asset_string: 'course_1', can_update_wiki_page: false, can_update_todo_date: false}],
    )
    expect(event.iconType()).toBe('document')
    expect(event.can_edit).toBe(false)
    expect(event.can_delete).toBe(false)
    expect(event.can_change_context).toBe(false)
  })

  test('sets can_edit/can_delete/fullDetailsURL/readableType on discussion_topics', () => {
    const event = commonEventFactory(
      {
        context_code: 'course_1',
        plannable_type: 'discussion_topic',
        html_url: 'http://example.org/courses/1/discussion_topics/123',
        plannable: {id: '123', title: 'some title', todo_date: '2016-12-01T12:30:00Z'},
      },
      [{asset_string: 'course_1', can_update_discussion_topic: true, can_update_todo_date: true}],
    )
    expect(event.can_edit).toBe(true)
    expect(event.can_delete).toBe(true)
    expect(event.can_change_context).toBe(false)
    expect(event.fullDetailsURL()).toBe('http://example.org/courses/1/discussion_topics/123')
    expect(event.readableType()).toBe('Discussion')
  })

  test('sets can_edit/can_delete/fullDetailsURL/readableType on wiki pages', () => {
    const event = commonEventFactory(
      {
        context_code: 'course_1',
        plannable_type: 'wiki_page',
        html_url: 'http://example.org/courses/1/pages/some-page',
        plannable: {url: 'some_page', title: 'some page', todo_date: '2016-12-01T12:30:00Z'},
      },
      [{asset_string: 'course_1', can_update_wiki_page: true, can_update_todo_date: true}],
    )
    expect(event.iconType()).toBe('document')
    expect(event.can_edit).toBe(true)
    expect(event.can_delete).toBe(true)
    expect(event.can_change_context).toBe(false)
    expect(event.fullDetailsURL()).toBe('http://example.org/courses/1/pages/some-page')
    expect(event.readableType()).toBe('Page')
  })

  test('should not throw an error if the assignment_overrides is an empty array', () => {
    const event = commonEventFactory(
      {
        title: 'some title',
        start_at: '2016-12-01T12:30:00Z',
        assignment_overrides: [],
      },
      ['course_1'],
    )
    expect(event).toBeTruthy()
    expect(event.assignment_overrides).toBeUndefined()
  })
})
