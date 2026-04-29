/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

describe('isCompleted()', () => {
  let data, contexts
  const subject = () => commonEventFactory(data, contexts)

  describe('when the event type is a todo item', () => {
    beforeEach(() => {
      data = {
        context_code: 'course_1',
        plannable_type: 'wiki_page',
        plannable: {url: 'some_title', title: 'some title', todo_date: '2016-12-01T12:30:00Z'},
      }

      contexts = [
        {asset_string: 'course_1', can_update_wiki_page: false, can_update_todo_date: false},
      ]
    })

    describe('and the item is marked complete', () => {
      beforeEach(() => {
        data.planner_override = {
          marked_complete: true,
        }
      })

      it('returns true', () => {
        expect(subject().isCompleted()).toEqual(true)
      })
    })

    describe('and the item is not marked complete', () => {
      beforeEach(() => {
        data.planner_override = {
          marked_complete: false,
        }
      })

      it('returns false', () => {
        expect(subject().isCompleted()).toEqual(false)
      })
    })
  })
})

describe('commonEventFactory cross-shard context matching', () => {
  it('matches context when API returns consistent IDs', () => {
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
    expect(event.calendarEvent.effective_context_code).toBe('course_97700000000059053')
    expect(event.calendarEvent.all_context_codes).toBe('course_97700000000059053')
  })

  it('matches context in multi-context events', () => {
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
    expect(event.calendarEvent.effective_context_code).toBe('course_97700000000059053,course_97700000000059054')
    expect(event.calendarEvent.all_context_codes).toBe('course_97700000000059053,course_97700000000059054')
  })

  it('returns null when context cannot be matched', () => {
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

  it('does not match different IDs', () => {
    const event = commonEventFactory(
      {
        title: 'Should not match',
        start_at: '2026-01-26T18:00:00Z',
        effective_context_code: 'course_97700000000059053',
      },
      [{asset_string: 'course_590'}],
    )
    expect(event).toBeNull()
  })
})
