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

import EventDataSource from 'compiled/calendar/EventDataSource'
import fcUtil from 'compiled/util/fcUtil'
import tz from 'timezone'
import denver from 'timezone/America/Denver'

QUnit.module('EventDataSource: getEvents', {
  setup() {
    this.snapshot = tz.snapshot()
    tz.changeZone(denver, 'America/Denver')
    this.date1 = fcUtil.wrap('2015-11-01T20:00:00-07:00')
    this.date2 = fcUtil.wrap('2015-11-02T20:00:00-07:00')
    this.date3 = fcUtil.wrap('2015-11-03T20:00:00-07:00')
    this.date4 = fcUtil.wrap('2015-11-04T20:00:00-07:00')

    // create the data source with a couple of recognized contexts. we'll use
    // those same context codes in querying
    this.source = new EventDataSource([{asset_string: 'course_1'}, {asset_string: 'course_2'}])
    this.contexts = ['course_1', 'course_2']

    // a container for stubbing queries, along with helpers to populate
    // the stubbed results in individual specs and a slot for the most recent
    // query (distilled)
    this.server = {
      calendarEvents: [],
      assignments: [],
      lastQuery: null,
      reset() {
        this.calendarEvents = []
        this.assignments = []
        this.lastQuery = null
      },
      addCalendarEvent(context_code, id, start_at) {
        return this.calendarEvents.push({
          context_code,
          calendar_event: {
            id,
            start_at
          }
        })
      },
      addAssignment(context_code, id, due_at) {
        return this.assignments.push({
          context_code,
          assignment: {
            id,
            due_at
          }
        })
      }
    }

    // stub the fetch method on the source to just use our stubbed query
    // results, and also to record the query made
    this.source.startFetch = (requests, dataCB, doneCB, _) => {
      const {start_date, end_date, undated} = requests[0][1]
      this.server.lastQuery = {
        start_date,
        end_date,
        undated
      }
      dataCB(this.server.calendarEvents, null, {type: 'events'})
      dataCB(this.server.assignments, null, {type: 'assignments'})
      doneCB()
    }
  },

  teardown() {
    tz.restore(this.snapshot)
  }
})

test('addEventToCache handles cases where the contextCode returns a list', function() {
  const fakeEvent = {
    contextCode() {
      return 'course_1,course_2'
    },
    id: 42
  }
  this.source.addEventToCache(fakeEvent)
  ok(this.source.cache.contexts.course_1.events[42])
})

test('addEventToCache handles the case where contextCode contains context not in the cache', function() {
  const fakeEvent = {
    contextCode() {
      return 'course_3,course_2'
    },
    id: 42
  }
  this.source.addEventToCache(fakeEvent)
  ok(this.source.cache.contexts.course_2.events[42])
})

test('addEventToCache handles cases where the contextCode is a single item', function() {
  const fakeEvent = {
    contextCode() {
      return 'course_1'
    },
    id: 42
  }
  this.source.addEventToCache(fakeEvent)
  ok(this.source.cache.contexts.course_1.events[42])
})

test('overlapping ranges: overlap at start shifts start to end of overlap', function() {
  this.source.getEvents(this.date1, this.date2, this.contexts, () => {})
  this.source.getEvents(this.date1, this.date4, this.contexts, () => {})
  equal(this.server.lastQuery.start_date, fcUtil.unwrap(this.date2).toISOString())
})

test('overlapping ranges: no overlap at start leaves start alone', function() {
  this.source.getEvents(this.date1, this.date2, this.contexts, () => {})
  this.source.getEvents(this.date3, this.date4, this.contexts, () => {})
  equal(this.server.lastQuery.start_date, fcUtil.unwrap(this.date3).toISOString())
})

test('overlapping ranges: no overlap at end leaves end alone', function() {
  this.source.getEvents(this.date3, this.date4, this.contexts, () => {})
  this.source.getEvents(this.date1, this.date2, this.contexts, () => {})
  equal(this.server.lastQuery.end_date, fcUtil.unwrap(this.date2).toISOString())
})

test('overlapping ranges: overlap at end shifts end to start of overlap', function() {
  this.source.getEvents(this.date3, this.date4, this.contexts, () => {})
  this.source.getEvents(this.date1, this.date4, this.contexts, () => {})
  equal(this.server.lastQuery.end_date, fcUtil.unwrap(this.date3).toISOString())
})

test('overlapping ranges: fully interior overlap leaves ends alone', function() {
  this.source.getEvents(this.date2, this.date3, this.contexts, () => {})
  this.source.getEvents(this.date1, this.date4, this.contexts, () => {})
  equal(this.server.lastQuery.start_date, fcUtil.unwrap(this.date1).toISOString())
  equal(this.server.lastQuery.end_date, fcUtil.unwrap(this.date4).toISOString())
})

test('overlapping ranges: both ends move if necessary', function() {
  this.source.getEvents(this.date1, this.date2, this.contexts, () => {})
  this.source.getEvents(this.date3, this.date4, this.contexts, () => {})
  this.source.getEvents(this.date1, this.date4, this.contexts, () => {})
  equal(this.server.lastQuery.start_date, fcUtil.unwrap(this.date2).toISOString())
  equal(this.server.lastQuery.end_date, fcUtil.unwrap(this.date3).toISOString())
})

test('overlapping ranges: full overlap means no query', function() {
  this.source.getEvents(this.date1, this.date3, this.contexts, () => {})
  this.source.getEvents(this.date2, this.date4, this.contexts, () => {})
  this.server.reset()
  this.source.getEvents(this.date1, this.date4, this.contexts, () => {})
  ok(!this.server.lastQuery)
})

test('date-only boundaries: date-only end is treated as midnight in profile timezone (excludes that date)', function() {
  const end = fcUtil
    .clone(this.date4)
    .stripTime()
    .stripZone()
  this.server.addCalendarEvent('course_1', '1', fcUtil.unwrap(this.date3).toISOString())
  this.server.addCalendarEvent('course_2', '2', fcUtil.unwrap(this.date4).toISOString())
  this.source.getEvents(this.date1, end, this.contexts, list => {
    equal(list.length, 1)
    equal(list[0].id, 'calendar_event_1')
  })
  equal(this.server.lastQuery.end_date, '2015-11-04T07:00:00.000Z')
})

test('date-only boundaries: date-only start is treated as midnight in profile timezone (includes that date)', function() {
  const start = fcUtil
    .clone(this.date2)
    .stripTime()
    .stripZone()
  this.server.addCalendarEvent('course_1', '1', fcUtil.unwrap(this.date1).toISOString())
  this.server.addCalendarEvent('course_2', '2', fcUtil.unwrap(this.date2).toISOString())
  this.source.getEvents(start, this.date4, this.contexts, list => {
    equal(list.length, 1)
    equal(list[0].id, 'calendar_event_2')
  })
  equal(this.server.lastQuery.start_date, '2015-11-02T07:00:00.000Z')
})

test('pagination: both pages final returns full range and leaves nextPageDate unset', function() {
  this.server.addCalendarEvent('course_1', '1', fcUtil.unwrap(this.date1).toISOString())
  this.server.addCalendarEvent('course_2', '2', fcUtil.unwrap(this.date2).toISOString())
  this.server.addAssignment('course_2', '3', fcUtil.unwrap(this.date3).toISOString())
  return this.source.getEvents(this.date1, this.date4, this.contexts, list => {
    ok(!list.nextPageDate)
    equal(list.length, 3)
  })
})

test('pagination: one page final sets nextPageDate and returns only up to nextPageDate (exclusive)', function() {
  // since the max calendarEvent date is @date2, nextPageDate will be @date2
  // and nothing >= @date2 will be included
  this.server.addCalendarEvent('course_1', '1', fcUtil.unwrap(this.date1).toISOString())
  this.server.addCalendarEvent('course_2', '2', fcUtil.unwrap(this.date2).toISOString())
  this.server.addAssignment('course_1', '3', fcUtil.unwrap(this.date1).toISOString())
  this.server.addAssignment('course_2', '4', fcUtil.unwrap(this.date2).toISOString())
  this.server.addAssignment('course_2', '5', fcUtil.unwrap(this.date3).toISOString())
  this.server.calendarEvents.next = true
  return this.source.getEvents(this.date1, this.date4, this.contexts, list => {
    equal(+list.nextPageDate, +this.date2)
    equal(list.length, 2)
    ok(['calendar_event_1', 'assignment_3'].indexOf(list[0].id) >= 0)
    ok(['calendar_event_1', 'assignment_3'].indexOf(list[1].id) >= 0)
  })
})

test('pagination: both pages final sets nextPageDate and returns only up to nextPageDate (exclusive)', function() {
  // since assignments has the smallest max date at @date2, nextPageDate will be
  // @date2 and nothing >= @date2 will be included
  this.server.addCalendarEvent('course_1', '1', fcUtil.unwrap(this.date1).toISOString())
  this.server.addCalendarEvent('course_2', '2', fcUtil.unwrap(this.date2).toISOString())
  this.server.addAssignment('course_1', '3', fcUtil.unwrap(this.date1).toISOString())
  this.server.addAssignment('course_2', '4', fcUtil.unwrap(this.date2).toISOString())
  this.server.addAssignment('course_2', '5', fcUtil.unwrap(this.date3).toISOString())
  this.server.calendarEvents.next = true
  this.server.assignments.next = true
  return this.source.getEvents(this.date1, this.date4, this.contexts, list => {
    equal(+list.nextPageDate, +this.date2)
    equal(list.length, 2)
    ok(['calendar_event_1', 'assignment_3'].indexOf(list[0].id) >= 0)
    ok(['calendar_event_1', 'assignment_3'].indexOf(list[1].id) >= 0)
  })
})

test('pagination: calls data callback with each page of data if set', function() {
  this.server.addCalendarEvent('course_1', '1', fcUtil.unwrap(this.date1).toISOString())
  this.server.addAssignment('course_2', '3', fcUtil.unwrap(this.date3).toISOString())
  let pages = 0
  return this.source.getEvents(
    this.date1,
    this.date4,
    this.contexts,
    list => {
      equal(list.length, 2)
      equal(pages, 2)
    },
    list => {
      pages += 1
      equal(list.length, 1)
    }
  )
})

test('indexParams filters appointment_group_ids from params', function() {
  const p = this.source.indexParams({blah: 'blah', context_codes: ['course_1', 'appointment_group_2', 'group_3', 'appointment_group_1337']})
  equal(p.blah, 'blah')
  deepEqual(p.context_codes, ['course_1', 'group_3'])
  equal(p.appointment_group_ids, '2,1337')
})