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
    ok @container.find('.ig-row').length == 18

    # should bin results by day
    dates = @container.find('.agenda-date')
    ok dates.length == 10

    # the bins should be sorted properly
    textDates = _.map(dates, (d) -> d.innerText)
    console.log(textDates)
    ok _.isEqual(textDates, [
      "Mon, Oct 7"
      "Tue, Oct 8"
      "Wed, Oct 9"
      "Thu, Oct 10"
      "Fri, Oct 11"
      "Sat, Oct 12"
      "Mon, Oct 14"
      "Wed, Oct 16"
      "Fri, Oct 18"
      "Fri, Nov 1"
    ])

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

