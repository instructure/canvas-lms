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

import $ from 'jquery'
import 'jquery-migrate'
import EventDataSource from '@canvas/calendar/jquery/EventDataSource'
import fcUtil from '@canvas/calendar/jquery/fcUtil'
import fakeENV from '@canvas/test-utils/fakeENV'
import tzInTest from '@instructure/moment-utils/specHelpers'
import {isArray, isObject, uniq} from 'lodash'
import sinon from 'sinon'
import timezone from 'timezone'
import denver from 'timezone/America/Denver'
import juneau from 'timezone/America/Juneau'
import french from 'timezone/fr_FR'
import AgendaView from '../AgendaView'
import assignmentResponse from './calendarAssignments'
import eventResponse from './calendarEvents'

const plannerItemsResponse = `[]`

const loadEventPage = (server, includeNext = false) =>
  sendCustomEvents(server, eventResponse, assignmentResponse, plannerItemsResponse, includeNext)

const sendCustomEvents = function (server, events, assignments, plannerItems, includeNext = false) {
  const requestIndex = server.requests.length - 3
  server.requests[requestIndex].respond(200, {'Content-Type': 'application/json'}, plannerItems)
  server.requests[requestIndex + 1].respond(
    200,
    {
      'Content-Type': 'application/json',
      Link: `</api/magic>; rel="${includeNext ? 'next' : 'current'}"`,
    },
    events,
  )
  return server.requests[requestIndex + 2].respond(
    200,
    {'Content-Type': 'application/json'},
    assignments,
  )
}

describe('AgendaView', () => {
  let container
  let contexts
  let contextCodes
  let startDate
  let dataSource
  let server

  beforeEach(() => {
    container = $('<div />', {id: 'agenda-wrapper'}).appendTo(document.body)
    contexts = [{asset_string: 'user_1'}, {asset_string: 'course_2'}, {asset_string: 'group_3'}]
    contextCodes = ['user_1', 'course_2', 'group_3']
    startDate = fcUtil.wrap(new Date(JSON.parse(eventResponse)[0].start_at))
    fcUtil.addMinuteDelta(startDate, -60 * 24 * 15)
    dataSource = new EventDataSource(contexts)
    server = sinon.fakeServer.create()
    tzInTest.configureAndRestoreLater({
      tz: timezone(denver, 'America/Denver'),
      tzData: {
        'America/Denver': denver,
      },
      momentLocale: 'en',
    })
    fakeENV.setup({CALENDAR: {}})
  })

  afterEach(() => {
    container.remove()
    server.restore()
    tzInTest.restore()
    fakeENV.teardown()
  })

  it('renders results', () => {
    const view = new AgendaView({
      el: container,
      dataSource,
    })
    view.fetch(contextCodes, startDate)
    loadEventPage(server)

    expect(container.find('.agenda-event__item-container')).toHaveLength(18)
    expect(container.find('.agenda-date')).toHaveLength(view.toJSON().days.length)
    expect(container.find('.agenda-load-btn')).toHaveLength(0)
  })

  it('shows "load more" if there are more results', () => {
    const view = new AgendaView({
      el: container,
      dataSource,
    })
    view.fetch(contextCodes, startDate)
    loadEventPage(server, true)
    expect(container.find('.agenda-load-btn')).toHaveLength(1)
  })

  it('properly serializes results in toJSON', () => {
    tzInTest.configureAndRestoreLater({
      tz: timezone(denver, 'America/Denver'),
      tzData: {
        'America/Denver': denver,
      },
      momentLocale: 'en',
      formats: {
        'date.formats.short_with_weekday': '%a, %b %-d',
        'date.abbr_day_names.1': 'Mon',
        'date.abbr_month_names.10': 'Oct',
      },
    })
    const view = new AgendaView({
      el: container,
      dataSource,
    })
    view.fetch(contextCodes, startDate)
    loadEventPage(server)
    const serialized = view.toJSON()

    expect(isArray(serialized.days)).toBe(true)
    expect(isObject(serialized.meta)).toBe(true)
    expect(uniq(serialized.days)).toHaveLength(serialized.days.length)
    expect(serialized.days[0].date).toBe('Mon, Oct 7')
    serialized.days.forEach(d => expect(d.events.length).toBeGreaterThan(0))
  })

  it('only includes days on page breaks once', () => {
    const view = new AgendaView({
      el: container,
      dataSource,
    })
    view.fetch(contextCodes, startDate)

    let id = 1
    const addEvents = (events, date) =>
      [1, 2, 3, 4, 5, 6, 7, 8, 9, 10].map(_i =>
        events.push({
          start_at: date.toISOString(),
          context_code: 'user_1',
          id: id++,
        }),
      )

    const date = new Date()
    let events = []
    for (let i = 1; i <= 5; i++) {
      date.setFullYear(date.getFullYear() + 1)
      addEvents(events, date)
    }

    sendCustomEvents(server, JSON.stringify(events), JSON.stringify([]), JSON.stringify([]), true)

    expect(container.find('.agenda-event__item-container')).toHaveLength(40)
    expect(container.find('.agenda-load-btn')).toHaveLength(1)

    view.loadMore({preventDefault: $.noop})
    events = []
    for (let i = 1; i <= 2; i++) {
      addEvents(events, date)
      date.setFullYear(date.getFullYear() + 1)
    }

    sendCustomEvents(server, JSON.stringify(events), JSON.stringify([]), JSON.stringify([]), false)

    expect(container.find('.agenda-event__item-container')).toHaveLength(70)
  })

  it('renders non-assignment events with locale-appropriate format string', () => {
    tzInTest.configureAndRestoreLater({
      tz: timezone(denver, 'America/Denver', french, 'fr_FR'),
      tzData: {
        'America/Denver': denver,
      },
      momentLocale: 'fr',
      formats: {'time.formats.tiny': '%k:%M'},
    })
    const view = new AgendaView({
      el: container,
      dataSource,
    })
    view.fetch(contextCodes, startDate)
    loadEventPage(server)
    // this event has a start_at of 2013-10-08T20:30:00Z, or 1pm MDT
    expect(container.find('.agenda-event__time').slice(2, 3).text()).toMatch(/13:00/)
  })

  it('renders assignment events with locale-appropriate format string', () => {
    tzInTest.configureAndRestoreLater({
      tz: timezone(denver, 'America/Denver', french, 'fr_FR'),
      tzData: {
        'America/Denver': denver,
      },
      momentLocale: 'fr',
      formats: {'time.formats.tiny': '%k:%M'},
    })
    const view = new AgendaView({
      el: container,
      dataSource,
    })
    view.fetch(contextCodes, startDate)
    loadEventPage(server)
    // this event has a start_at of 2013-10-13T05:59:59Z, or 11:59pm MDT
    expect(container.find('.agenda-event__time').slice(12, 13).text()).toMatch(/23:59/)
  })

  it('renders non-assignment events in appropriate timezone', () => {
    tzInTest.configureAndRestoreLater({
      tz: timezone(juneau, 'America/Juneau'),
      tzData: {
        'America/Juneau': juneau,
      },
      formats: {
        'time.formats.tiny': '%l:%M%P',
      },
    })
    const view = new AgendaView({
      el: container,
      dataSource,
    })
    view.fetch(contextCodes, startDate)
    loadEventPage(server)
    // this event has a start_at of 2013-10-08T20:30:00Z, or 11:00am AKDT
    expect(container.find('.agenda-event__time').slice(2, 3).text()).toMatch(/11:00am/)
  })

  it('renders assignment events in appropriate timezone', () => {
    tzInTest.configureAndRestoreLater({
      tz: timezone(juneau, 'America/Juneau'),
      tzData: {
        'America/Juneau': juneau,
      },
      formats: {
        'time.formats.tiny': '%l:%M%P',
      },
    })
    const view = new AgendaView({
      el: container,
      dataSource,
    })
    view.fetch(contextCodes, startDate)
    loadEventPage(server)
    // this event has a start_at of 2013-10-13T05:59:59Z, or 9:59pm AKDT
    expect(container.find('.agenda-event__time').slice(12, 13).text()).toMatch(/9:59pm/)
  })
})
