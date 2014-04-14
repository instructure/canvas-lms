require [
  'jquery'
  'underscore'
  'timezone'
  'vendor/timezone/America/Denver'
  'compiled/views/calendar/AgendaView'
  'compiled/calendar/EventDataSource'
  'helpers/ajax_mocks/api/v1/calendarEvents'
  'helpers/ajax_mocks/api/v1/calendarAssignments'
], ($, _, tz, denver, AgendaView, EventDataSource, eventResponse, assignmentResponse) ->
  loadEventPage = (server, includeNext = false) ->
    sendCustomEvents(server, eventResponse, assignmentResponse, includeNext)

  sendCustomEvents = (server, events, assignments, includeNext = false, requestIndex = 0) ->
    server.requests[requestIndex].respond 200,
      { 'Content-Type': 'application/json', 'Link': '</api/magic>; rel="'+(if includeNext then 'next' else 'current')+'"' }, events
    server.requests[requestIndex+1].respond 200,
      { 'Content-Type': 'application/json' }, assignments

  module "AgendaView",
    setup: ->
      @container = $('<div />', id: 'agenda-wrapper').appendTo('#fixtures')
      @contexts = [{"asset_string":"user_1"}, {"asset_string":"course_2"}, {"asset_string":"group_3"}]
      @contextCodes = ["user_1", "course_2", "group_3"]
      @startDate = new Date()
      @startDate.setYear(2001)
      @dataSource = new EventDataSource(@contexts)
      @server = sinon.fakeServer.create()
      @snapshot = tz.snapshot()
      tz.changeZone(denver, 'America/Denver')

    teardown: ->
      @container.remove()
      @server.restore()
      tz.restore(@snapshot)

  test 'should render results', ->
    view = new AgendaView(el: @container, dataSource: @dataSource)
    view.fetch(@contextCodes, @startDate)
    loadEventPage(@server)

    # should render all events
    ok @container.find('.ig-row').length == 18, 'finds 18 ig-rows'

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
    view = new AgendaView(el: @container, dataSource: @dataSource)
    view.fetch(@contextCodes, @startDate)
    loadEventPage(@server)

    serialized = view.toJSON()

    ok _.isArray(serialized.days), 'days is an array'
    ok _.isObject(serialized.meta), 'meta is an object'
    ok _.uniq(serialized.days).length == serialized.days.length, 'does not duplicate dates'
    ok serialized.days[0].date == 'Mon, Oct 7', 'finds the correct first day'
    _.each serialized.days, (d) ->
      ok d.events.length, 'every day has events'

  test 'should omit days on page breaks', ->
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

    ok @container.find('.ig-row').length == 40, 'finds 40 ig-rows'
    ok @container.find('.agenda-load-btn').length
    view.loadMore({preventDefault: $.noop})

    events = []
    for i in [1..2]
      addEvents(events, date)
      date.setFullYear(date.getFullYear()+1)
    sendCustomEvents(@server, JSON.stringify(events), JSON.stringify([]), false, 2)

    ok @container.find('.ig-row').length == 60, 'finds 60 ig-rows'
