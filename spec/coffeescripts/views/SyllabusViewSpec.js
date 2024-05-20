/*
 * Copyright (C) 2013 - present Instructure, Inc.
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

/* eslint-disable qunit/no-global-expect */
/* eslint-disable jest/valid-expect */
import $ from 'jquery'
import 'jquery-migrate'
import _ from 'lodash'
import tzInTest from '@canvas/datetime/specHelpers'
import timezone from 'timezone'
import denver from 'timezone/America/Denver'
import newYork from 'timezone/America/New_York'
import SyllabusBehaviors from '@canvas/syllabus/backbone/behaviors/SyllabusBehaviors'
import SyllabusCollection from 'ui/features/syllabus/backbone/collections/SyllabusCollection'
import SyllabusCalendarEventsCollection from 'ui/features/syllabus/backbone/collections/SyllabusCalendarEventsCollection'
import SyllabusAppointmentGroupsCollection from 'ui/features/syllabus/backbone/collections/SyllabusAppointmentGroupsCollection'
import SyllabusPlannerCollection from 'ui/features/syllabus/backbone/collections/SyllabusPlannerCollection'
import SyllabusView from 'ui/features/syllabus/backbone/views/SyllabusView'
import SyllabusViewPrerendered from './SyllabusViewPrerendered'
import fakeENV from 'helpers/fakeENV'
import '@canvas/jquery/jquery.simulate'
import {getI18nFormats} from 'ui/boot/initializers/configureDateTime'

function setupServerResponses() {
  const server = sinon.fakeServer.create()

  // Fake calendar_events endpoint
  let {assignments} = SyllabusViewPrerendered
  let {events} = SyllabusViewPrerendered
  function calendar_events_endpoint(request) {
    let more, response
    if (request.url.match(/.*\?.*\btype=assignment\b/)) {
      response = assignments.slice(0, 2)
      assignments = assignments.slice(2)
      more = assignments.length > 0
    } else if (request.url.match(/.*\?.*\btype=event\b/)) {
      response = events.slice(0, 2)
      events = events.slice(2)
      more = events.length > 0
    }

    let links = `<${request.url}>; rel=\"first\"`
    if (more) {
      links += `,<${request.url}>; rel=\"next\"`
    }

    return request.respond(
      200,
      {
        'Content-Type': 'application/json',
        Link: links,
      },
      JSON.stringify(response)
    )
  }

  // Fake appointment_groups endpoint
  let {appointment_groups} = SyllabusViewPrerendered
  function appointment_groups_endpoint(request) {
    const response = appointment_groups.slice(0, 2)
    appointment_groups = appointment_groups.slice(2)
    const more = appointment_groups.length > 0

    let links = `<${request.url}>; rel=\"first\"`
    if (more) {
      links += `,<${request.url}>; rel=\"next\"`
    }

    return request.respond(
      200,
      {
        'Content-Type': 'application/json',
        Link: links,
      },
      JSON.stringify(response)
    )
  }

  let {planner_items} = SyllabusViewPrerendered
  function planner_items_endpoint(request) {
    const response = planner_items.slice(0, 2)
    planner_items = planner_items.slice(2)
    const more = planner_items.length > 0

    let links = `<${request.url}>; rel=\"first\"`
    if (more) {
      links += `,<${request.url}>; rel=\"next\"`
    }

    return request.respond(
      200,
      {
        'Content-Type': 'application/json',
        Link: links,
      },
      JSON.stringify(response)
    )
  }

  server.respondWith(/\/api\/v1\/calendar_events($|\?)/, calendar_events_endpoint)
  server.respondWith(/\/api\/v1\/appointment_groups($|\?)/, appointment_groups_endpoint)
  server.respondWith(/\/api\/v1\/planner\/items($|\?)/, planner_items_endpoint)
  return server
}

QUnit.module('Syllabus', {
  setup() {
    fakeENV.setup({TIMEZONE: 'America/Denver', CONTEXT_TIMEZONE: 'America/New_York'})
    // Setup stubs/mocks
    this.server = setupServerResponses()

    tzInTest.configureAndRestoreLater({
      tz: timezone(denver, 'America/Denver'),
      tzData: {
        'America/Denver': denver,
        'America/New_York': newYork,
      },
      formats: getI18nFormats(),
    })

    this.clock = sinon.useFakeTimers(new Date(2012, 0, 23, 15, 30).getTime())

    // Add pre-rendered html elements
    const $fixtures = $('#fixtures')

    this.jumpToToday = $(SyllabusViewPrerendered.jumpToToday)
    this.jumpToToday.appendTo($fixtures)

    this.miniMonth = $(SyllabusViewPrerendered.miniMonth())
    this.miniMonth.appendTo($fixtures)

    this.syllabusContainer = $(SyllabusViewPrerendered.syllabusContainer)
    this.syllabusContainer.appendTo($fixtures)

    // Fill the collections
    const collections = [
      new SyllabusCalendarEventsCollection([ENV.context_asset_string], 'event'),
      new SyllabusCalendarEventsCollection([ENV.context_asset_string], 'assignment'),
      new SyllabusAppointmentGroupsCollection([ENV.context_asset_string], 'reservable'),
      new SyllabusAppointmentGroupsCollection([ENV.context_asset_string], 'manageable'),
      new SyllabusPlannerCollection([ENV.context_asset_string]),
    ]

    const acollection = new SyllabusCollection(collections)

    _.each(collections, collection => {
      const error = () => {
        ok(false, 'ajax call failed')
      }

      const success = () => {
        if (collection.canFetch('next')) {
          collection.fetch({
            page: 'next',
            success,
            error,
          })

          // need to manually respond to calls made during a previous response
          return this.server.respond()
        }
      }

      return collection.fetch({
        data: {
          per_page: 2,
        },
        success,
        error,
      })
    })

    this.server.respond()

    // Render and bind behaviors
    this.view = new SyllabusView({
      el: '#syllabusTableBody',
      collection: acollection,
    })
  },

  teardown() {
    fakeENV.teardown()
    this.syllabusContainer.remove()
    this.miniMonth.remove()
    this.jumpToToday.remove()
    this.clock.restore()
    tzInTest.restore()
    this.server.restore()
    document.getElementById('fixtures').innerHTML = ''
  },

  render() {
    this.view.render()

    SyllabusBehaviors.bindToMiniCalendar()
    SyllabusBehaviors.bindToSyllabus()
  },

  renderAssertions() {
    expect(26)
    // rendering
    const syllabus = $('#syllabusTableBody')
    ok(syllabus.length, 'syllabus - syllabus added to the dom')
    ok(syllabus.is(':visible'), 'syllabus - syllabus visible')

    const dates = $('tr.date', syllabus)
    equal(dates.length, 22, 'dates - dates render')
    equal($('td.day_date', dates).length, 6, 'dates - coalesce')

    const assignments = $('tr.syllabus_assignment', syllabus)
    equal(assignments.length, 10, 'events - all assignments rendered')
    if (this.view.can_read) {
      equal($('td.name a', assignments).length, 10, 'events - link rendered for each assignment')
    } else {
      equal($('td.name a', assignments).length, 0, 'events - link not rendered for each assignment')
    }

    const graded_discussions = $(
      'tr.syllabus_assignment.assignment_type_discussion_topic',
      syllabus
    )
    equal(graded_discussions.length, 1, 'graded discussions rendered')
    const quizzes = $('tr.syllabus_assignment.assignment_type_quiz', syllabus)
    equal(quizzes.length, 1, 'quizzes rendered')

    const events = $('tr.syllabus_event', syllabus)
    equal(events.length, 6, 'events - all events rendered')
    if (this.view.can_read && this.view.is_valid_user) {
      equal($('td.name a', events).length, 6, 'events - link rendered for each event')
    } else {
      equal($('td.name a', events).length, 0, 'events - link not rendered for each event')
    }

    const discussions = $('tr.syllabus_discussion_topic', syllabus)
    equal(discussions.length, 3, 'discussions - all discussions rendered')
    if (this.view.can_read && this.view.is_valid_user) {
      equal($('td.name a', discussions).length, 3, 'discussions - link rendered for each event')
    } else {
      equal($('td.name a', discussions).length, 0, 'discussions - link not rendered for each event')
    }

    const pages = $('tr.syllabus_wiki_page', syllabus)
    equal(pages.length, 3, 'pages - all pages rendered')
    if (this.view.can_read && this.view.is_valid_user) {
      equal($('td.name a', pages).length, 3, 'pages - link rendered for each event')
    } else {
      equal($('td.name a', pages).length, 0, 'pages - link not rendered for each event')
    }

    // mini calendar dates - has event
    let expected = $(
      '#mini_day_2012_01_01, #mini_day_2012_01_11, #mini_day_2012_01_23, #mini_day_2012_01_30, #mini_day_2012_01_31'
    )
    let actual = $('.mini_calendar_day.has_event')
    equal(expected.length, 5, 'mini calendar - expected dates with events found')
    deepEqual(actual.toArray(), expected.toArray(), 'mini calendar - dates with events highlighted')

    // today
    expected = $('#mini_day_2012_01_23')
    actual = $('.mini_calendar_day.related')
    equal(expected.length, 1, 'today - today found')
    deepEqual(actual.toArray(), expected.toArray(), 'today - today highlighted')

    expected = $('.events_2012_01_23')
    actual = $('tr.date.related')
    equal(expected.length, 2, "today - today's events found")
    deepEqual(actual.toArray(), expected.toArray(), "today - today's events highlighted")

    expected = $('.events_2012_01_01, .events_2012_01_11')
    actual = $('tr.date.date_passed')

    equal(expected.length, 12, 'passed events - passed events found')
    deepEqual(
      actual.toArray(),
      expected.toArray(),
      'passed events - events before today marked as passed'
    )

    // context-sensitive datetime titles
    const assignment_ts = $('.events_2012_01_01.related-assignment_1 .dates > span:nth-child(1)')
    equal(assignment_ts.text(), '10am', 'assignment - local time in table')
    equal(
      assignment_ts.data('html-tooltip-title'),
      'Local: Jan 1 at 10am<br>Course: Jan 1 at 12pm',
      'assignment - correct local and course times given'
    )

    const event_ts = $('.events_2012_01_01.related-appointment_group_1 .dates > span:nth-child(1)')
    equal(event_ts.text(), ' 8am', 'event - local time in table')
    equal(
      event_ts.data('html-tooltip-title'),
      'Local: Jan 1 at 8am<br>Course: Jan 1 at 10am',
      'event - correct local and course times given'
    )
  },
})

test('render (user public course)', function () {
  this.view.can_read = true // public course -- can read
  this.view.is_valid_user = true // user - enrolled (can read)

  this.render()
  this.renderAssertions()
})

test('render (anonymous public course)', function () {
  this.view.can_read = true // public course -- can read
  this.view.is_valid_user = false // anonymous

  this.render()
  this.renderAssertions()
})

test('render (user public syllabus)', function () {
  this.view.can_read = false // public syllabus -- cannot read
  this.view.is_valid_user = true // user - non-enrolled (cannot read)

  this.render()
  this.renderAssertions()
})

test('render (anonymous public syllabus)', function () {
  this.view.can_read = false // public syllabus -- cannot read
  this.view.is_valid_user = false // anonymous

  this.render()
  this.renderAssertions()
})

test('syllabus interaction', function () {
  expect(14)

  this.view.is_public_course = true
  this.view.can_participate = true
  this.render()

  // dated hover
  const event = $('.events_2012_01_11')
  const date = $('#mini_day_2012_01_11')
  equal(event.length, 2, 'hover dated syllabus row - event found')
  equal(date.length, 1, 'hover dated syllabus row - mini calendar day found')
  event.first().simulate('mouseover')

  let expected = event
  let actual = $('tr.date.related')
  deepEqual(actual.toArray(), expected.toArray(), 'hover dated syllabus row - event highlighted')

  expected = date
  actual = $('.mini_calendar_day.related')
  deepEqual(
    actual.toArray(),
    expected.toArray(),
    'hover dated syllabus row - mini calendar day highlighted'
  )

  // undated hover
  const undated = $(
    'tr.date:not(.events_2012_01_01, .events_2012_01_11, .events_2012_01_23, .events_2012_01_30, .events_2012_01_31)'
  )
  equal(undated.length, 2, 'hover undated syllabus row - row found')

  undated.simulate('mouseover')

  expected = []
  actual = $('tr.date.related')
  deepEqual(actual.toArray(), expected, 'hover undated syllabus row - no events highlighted')

  expected = []
  actual = $('.mini_calendar_day.related')
  deepEqual(
    actual.toArray(),
    expected,
    'hover undated syllabus row - no mini calendar days highlighted'
  )

  // event hover
  const assignment = $('tr.related-assignment_1:not(.special_date)')
  equal(assignment.length, 1, 'hover event - assignment event found')

  assignment.simulate('mouseover')

  expected = $('tr.related-assignment_1.special_date')
  equal(expected.length, 5, 'hover event - special dates for assignment found')

  actual = $('tr.syllabus_assignment.related_event')
  deepEqual(
    actual.toArray(),
    expected.toArray(),
    'hover event - special dates for assignment highlighted'
  )

  // override hover
  const override = $('tr.related-assignment_1.special_date:first')
  equal(override.length, 1, 'hover special date - found special date')

  override.simulate('mouseover')
  expected = $('tr.related-assignment_1').not(override)
  actual = $('tr.syllabus_assignment.related_event')
  equal(expected.length, 5, 'hover special date - related assignment and special dates found')
  deepEqual(
    actual.toArray(),
    expected.toArray(),
    'hover special date - related assignment and special dates highlighted'
  )

  // event/override unhover
  override.simulate('mouseout')

  expected = []
  actual = $('tr.syllabus_assignment.related_event')
  deepEqual(actual.toArray(), expected, 'unhover event - events no longer highlighted')
})

test('mini calendar', function () {
  expect(27)

  this.view.is_public_course = true
  this.view.can_participate = true
  this.render()

  // hover non-event date
  const nonEventMiniDay = $('#mini_day_2012_01_17')
  equal(nonEventMiniDay.length, 1, 'non-event day hover - found')

  nonEventMiniDay.children('.day_wrapper').simulate('mouseover')
  deepEqual(
    $('.mini_calendar_day.related').toArray(),
    nonEventMiniDay.toArray(),
    'non-event day hover - highlighted'
  )

  // hover event date
  const eventMiniDay = $('#mini_day_2012_01_30')
  equal(eventMiniDay.length, 1, 'event day hover - event day found')

  eventMiniDay.children('.day_wrapper').simulate('mouseover')
  deepEqual(
    $('.mini_calendar_day.related').toArray(),
    eventMiniDay.toArray(),
    'event day hover - event day highlighted'
  )

  let expected = $('.events_2012_01_30')
  let actual = $('tr.date.related')
  equal(expected.length, 4, 'event day hover - syllabus event found')
  deepEqual(actual.toArray(), expected.toArray(), 'event day hover - syllabus event highlighted')

  // unhover the event date
  eventMiniDay.children('.day_wrapper').simulate('mouseout')

  expected = []
  actual = $('.mini_calendar_day.related')
  deepEqual(
    actual.toArray(),
    expected,
    'event day unhover - mini calendar day no longer highlighted'
  )

  expected = []
  actual = $('tr.date.related')
  deepEqual(actual.toArray(), expected, 'event day unhover - syllabus events no longer highlighted')

  // previous month link
  const prevMonthLink = $('.prev_month_link')
  equal(prevMonthLink.length, 1, 'previous month - link found')

  prevMonthLink.simulate('click')

  equal(parseInt($('.month_number').text(), 10), 12, 'previous month - month changed to December')
  equal(parseInt($('.year_number').text(), 10), 2011, 'previous month - year changed to 2011')

  expected = $('#mini_day_2012_01_01')
  actual = $('.mini_calendar_day.has_event')
  equal(expected.length, 1, 'previous month - expected dates with events found')
  deepEqual(
    actual.toArray(),
    expected.toArray(),
    'previous month - expected dates with events highlighted'
  )

  // next month link
  const nextMonthLink = $('.next_month_link')
  equal(nextMonthLink.length, 1, 'next month - link found')

  nextMonthLink.simulate('click')
  nextMonthLink.simulate('click')

  equal(parseInt($('.month_number').text(), 10), 2, 'next month - month changed to February')
  equal(parseInt($('.year_number').text(), 10), 2012, 'next month - year changed to 2012')

  expected = $('#mini_day_2012_01_30, #mini_day_2012_01_31')
  actual = $('.mini_calendar_day.has_event')
  equal(expected.length, 2, 'next month - expected dates with events found')
  deepEqual(
    actual.toArray(),
    expected.toArray(),
    'next month - expected dates with events highlighted'
  )

  // jump to today link
  const jumpToTodayLink = $('a.jump_to_today_link')
  equal(jumpToTodayLink.length, 1, 'jump to today - link found')

  jumpToTodayLink.simulate('click')

  equal(parseInt($('.month_number').text(), 10), 1, 'jump to today - month changed to January')
  equal(parseInt($('.year_number').text(), 10), 2012, 'jump to today - year left at 2012')

  expected = $(
    '#mini_day_2012_01_01, #mini_day_2012_01_11, #mini_day_2012_01_23, #mini_day_2012_01_30, #mini_day_2012_01_31'
  )
  actual = $('.mini_calendar_day.has_event')
  equal(expected.length, 5, 'jump to today - expected has event dates found')
  deepEqual(
    actual.toArray(),
    expected.toArray(),
    'jump to today - expected dates with events highlighted'
  )

  expected = $('#mini_day_2012_01_23')
  actual = $('.mini_calendar_day.selected')
  equal(expected.length, 1, 'jump to today - today found')
  deepEqual(actual.toArray(), expected.toArray(), 'jump to today - today highlighted')

  expected = $('.events_2012_01_23')
  actual = $('tr.date.selected')
  equal(expected.length, 2, "jump to today - today's events found")

  deepEqual(actual.toArray(), expected.toArray(), "jump to today - today's events highlighted")
})
