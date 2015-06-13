#
# Copyright (C) 2013 Instructure, Inc.
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
#

define [
  'jquery'
  'underscore'
  'timezone'
  'vendor/timezone/America/Denver'
  'vendor/timezone/America/New_York'
  'compiled/behaviors/SyllabusBehaviors'
  'compiled/collections/SyllabusCollection'
  'compiled/collections/SyllabusCalendarEventsCollection'
  'compiled/collections/SyllabusAppointmentGroupsCollection'
  'compiled/views/courses/SyllabusView'
  'spec/javascripts/compiled/views/SyllabusViewPrerendered'
  'helpers/fakeENV'
  'helpers/jquery.simulate'
], ($, _, tz, denver, newYork, SyllabusBehaviors, SyllabusCollection, SyllabusCalendarEventsCollection, SyllabusAppointmentGroupsCollection, SyllabusView, SyllabusViewPrerendered, fakeENV) ->

  setupServerResponses = ->
    server = sinon.fakeServer.create()

    # Fake calendar_events endpoint
    assignments = SyllabusViewPrerendered.assignments
    events = SyllabusViewPrerendered.events
    calendar_events_endpoint = (request) ->
      if request.url.match(/.*\?.*\btype=assignment\b/)
        response = assignments[..1]
        assignments = assignments[2..]
        more = assignments.length > 0
      else if request.url.match(/.*\?.*\btype=event\b/)
        response = events[..1]
        events = events[2..]
        more = events.length > 0

      links = "<#{request.url}>; rel=\"first\""
      links += ",<#{request.url}>; rel=\"next\"" if more

      request.respond 200,
        'Content-Type': 'application/json'
        'Link': links
        JSON.stringify response

    # Fake appointment_groups endpoint
    appointment_groups = SyllabusViewPrerendered.appointment_groups
    appointment_groups_endpoint = (request) ->
      response = appointment_groups[..1]
      appointment_groups = appointment_groups[2..]
      more = appointment_groups.length > 0

      links = "<#{request.url}>; rel=\"first\""
      links += ",<#{request.url}>; rel=\"next\"" if more

      request.respond 200,
        'Content-Type': 'application/json'
        'Link': links
        JSON.stringify response

    server.respondWith /\/api\/v1\/calendar_events($|\?)/, calendar_events_endpoint
    server.respondWith /\/api\/v1\/appointment_groups($|\?)/, appointment_groups_endpoint
    server

  module 'Syllabus',
    setup: ->
      fakeENV.setup(TIMEZONE: 'America/Denver', CONTEXT_TIMEZONE: 'America/New_York')
      # Setup stubs/mocks
      @server = setupServerResponses()

      @tzSnapshot = tz.snapshot()
      tz.changeZone(denver, 'America/Denver')
      tz.preload("America/New_York", newYork)

      @clock = sinon.useFakeTimers(new Date(2012, 0, 23, 15, 30).getTime())

      # Add pre-rendered html elements
      $fixtures = $('#fixtures')

      @jumpToToday = $(SyllabusViewPrerendered.jumpToToday)
      @jumpToToday.appendTo $fixtures

      @miniMonth = $(SyllabusViewPrerendered.miniMonth)
      @miniMonth.appendTo $fixtures

      @syllabusContainer = $(SyllabusViewPrerendered.syllabusContainer)
      @syllabusContainer.appendTo $fixtures

      # Fill the collections
      collections = [
        new SyllabusCalendarEventsCollection [ENV.context_asset_string], 'event'
        new SyllabusCalendarEventsCollection [ENV.context_asset_string], 'assignment'
        new SyllabusAppointmentGroupsCollection [ENV.context_asset_string], 'reservable'
        new SyllabusAppointmentGroupsCollection [ENV.context_asset_string], 'manageable'
      ]

      acollection = new SyllabusCollection collections

      _.map collections, (collection) ->
        error = ->
          ok false, 'ajax call failed'

        success = ->
          if collection.canFetch 'next'
            collection.fetch
              page: 'next'
              success: success
              error: error

        collection.fetch
          data:
            per_page: 2
          success: success
          error: error

      @server.respond()

      # Render and bind behaviors
      @view = new SyllabusView
        el: '#syllabusContainer'
        collection: acollection

    teardown: ->
      fakeENV.teardown()
      @syllabusContainer.remove()
      @miniMonth.remove()
      @jumpToToday.remove()
      @clock.restore()
      tz.restore(@tzSnapshot)
      @server.restore()
      document.getElementById("fixtures").innerHTML = ""

    render: ->
      @view.render()

      SyllabusBehaviors.bindToMiniCalendar()
      SyllabusBehaviors.bindToSyllabus()

    renderAssertions: ->
      expect 19

      # rendering
      syllabus = $('#syllabus')
      ok syllabus.length, 'syllabus - syllabus added to the dom'
      ok syllabus.is(':visible'), 'syllabus - syllabus visible'

      dates = $('tr.date', syllabus)
      equal dates.length, 6, 'dates - dates coalesce'

      assignments = $('tr.syllabus_assignment', dates)
      equal assignments.length, 10, 'events - all assignments rendered'
      if @view.can_read
        equal $('td.name a', assignments).length, 10, 'events - link rendered for each assignment'
      else
        equal $('td.name a', assignments).length, 0, 'events - link not rendered for each assignment'

      events = $('tr.syllabus_event', dates)
      equal events.length, 6, 'events - all events rendered'
      if @view.can_read && @view.is_valid_user
        equal $('td.name a', events).length, 6, 'events - link rendered for each event'
      else
        equal $('td.name a', events).length, 0, 'events - link not rendered for each event'

      # mini calendar dates - has event
      expected = $('#mini_day_2012_01_01, #mini_day_2012_01_11, #mini_day_2012_01_23, #mini_day_2012_01_30, #mini_day_2012_01_31')
      actual = $('.mini_calendar_day.has_event')
      equal expected.length, 5, 'mini calendar - expected dates with events found'
      deepEqual actual.toArray(), expected.toArray(), 'mini calendar - dates with events highlighted'

      # today
      expected = $('#mini_day_2012_01_23')
      actual = $('.mini_calendar_day.related')
      equal expected.length, 1, 'today - today found'
      deepEqual actual.toArray(), expected.toArray(), 'today - today highlighted'

      expected = $('.events_2012_01_23')
      actual = $('tr.date.related')
      equal expected.length, 1, 'today - today\'s events found'
      deepEqual actual.toArray(), expected.toArray(), 'today - today\'s events highlighted'

      expected = $('.events_2012_01_01, .events_2012_01_11')
      actual = $('tr.date.date_passed')
      equal expected.length, 2, 'passed events - passed events found'
      deepEqual actual.toArray(), expected.toArray(), 'passed events - events before today marked as passed'

      # context-sensitive datetime titles
      assignment_ts = $('.events_2012_01_01 .related-assignment_1 .dates > span:nth-child(1)')
      equal assignment_ts.text(), "10am", "assignment - local time in table"
      equal assignment_ts.data('html-tooltip-title'), "Local: Jan 1 at 10:00am<br>Course: Jan 1 at 12:00pm", 'assignment - correct local and course times given'

      event_ts = $('.events_2012_01_01 .related-appointment_group_1 .dates > span:nth-child(1)')
      equal event_ts.text(), " 8am", "event - local time in table"
      equal event_ts.data('html-tooltip-title'), "Local: Jan 1 at 8:00am<br>Course: Jan 1 at 10:00am", 'event - correct local and course times given'

  test 'render (user public course)', ->
    @view.can_read = true # public course -- can read
    @view.is_valid_user = true # user - enrolled (can read)

    @render()
    @renderAssertions()

  test 'render (anonymous public course)', ->
    @view.can_read = true # public course -- can read
    @view.is_valid_user = false # anonymous

    @render()
    @renderAssertions()

  test 'render (user public syllabus)', ->
    @view.can_read = false # public syllabus -- cannot read
    @view.is_valid_user = true # user - non-enrolled (cannot read)

    @render()
    @renderAssertions()

  test 'render (anonymous public syllabus)', ->
    @view.can_read = false # public syllabus -- cannot read
    @view.is_valid_user = false # anonymous

    @render()
    @renderAssertions()

  test 'syllabus interaction', ->
    expect 14

    @view.is_public_course = true
    @view.can_participate = true
    @render()

    # dated hover
    event = $('.events_2012_01_11')
    date = $('#mini_day_2012_01_11')
    equal event.length, 1, 'hover dated syllabus row - event found'
    equal date.length, 1, 'hover dated syllabus row - mini calendar day found'
    event.simulate 'mouseover'

    expected = event
    actual = $('tr.date.related')
    deepEqual actual.toArray(), expected.toArray(), 'hover dated syllabus row - event highlighted'

    expected = date
    actual = $('.mini_calendar_day.related')
    deepEqual actual.toArray(), expected.toArray(), 'hover dated syllabus row - mini calendar day highlighted'

    # undated hover
    undated = $('tr.date:not(.events_2012_01_01, .events_2012_01_11, .events_2012_01_23, .events_2012_01_30, .events_2012_01_31)')
    equal undated.length, 1, 'hover undated syllabus row - row found'

    undated.simulate 'mouseover'

    expected = []
    actual = $('tr.date.related')
    deepEqual actual.toArray(), expected, 'hover undated syllabus row - no events highlighted'

    expected = []
    actual = $('.mini_calendar_day.related')
    deepEqual actual.toArray(), expected, 'hover undated syllabus row - no mini calendar days highlighted'

    # event hover
    assignment = $('tr.related-assignment_1:not(.special_date)')
    equal assignment.length, 1, 'hover event - assignment event found'

    assignment.simulate 'mouseover'

    expected = $('tr.related-assignment_1.special_date')
    equal expected.length, 5, 'hover event - special dates for assignment found'

    actual = $('tr.syllabus_assignment.related_event')
    deepEqual actual.toArray(), expected.toArray(), 'hover event - special dates for assignment highlighted'

    # override hover
    override = $('tr.related-assignment_1.special_date:first')
    equal override.length, 1, 'hover special date - found special date'

    override.simulate 'mouseover'

    expected = $('tr.related-assignment_1').not(override)
    actual = $('tr.syllabus_assignment.related_event')
    equal expected.length, 5, 'hover special date - related assignment and special dates found'
    deepEqual actual.toArray(), expected.toArray(), 'hover special date - related assignment and special dates highlighted'

    # event/override unhover
    override.simulate 'mouseout'

    expected = []
    actual = $('tr.syllabus_assignment.related_event')
    deepEqual actual.toArray(), expected, 'unhover event - events no longer highlighted'

  test 'hide/show special events', ->
    expect 20

    @view.is_public_course = true
    @view.can_participate = true
    @render()

    # hide/show special
    day = $('#mini_day_2012_01_31')
    equal day.length, 1, 'render - expected day found'

    toggleSpecial = $('#toggle_special_dates_in_syllabus')
    equal toggleSpecial.length, 1, 'render - toggle special dates found'

    equal toggleSpecial.hasClass('shown'), true, 'render - toggle marked as shown'
    equal toggleSpecial.hasClass('hidden'), false, 'render - toggle not marked as hidden'

    expected = $('tr.syllabus_assignment, tr.syllabus_event')
    actual = expected.filter(':visible')
    equal expected.length, 16, 'render - all events found'
    deepEqual actual.toArray(), expected.toArray(), 'render - all events visible'

    equal day.hasClass('has_event'), true, 'render - dates with special events shown as having events'

    # click toggle special (hide special)
    toggleSpecial.simulate 'click'

    equal toggleSpecial.hasClass('shown'), false, 'hide special - toggle not marked as shown'
    equal toggleSpecial.hasClass('hidden'), true, 'hide special - toggle marked as hidden'

    expected = []
    actual = $('tr.special_date:visible')
    deepEqual actual.toArray(), expected, 'hide special - all special events hidden'

    expected = $('tr.syllabus_assignment:not(.special_date), tr.syllabus_event:not(.special_date)')
    actual = expected.filter(':visible')
    equal expected.length, 11, 'hide special - all non-special events found'
    deepEqual actual.toArray(), expected.toArray(), 'hide special - all non-special events visible'

    equal $('.mini_calendar_day.has_event').length, 4, 'hide special - dates that have non-special events still shown as having events'
    equal day.hasClass('has_event'), false, 'hide special - dates with only special events no longer shown having events'

    # click toggle special (show special)
    toggleSpecial.simulate 'click'

    equal toggleSpecial.hasClass('shown'), true, 'show special - toggle marked as shown'
    equal toggleSpecial.hasClass('hidden'), false, 'show special - toggle not marked as hidden'

    expected = $('tr.syllabus_assignment, tr.syllabus_event')
    actual = expected.filter(':visible')
    equal expected.length, 16, 'show special - all events found'
    deepEqual actual.toArray(), expected.toArray(), 'show special - all events once again visible'

    equal $('.mini_calendar_day.has_event').length, 5, 'show special - dates that have non-special events still shown as having events'
    equal day.hasClass('has_event'), true, 'show special - dates with only special events no longer shown having events'

  test 'mini calendar', ->
    expect 27

    @view.is_public_course = true
    @view.can_participate = true
    @render()

    # hover non-event date
    nonEventMiniDay = $('#mini_day_2012_01_17')
    equal nonEventMiniDay.length, 1, 'non-event day hover - found'

    nonEventMiniDay.simulate 'mouseover'
    deepEqual $('.mini_calendar_day.related').toArray(), nonEventMiniDay.toArray(), 'non-event day hover - highlighted'

    # hover event date
    eventMiniDay = $('#mini_day_2012_01_30')
    equal eventMiniDay.length, 1, 'event day hover - event day found'

    eventMiniDay.simulate 'mouseover'
    deepEqual $('.mini_calendar_day.related').toArray(), eventMiniDay.toArray(), 'event day hover - event day highlighted'

    expected = $('.events_2012_01_30')
    actual = $('tr.date.related')
    equal expected.length, 1, 'event day hover - syllabus event found'
    deepEqual actual.toArray(), expected.toArray(), 'event day hover - syllabus event highlighted'

    # unhover the event date
    eventMiniDay.simulate 'mouseout'

    expected = []
    actual = $('.mini_calendar_day.related')
    deepEqual actual.toArray(), expected, 'event day unhover - mini calendar day no longer highlighted'

    expected = []
    actual = $('tr.date.related')
    deepEqual actual.toArray(), expected, 'event day unhover - syllabus events no longer highlighted'

    # previous month link
    prevMonthLink = $('.prev_month_link')
    equal prevMonthLink.length, 1, 'previous month - link found'

    prevMonthLink.simulate 'mousedown'

    equal parseInt($('.month_number').text()), 12, 'previous month - month changed to December'
    equal parseInt($('.year_number').text()), 2011, 'previous month - year changed to 2011'

    expected = $('#mini_day_2012_01_01')
    actual = $('.mini_calendar_day.has_event')
    equal expected.length, 1, 'previous month - expected dates with events found'
    deepEqual actual.toArray(), expected.toArray(), 'previous month - expected dates with events highlighted'

    # next month link
    nextMonthLink = $('.next_month_link')
    equal nextMonthLink.length, 1, 'next month - link found'

    nextMonthLink.simulate 'mousedown'
    nextMonthLink.simulate 'mousedown'

    equal parseInt($('.month_number').text()), 2, 'next month - month changed to February'
    equal parseInt($('.year_number').text()), 2012, 'next month - year changed to 2012'

    expected = $('#mini_day_2012_01_30, #mini_day_2012_01_31')
    actual = $('.mini_calendar_day.has_event')
    equal expected.length, 2, 'next month - expected dates with events found'
    deepEqual actual.toArray(), expected.toArray(), 'next month - expected dates with events highlighted'

    # jump to today link
    jumpToTodayLink = $('a.jump_to_today_link')
    equal jumpToTodayLink.length, 1, 'jump to today - link found'

    jumpToTodayLink.simulate 'click'

    equal parseInt($('.month_number').text()), 1, 'jump to today - month changed to January'
    equal parseInt($('.year_number').text()), 2012, 'jump to today - year left at 2012'

    expected = $('#mini_day_2012_01_01, #mini_day_2012_01_11, #mini_day_2012_01_23, #mini_day_2012_01_30, #mini_day_2012_01_31')
    actual = $('.mini_calendar_day.has_event')
    equal expected.length, 5, 'jump to today - expected has event dates found'
    deepEqual actual.toArray(), expected.toArray(), 'jump to today - expected dates with events highlighted'

    expected = $('#mini_day_2012_01_23')
    actual = $('.mini_calendar_day.selected')
    equal expected.length, 1, 'jump to today - today found'
    deepEqual actual.toArray(), expected.toArray(), 'jump to today - today highlighted'

    expected = $('.events_2012_01_23')
    actual = $('tr.date.selected')
    equal expected.length, 1, 'jump to today - today\'s events found'
    deepEqual actual.toArray(), expected.toArray(), 'jump to today - today\'s events highlighted'
