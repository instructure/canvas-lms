require [
  'underscore'
  'compiled/views/calendar/AgendaView'
  'spec/javascripts/helpers/ajax_mocks/api/v1/calendarEvents'
  'spec/javascripts/helpers/ajax_mocks/api/v1/calendarAssignments'
], (_, AgendaView, eventResponse, assignmentResponse) ->

  loadEventPage = (server) ->
    server.requests[0].respond 200,
      { 'Content-Type': 'application/json' }, eventResponse
    server.requests[1].respond 200,
      { 'Content-Type': 'application/json' }, assignmentResponse

  originalFudge = $.fudgeDateForProfileTimezone


  module "AgendaView",
    setup: ->
      @container = $('<div />', id: 'agenda-wrapper').appendTo('body')
      @server = sinon.fakeServer.create()
      $.fudgeDateForProfileTimezone = (d) -> d

    teardown: ->
      @container.remove()
      @server.restore()
      $.fudgeDateForProfileTimezone = originalFudge

  test 'should render results', ->
    view = new AgendaView(el: @container)
    view.fetch()
    loadEventPage(@server)

    # should render all events
    ok @container.find('.ig-row').length == 18, 'finds 18 ig-rows'

    # should bin results by day
    ok @container.find('.agenda-date').length == view.toJSON().days.length

    # should not show "load more" if there are no more pages
    ok !@container.find('.agenda-load-btn').length, 'does not find the loader'

  test 'should show "load more" if there are more results', ->
    view = new AgendaView(el: @container)
    view.fetch()

    # stub out canFetch as if we had other pages
    view.eventCollection.canFetch      = _.identity
    view.assignmentCollection.canFetch = _.identity

    loadEventPage(@server)

    ok @container.find('.agenda-load-btn').length

  test 'toJSON should properly serialize results', ->
    view = new AgendaView(el: @container)
    view.fetch()
    loadEventPage(@server)

    serialized = view.toJSON()

    ok _.isArray(serialized.days), 'days is an array'
    ok _.isObject(serialized.meta), 'meta is an object'
    ok _.uniq(serialized.days).length == serialized.days.length, 'does not duplicate dates'
    ok serialized.days[0].date == 'Mon, Oct 7', 'finds the correct first day'
    _.each serialized.days, (d) ->
      ok d.events.length, 'every day has events'

