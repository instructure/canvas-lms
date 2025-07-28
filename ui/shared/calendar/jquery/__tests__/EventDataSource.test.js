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

import EventDataSource from '../EventDataSource'
import moment from 'moment-timezone'
import $ from 'jquery'
import fakeENV from '@canvas/test-utils/fakeENV'

// Mock timezone functions
jest.mock('@instructure/moment-utils', () => ({
  configure: jest.fn(),
  parse: date => new Date(date),
  format: jest.fn(),
  fudgeDateForProfileTimezone: date => date,
  unfudgeDateForProfileTimezone: date => date,
}))

describe('EventDataSource', () => {
  let source
  let server
  let date1, date2, date3, date4
  let contexts
  let originalZone

  beforeEach(() => {
    originalZone = moment.tz.guess()
    moment.tz.setDefault('America/Denver')

    fakeENV.setup({
      TIMEZONE: 'America/Denver',
      CONTEXT_TIMEZONE: 'America/Denver',
      TIMEZONE_OFFSET: -420, // MST offset in minutes
    })

    // Create test dates in Denver timezone
    date1 = moment.tz('2015-11-01T20:00:00', 'America/Denver')
    date2 = moment.tz('2015-11-02T20:00:00', 'America/Denver')
    date3 = moment.tz('2015-11-03T20:00:00', 'America/Denver')
    date4 = moment.tz('2015-11-04T20:00:00', 'America/Denver')

    source = new EventDataSource([
      {asset_string: 'course_1'},
      {asset_string: 'course_2'},
      {asset_string: 'course_3'},
      {asset_string: 'group_1'},
    ])
    contexts = ['course_1', 'course_2', 'course_3']

    server = {
      calendarEvents: [],
      assignments: [],
      lastQuery: null,
      reset() {
        this.calendarEvents = []
        this.assignments = []
        this.lastQuery = null
      },
      addCalendarEvent(context_code, id, start_at) {
        this.calendarEvents.push({
          context_code,
          calendar_event: {
            id: `calendar_event_${id}`,
            start_at,
          },
        })
      },
      addAssignment(context_code, id, due_at) {
        this.assignments.push({
          context_code,
          assignment: {
            id: `assignment_${id}`,
            due_at,
          },
        })
      },
      addPlannerItem(context_type, context_id, plannable_type, plannable_id, title, todo_date) {
        const item = {
          plannable_type,
          plannable_id,
          plannable: {
            title,
            todo_date,
          },
        }
        item[`${context_type}_id`] = context_id
        return this.calendarEvents.push(item)
      },
    }

    source.startFetch = jest.fn((requests, dataCB, doneCB) => {
      const {start_date, end_date, undated} = requests[0][1]
      server.lastQuery = {
        start_date,
        end_date,
        undated,
      }

      // Filter assignments based on course pacing settings
      const filteredAssignments = server.assignments.filter(assignment => {
        const context = ENV.CALENDAR?.CONTEXTS?.find(
          ctx => ctx.asset_string === assignment.context_code,
        )
        return !context?.course_pacing_enabled || context?.user_is_student
      })

      if (filteredAssignments.length > 0) {
        dataCB(filteredAssignments, null, {type: 'assignments'})
      }

      if (server.calendarEvents.length > 0) {
        dataCB(server.calendarEvents, null, {type: 'events'})
      }

      doneCB()
    })

    // Mock jQuery's fullCalendar
    $.fullCalendar = {
      moment: date => moment(date),
    }
  })

  afterEach(() => {
    moment.tz.setDefault(originalZone)
    fakeENV.teardown()
    server?.restore?.()
  })

  describe('overlapping ranges', () => {
    it('shifts start to end of overlap when ranges overlap at start', () => {
      source.getEvents(date1, date2, contexts, () => {})
      source.getEvents(date1, date4, contexts, () => {})
      expect(server.lastQuery.start_date).toBe(date2.toISOString())
    })

    it('leaves start alone when no overlap at start', () => {
      source.getEvents(date3, date4, contexts, () => {})
      expect(server.lastQuery.start_date).toBe(date3.toISOString())
    })

    it('leaves end alone when no overlap at end', () => {
      source.getEvents(date3, date4, contexts, () => {})
      source.getEvents(date1, date2, contexts, () => {})
      expect(server.lastQuery.end_date).toBe(date2.toISOString())
    })

    it('shifts end to start of overlap when ranges overlap at end', () => {
      source.getEvents(date3, date4, contexts, () => {})
      source.getEvents(date1, date4, contexts, () => {})
      expect(server.lastQuery.end_date).toBe(date3.toISOString())
    })

    it('leaves ends alone with fully interior overlap', () => {
      source.getEvents(date2, date3, contexts, () => {})
      source.getEvents(date1, date4, contexts, () => {})
      expect(server.lastQuery.start_date).toBe(date1.toISOString())
      expect(server.lastQuery.end_date).toBe(date4.toISOString())
    })

    it('moves both ends if necessary', () => {
      source.getEvents(date1, date2, contexts, () => {})
      source.getEvents(date3, date4, contexts, () => {})
      source.getEvents(date1, date4, contexts, () => {})
      expect(server.lastQuery.start_date).toBe(date2.toISOString())
      expect(server.lastQuery.end_date).toBe(date3.toISOString())
    })

    it('makes no query with full overlap', () => {
      source.getEvents(date1, date3, contexts, () => {})
      source.getEvents(date2, date4, contexts, () => {})
      server.reset()
      source.getEvents(date1, date4, contexts, () => {})
      expect(server.lastQuery).toBeNull()
    })
  })

  describe('course pacing assignments', () => {
    beforeEach(() => {
      window.ENV = {
        CALENDAR: {
          CONTEXTS: [
            {
              asset_string: 'course_1',
              course_pacing_enabled: true,
              user_is_student: false,
            },
          ],
        },
      }
    })

    afterEach(() => {
      delete window.ENV
    })

    it('filters out course pacing assignments for teachers', () => {
      server.addAssignment('course_1', '1', date1.toISOString())
      source.getEvents(date1, date2, ['course_1'], list => {
        expect(list).toHaveLength(0)
      })
    })
  })
})
