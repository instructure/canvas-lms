#
# Copyright (C) 2013 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'jquery'
  'underscore'
  'timezone'
  'compiled/util/fcUtil'
  'timezone/America/Denver'
  'timezone/America/Juneau'
  'timezone/fr_FR'
  'compiled/views/calendar/AgendaView'
  'compiled/calendar/Calendar'
  'compiled/calendar/EventDataSource'
  'helpers/ajax_mocks/api/v1/calendarEvents'
  'helpers/ajax_mocks/api/v1/calendarAssignments'
  'helpers/I18nStubber'
  'helpers/fakeENV'
], ($, _, tz, fcUtil, denver, juneau, french, AgendaView, Calendar, EventDataSource, eventResponse, assignmentResponse, I18nStubber, fakeENV) ->
  loadEventPage = (server, includeNext = false) ->
    sendCustomEvents(server, eventResponse, assignmentResponse, includeNext)

  sendCustomEvents = (server, events, assignments, includeNext = false) ->
    requestIndex = server.requests.length - 2
    server.requests[requestIndex].respond 200,
      { 'Content-Type': 'application/json', 'Link': '</api/magic>; rel="'+(if includeNext then 'next' else 'current')+'"' }, events
    server.requests[requestIndex+1].respond 200,
      { 'Content-Type': 'application/json' }, assignments

  QUnit.module "AgendaView",
    setup: ->
      @container = $('<div />', id: 'agenda-wrapper').appendTo('#fixtures')
      @contexts = [{"asset_string":"user_1"}, {"asset_string":"course_2"}, {"asset_string":"group_3"}]
      @contextCodes = ["user_1", "course_2", "group_3"]
      @startDate = fcUtil.now()
      @startDate.minute(1)
      @startDate.year(2001)
      @dataSource = new EventDataSource(@contexts)
      @server = sinon.fakeServer.create()
      @snapshot = tz.snapshot()
      tz.changeZone(denver, 'America/Denver')
      I18nStubber.pushFrame()
      fakeENV.setup({CALENDAR: {}})

    teardown: ->
      @container.remove()
      @server.restore()
      tz.restore(@snapshot)
      I18nStubber.popFrame()
      fakeENV.teardown()

  test 'should render results', ->
    view = new AgendaView(el: @container, dataSource: @dataSource)
    view.fetch(@contextCodes, @startDate)
    loadEventPage(@server)
    # should render all events
    ok @container.find('.agenda-event__item-container').length == 18, 'finds 18 agenda-event__item-containers'

    # should bin results by day
    ok @container.find('.agenda-date').length == view.toJSON().days.length

    # should not show "load more" if there are no more pages
    ok !@container.find('.agenda-load-btn').length, 'does not find the loader'

  test 'should show "load more" if there are more results', ->
    view = new AgendaView(el: @container, dataSource: @dataSource)
    view.fetch(@contextCodes, @startDate)

    loadEventPage(@server, true)

    ok @container.find('.agenda-load-btn').length

  test 'toJSON should properly serialize results', ->
    I18nStubber.stub 'en',
      'date.formats.short_with_weekday': '%a, %b %-d'
      'date.abbr_day_names.1': 'Mon'
      'date.abbr_month_names.10': 'Oct'

    view = new AgendaView(el: @container, dataSource: @dataSource)
    view.fetch(@contextCodes, @startDate)
    loadEventPage(@server)

    serialized = view.toJSON()

    ok _.isArray(serialized.days), 'days is an array'
    ok _.isObject(serialized.meta), 'meta is an object'
    ok _.uniq(serialized.days).length == serialized.days.length, 'does not duplicate dates'
    ok serialized.days[0].date == 'Mon, Oct 7', 'finds the correct first day'
    ok serialized.meta.hasOwnProperty('better_scheduler'), 'contains a property indicating better_scheduler is active or not'
    _.each serialized.days, (d) ->
      ok d.events.length, 'every day has events'

  test 'should only include days on page breaks once', ->
    view = new AgendaView(el: @container, dataSource: @dataSource)
    window.view = view
    view.fetch(@contextCodes, @startDate)

    id = 1
    addEvents = (events, date) ->
      for i in [1..10]
        events.push
          start_at: date.toISOString()
          context_code: 'user_1'
          id: id++

    date = new Date()
    events = []
    for i in [1..5]
      date.setFullYear(date.getFullYear()+1)
      addEvents(events, date)
    sendCustomEvents(@server, JSON.stringify(events), JSON.stringify([]), true)

    ok @container.find('.agenda-event__item-container').length, 40, 'finds 40 agenda-event__item-containers'
    ok @container.find('.agenda-load-btn').length
    view.loadMore({preventDefault: $.noop})

    events = []
    for i in [1..2]
      addEvents(events, date)
      date.setFullYear(date.getFullYear()+1)
    sendCustomEvents(@server, JSON.stringify(events), JSON.stringify([]), false)

    equal @container.find('.agenda-event__item-container').length, 70, 'finds 70 agenda-event__item-containers'

  test 'renders non-assignment events with locale-appropriate format string', ->
    tz.changeLocale(french, 'fr_FR', 'fr')
    I18nStubber.setLocale 'fr_FR'
    I18nStubber.stub 'fr_FR', 'time.formats.tiny': '%k:%M'

    view = new AgendaView(el: @container, dataSource: @dataSource)
    view.fetch(@contextCodes, @startDate)
    loadEventPage(@server)

    # this event has a start_at of 2013-10-08T20:30:00Z, or 1pm MDT
    ok @container.find('.agenda-event__time').slice(2, 3).text().match(/13:00/), 'formats according to locale'

  test 'renders assignment events with locale-appropriate format string', ->
    tz.changeLocale(french, 'fr_FR', 'fr')
    I18nStubber.setLocale 'fr_FR'
    I18nStubber.stub 'fr_FR', 'time.formats.tiny': '%k:%M'

    view = new AgendaView(el: @container, dataSource: @dataSource)
    view.fetch(@contextCodes, @startDate)
    loadEventPage(@server)

    # this event has a start_at of 2013-10-13T05:59:59Z, or 11:59pm MDT
    ok @container.find('.agenda-event__time').slice(12, 13).text().match(/23:59/), 'formats according to locale'

  test 'renders non-assignment events in appropriate timezone', ->
    tz.changeZone(juneau, 'America/Juneau')
    I18nStubber.stub 'en',
      'time.formats.tiny': '%l:%M%P'
      'date': {}

    view = new AgendaView(el: @container, dataSource: @dataSource)
    view.fetch(@contextCodes, @startDate)
    loadEventPage(@server)

    # this event has a start_at of 2013-10-08T20:30:00Z, or 11:00am AKDT
    ok @container.find('.agenda-event__time').slice(2, 3).text().match(/11:00am/), 'formats in correct timezone'

  test 'renders assignment events in appropriate timezone', ->
    tz.changeZone(juneau, 'America/Juneau')
    I18nStubber.stub 'en',
      'time.formats.tiny': '%l:%M%P'
      'date': {}

    view = new AgendaView(el: @container, dataSource: @dataSource)
    view.fetch(@contextCodes, @startDate)
    loadEventPage(@server)

    # this event has a start_at of 2013-10-13T05:59:59Z, or 9:59pm AKDT
    ok @container.find('.agenda-event__time').slice(12, 13).text().match(/9:59pm/), 'formats in correct timezone'
