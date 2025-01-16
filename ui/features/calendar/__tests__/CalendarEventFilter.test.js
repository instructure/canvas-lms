/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import commonEventFactory from '@canvas/calendar/jquery/CommonEvent/index'
import CalendarEventFilter from '../CalendarEventFilter'
import fakeENV from '@canvas/test-utils/fakeENV'

const createTestEvents = (
  can_edit,
  child_events_count,
  available_slots = 1,
  reserved = false,
  past_slot = false,
) => [
  commonEventFactory(
    {
      id: '1',
      title: 'Normal Event',
      start_at: '2016-08-29T11:00:00Z',
      end_at: '2016-08-29T11:30:00Z',
      workflow_state: 'active',
      type: 'event',
      description: '',
      child_events_count: 0,
      effective_context_code: 'course_1',
      context_code: 'course_1',
      all_context_codes: 'course_1',
      parent_event_id: null,
      hidden: false,
      child_events: [],
      url: 'http://example.org/api/v1/calendar_events/1',
    },
    [
      {
        asset_string: 'course_1',
        id: 1,
      },
    ],
  ),
  commonEventFactory(
    {
      id: '20',
      title: 'Appointment Slot',
      start_at: `${new Date().getFullYear() + (past_slot ? -1 : 1)}-08-29T11:00:00Z`,
      end_at: `${new Date().getFullYear() + (past_slot ? -1 : 1)}-08-29T11:30:00Z`,
      workflow_state: 'active',
      type: 'event',
      description: '',
      child_events_count,
      effective_context_code: 'course_1',
      context_code: 'course_1',
      all_context_codes: 'course_1,course_2',
      parent_event_id: null,
      hidden: false,
      appointment_group_id: '2',
      appointment_group_url: 'http://example.org/api/v1/appointment_groups/2',
      can_manage_appointment_group: can_edit,
      reserve_url: 'http://example.org/api/v1/calendar_events/20/reservations/%7B%7B%20id%20%7D%7D',
      child_events: [],
      url: 'http://example.org/api/v1/calendar_events/20',
      available_slots,
      reserved,
    },
    [
      {
        asset_string: 'course_1',
        id: 1,
        can_create_calendar_events: can_edit,
      },
    ],
  ),
]

describe('CalendarEventFilter', () => {
  afterEach(() => {
    fakeENV.teardown()
  })

  it('hides appointment slots and does not gray events when schedulerState is not provided', () => {
    const filteredEvents = CalendarEventFilter(null, createTestEvents(false, 0))
    expect(filteredEvents).toHaveLength(1)
    expect(filteredEvents[0].id).toBe('calendar_event_1')
    expect(filteredEvents[0].className.indexOf('grayed')).toBe(-1)
  })

  it('hides appointment slots and does not gray events when not in find-appointment mode', () => {
    const filteredEvents = CalendarEventFilter(null, createTestEvents(false, 0), {
      inFindAppointmentMode: false,
      selectedCourse: null,
    })
    expect(filteredEvents).toHaveLength(1)
    expect(filteredEvents[0].id).toBe('calendar_event_1')
    expect(filteredEvents[0].className.indexOf('grayed')).toBe(-1)
  })

  it('grays non-appointment events when in find-appointment mode', () => {
    const filteredEvents = CalendarEventFilter(null, createTestEvents(false, 0), {
      inFindAppointmentMode: true,
      selectedCourse: {
        id: 789,
        asset_string: 'course_789',
      },
    })
    expect(filteredEvents).toHaveLength(1)
    expect(filteredEvents[0].id).toBe('calendar_event_1')
    expect(filteredEvents[0].className).toContain('grayed')
  })

  it('shows appointment slots when in find-appointment mode and course is selected', () => {
    const filteredEvents = CalendarEventFilter(null, createTestEvents(false, 0), {
      inFindAppointmentMode: true,
      selectedCourse: {
        id: 1,
        asset_string: 'course_1',
      },
    })
    expect(filteredEvents).toHaveLength(2)
    expect(filteredEvents[0].id).toBe('calendar_event_1')
    expect(filteredEvents[0].className).toContain('grayed')
    expect(filteredEvents[1].id).toBe('calendar_event_20')
    expect(filteredEvents[1].className).not.toContain('grayed')
  })

  it('grays unreserved appointment events in appointment mode', () => {
    const filteredEvents = CalendarEventFilter(null, createTestEvents(true, 0), {
      inFindAppointmentMode: false,
      selectedCourse: {
        id: 789,
        asset_string: 'course_789',
      },
    })
    expect(filteredEvents).toHaveLength(2)
    expect(filteredEvents[0].id).toBe('calendar_event_1')
    expect(filteredEvents[0].className).not.toContain('grayed')
    expect(filteredEvents[1].className).toContain('grayed')
  })

  it('does not gray reserved appointment events without appointment mode', () => {
    const filteredEvents = CalendarEventFilter(null, createTestEvents(true, 2), {
      selectedCourse: {
        id: 789,
        asset_string: 'course_789',
      },
    })
    expect(filteredEvents).toHaveLength(2)
    expect(filteredEvents[0].id).toBe('calendar_event_1')
    expect(filteredEvents[0].className).not.toContain('grayed')
    expect(filteredEvents[1].className).not.toContain('grayed')
  })

  it('hides filled slots', () => {
    const filteredEvents = CalendarEventFilter(null, createTestEvents(false, 0, 0), {
      inFindAppointmentMode: true,
      selectedCourse: {
        id: 1,
        asset_string: 'course_1',
      },
    })
    expect(filteredEvents).toHaveLength(1)
    expect(filteredEvents[0].id).toBe('calendar_event_1')
  })

  it('hides already-reserved appointments that still have available slots', () => {
    const filteredEvents = CalendarEventFilter(null, createTestEvents(false, 0, 1, true), {
      inFindAppointmentMode: true,
      selectedCourse: {
        id: 1,
        asset_string: 'course_1',
      },
    })
    expect(filteredEvents).toHaveLength(1)
    expect(filteredEvents[0].id).toBe('calendar_event_1')
  })

  it('hides past appointments', () => {
    const filteredEvents = CalendarEventFilter(null, createTestEvents(false, 0, 1, false, true), {
      inFindAppointmentMode: true,
      selectedCourse: {
        id: 1,
        asset_string: 'course_1',
      },
    })
    expect(filteredEvents).toHaveLength(1)
    expect(filteredEvents[0].id).toBe('calendar_event_1')
  })

  it('follows normal calendar view flow when SHOW_SCHEDULER is enabled', () => {
    fakeENV.setup({CALENDAR: {SHOW_SCHEDULER: true}})
    const filteredEvents = CalendarEventFilter(true, createTestEvents(false, 0, 1, true), {})
    expect(filteredEvents).toHaveLength(1)
  })
})
