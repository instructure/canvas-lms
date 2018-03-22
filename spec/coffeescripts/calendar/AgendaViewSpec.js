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

import $ from 'jquery'
import {isArray, isObject, uniq} from 'lodash'
import tz from 'timezone'
import fcUtil from 'compiled/util/fcUtil'
import denver from 'timezone/America/Denver'
import juneau from 'timezone/America/Juneau'
import french from 'timezone/fr_FR'
import AgendaView from 'compiled/views/calendar/AgendaView'
import Calendar from 'compiled/calendar/Calendar'
import EventDataSource from 'compiled/calendar/EventDataSource'
import eventResponse from 'helpers/ajax_mocks/api/v1/calendarEvents'
import assignmentResponse from 'helpers/ajax_mocks/api/v1/calendarAssignments'
import I18nStubber from 'helpers/I18nStubber'
import fakeENV from 'helpers/fakeENV'

const loadEventPage = (server, includeNext = false) =>
  sendCustomEvents(server, eventResponse, assignmentResponse, includeNext)
var sendCustomEvents = function(server, events, assignments, includeNext = false) {
  const requestIndex = server.requests.length - 2
  server.requests[requestIndex].respond(
    200,
    {
      'Content-Type': 'application/json',
      Link: `</api/magic>; rel="${includeNext ? 'next' : 'current'}"`
    },
    events
  )
  return server.requests[requestIndex + 1].respond(
    200,
    {'Content-Type': 'application/json'},
    assignments
  )
}

QUnit.module('AgendaView', {
  setup() {
    this.container = $('<div />', {id: 'agenda-wrapper'}).appendTo('#fixtures')
    this.contexts = [
      {asset_string: 'user_1'},
      {asset_string: 'course_2'},
      {asset_string: 'group_3'}
    ]
    this.contextCodes = ['user_1', 'course_2', 'group_3']
    this.startDate = fcUtil.now()
    this.startDate.minute(1)
    this.startDate.year(2001)
    this.dataSource = new EventDataSource(this.contexts)
    this.server = sinon.fakeServer.create()
    this.snapshot = tz.snapshot()
    tz.changeZone(denver, 'America/Denver')
    I18nStubber.pushFrame()
    fakeENV.setup({CALENDAR: {}})
  },
  teardown() {
    this.container.remove()
    this.server.restore()
    tz.restore(this.snapshot)
    I18nStubber.popFrame()
    fakeENV.teardown()
  }
})

test('should render results', function() {
  const view = new AgendaView({
    el: this.container,
    dataSource: this.dataSource
  })
  view.fetch(this.contextCodes, this.startDate)
  loadEventPage(this.server)

  // should render all events
  ok(
    this.container.find('.agenda-event__item-container').length === 18,
    'finds 18 agenda-event__item-containers'
  )

  // should bin results by day
  ok(this.container.find('.agenda-date').length === view.toJSON().days.length)
  // should not show "load more" if there are no more pages
  ok(!this.container.find('.agenda-load-btn').length, 'does not find the loader')
})

test('should show "load more" if there are more results', function() {
  const view = new AgendaView({
    el: this.container,
    dataSource: this.dataSource
  })
  view.fetch(this.contextCodes, this.startDate)
  loadEventPage(this.server, true)
  ok(this.container.find('.agenda-load-btn').length)
})

test('toJSON should properly serialize results', function() {
  I18nStubber.stub('en', {
    'date.formats.short_with_weekday': '%a, %b %-d',
    'date.abbr_day_names.1': 'Mon',
    'date.abbr_month_names.10': 'Oct'
  })
  const view = new AgendaView({
    el: this.container,
    dataSource: this.dataSource
  })
  view.fetch(this.contextCodes, this.startDate)
  loadEventPage(this.server)
  const serialized = view.toJSON()
  ok(isArray(serialized.days), 'days is an array')
  ok(isObject(serialized.meta), 'meta is an object')
  ok(uniq(serialized.days).length === serialized.days.length, 'does not duplicate dates')
  ok(serialized.days[0].date === 'Mon, Oct 7', 'finds the correct first day')
  ok(
    serialized.meta.hasOwnProperty('better_scheduler'),
    'contains a property indicating better_scheduler is active or not'
  )
  serialized.days.forEach(d => ok(d.events.length, 'every day has events'))
})

test('should only include days on page breaks once', function() {
  let i
  const view = new AgendaView({
    el: this.container,
    dataSource: this.dataSource
  })
  window.view = view
  view.fetch(this.contextCodes, this.startDate)
  let id = 1
  const addEvents = (events, date) =>
    [1, 2, 3, 4, 5, 6, 7, 8, 9, 10].map(i =>
      events.push({
        start_at: date.toISOString(),
        context_code: 'user_1',
        id: id++
      })
    )
  const date = new Date()
  let events = []
  for (i = 1; i <= 5; i++) {
    date.setFullYear(date.getFullYear() + 1)
    addEvents(events, date)
  }
  sendCustomEvents(this.server, JSON.stringify(events), JSON.stringify([]), true)
  ok(
    this.container.find('.agenda-event__item-container').length,
    40,
    'finds 40 agenda-event__item-containers'
  )
  ok(this.container.find('.agenda-load-btn').length)
  view.loadMore({preventDefault: $.noop})
  events = []
  for (i = 1; i <= 2; i++) {
    addEvents(events, date)
    date.setFullYear(date.getFullYear() + 1)
  }
  sendCustomEvents(this.server, JSON.stringify(events), JSON.stringify([]), false)
  equal(
    this.container.find('.agenda-event__item-container').length,
    70,
    'finds 70 agenda-event__item-containers'
  )
})

test('renders non-assignment events with locale-appropriate format string', function() {
  tz.changeLocale(french, 'fr_FR', 'fr')
  I18nStubber.setLocale('fr_FR')
  I18nStubber.stub('fr_FR', {'time.formats.tiny': '%k:%M'})
  const view = new AgendaView({
    el: this.container,
    dataSource: this.dataSource
  })
  view.fetch(this.contextCodes, this.startDate)
  loadEventPage(this.server)

  // this event has a start_at of 2013-10-08T20:30:00Z, or 1pm MDT
  ok(
    this.container
      .find('.agenda-event__time')
      .slice(2, 3)
      .text()
      .match(/13:00/),
    'formats according to locale'
  )
})

test('renders assignment events with locale-appropriate format string', function() {
  tz.changeLocale(french, 'fr_FR', 'fr')
  I18nStubber.setLocale('fr_FR')
  I18nStubber.stub('fr_FR', {'time.formats.tiny': '%k:%M'})
  const view = new AgendaView({
    el: this.container,
    dataSource: this.dataSource
  })
  view.fetch(this.contextCodes, this.startDate)
  loadEventPage(this.server)

  // this event has a start_at of 2013-10-13T05:59:59Z, or 11:59pm MDT
  ok(
    this.container
      .find('.agenda-event__time')
      .slice(12, 13)
      .text()
      .match(/23:59/),
    'formats according to locale'
  )
})

test('renders non-assignment events in appropriate timezone', function() {
  tz.changeZone(juneau, 'America/Juneau')
  I18nStubber.stub('en', {
    'time.formats.tiny': '%l:%M%P',
    date: {}
  })
  const view = new AgendaView({
    el: this.container,
    dataSource: this.dataSource
  })
  view.fetch(this.contextCodes, this.startDate)
  loadEventPage(this.server)

  // this event has a start_at of 2013-10-08T20:30:00Z, or 11:00am AKDT
  ok(
    this.container
      .find('.agenda-event__time')
      .slice(2, 3)
      .text()
      .match(/11:00am/),
    'formats in correct timezone'
  )
})

test('renders assignment events in appropriate timezone', function() {
  tz.changeZone(juneau, 'America/Juneau')
  I18nStubber.stub('en', {
    'time.formats.tiny': '%l:%M%P',
    date: {}
  })
  const view = new AgendaView({
    el: this.container,
    dataSource: this.dataSource
  })
  view.fetch(this.contextCodes, this.startDate)
  loadEventPage(this.server)

  // this event has a start_at of 2013-10-13T05:59:59Z, or 9:59pm AKDT
  ok(
    this.container
      .find('.agenda-event__time')
      .slice(12, 13)
      .text()
      .match(/9:59pm/),
    'formats in correct timezone'
  )
})
