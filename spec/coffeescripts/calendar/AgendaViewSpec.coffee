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

  $.fudgeDateForProfileTimezone = (d) -> d

  module "AgendaView",
    setup: ->
      @container = $('<div />', id: 'agenda-wrapper').appendTo('body')
      @server = sinon.fakeServer.create()

    teardown: ->
      @container.remove()
      @server.restore()

  test 'should render results', ->
    view = new AgendaView(el: @container)
    view.fetch()
    loadEventPage(@server)

    # should render all events
    ok @container.find('.ig-row').length == 18

    # should bin results by day
    ok @container.find('.agenda-date').length == 9

    # should not show "load more" if there are no more pages
    ok !@container.find('.agenda-load-btn').length

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

    ok _.isArray(serialized.days)
    ok _.isObject(serialized.meta)
    ok serialized.days.length == 9
    ok serialized.days[0].date == 'Mon, Oct 7'
    _.each(serialized.days, (d) -> ok d.events.length)

