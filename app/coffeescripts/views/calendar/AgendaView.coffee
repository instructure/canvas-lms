define [
  'i18n!calendar'
  'jquery'
  'underscore'
  'Backbone'
  'compiled/collections/CalendarEventCollection'
  'compiled/calendar/ShowEventDetailsDialog'
  'jst/calendar/agendaView'
  'vendor/jquery.ba-tinypubsub'
], (I18n, $, _, Backbone, CalendarEventCollection, ShowEventDetailsDialog, template) ->

  class AgendaView extends Backbone.View

    PER_PAGE: 50

    template: template

    els:
      '.agenda-actions .loading-spinner'   : '$spinner'

    events:
      'click .agenda-load-btn': 'loadMore'
      'click .ig-row': 'manageEvent'
      'keydown .ig-row': 'manageEvent'

    @optionProperty 'calendar'

    constructor: ->
      super
      @dataSource = @options.dataSource

      $.subscribe
        "CommonEvent/eventDeleted" : @refetch
        "CommonEvent/eventSaved" : @refetch

    fetch: (contexts, start = new Date) ->
      @$el.empty()
      @$el.addClass('active')

      @contexts = contexts

      start.setHours(0)
      start.setMinutes(0)
      start.setSeconds(0)

      @startDate = start

      @_fetch(start, @handleEvents)

    _fetch: (start, callback) ->
      end = new Date(3000, 1, 1)
      @lastRequestID = $.guid++
      @dataSource.getEvents start, end, @contexts, callback, {singlePage: true, requestID: @lastRequestID}

    refetch: =>
      return unless @startDate
      @collection = []
      @_fetch(@startDate, @handleEvents)

    handleEvents: (events) =>
      return if events.requestID != @lastRequestID
      @collection = []
      @appendEvents(events)

    appendEvents: (events) =>
      @nextPageDate = events.nextPageDate
      @collection.push.apply(@collection, events)
      @collection = _.sortBy(@collection, 'start')
      @render()

    loadMore: (e) ->
      e.preventDefault()
      @$spinner.show()
      @_fetch(@nextPageDate, @appendEvents)

    manageEvent: (e) ->
      return if e.type == 'keydown' && e.keyCode != 13 && e.keyCode != 32
      eventId = $(e.target).closest('.agenda-event').data('event-id')
      event = @dataSource.eventWithId(eventId)
      new ShowEventDetailsDialog(event, @dataSource).show e

    render: =>
      super
      @$spinner.hide()
      $.publish('Calendar/colorizeContexts')

      lastEvent = _.last(@collection)
      return if !lastEvent
      @trigger('agendaDateRange', @startDate, lastEvent.start)

    # Internal: Change a flat array of objects into a sturctured array of
    # objects based on the given iterator function. Similar to _.groupBy,
    # except the result is an Array instead of a Hash and this function
    # assumes the list is already sorted by the given iterator.
    #
    # list     - The sorted list of values to box.
    # iterator - A function that returns the value to box by. The iterator
    #            is passed the value from the list.
    #
    # Returns a new boxed array with elemens from the given list.
    sortedBoxBy: (list, iterator) ->
      _.reduce(list, (result, currentElt) ->
        return [[currentElt]] if _.isEmpty(result)

        previousBox = _.last(result)
        previousElt = _.last(previousBox)
        if iterator(currentElt) == iterator(previousElt)
          previousBox.push(currentElt)
        else
          result.push([currentElt])

        result
      , [])

    # Internal: returns the 'start' of the event formatted for the template
    #
    # event - the event to format
    #
    # Returns the formatted String
    formattedDayString: (event) =>
      I18n.l('#date.formats.short_with_weekday', event.start)

    # Internal: change a box of events into an output hash for toJSON
    #
    # events - a box of events (all the events occur on the same day)
    #
    # Returns an Object with 'date' and 'events' keys.
    eventBoxToHash: (events) =>
      now = $.fudgeDateForProfileTimezone(new Date)
      event = _.first(events)
      start = event.start
      isToday =
        now.getDate() == start.getDate() &&
        now.getMonth() == start.getMonth() &&
        now.getFullYear() == start.getFullYear()
      date: @formattedDayString(event)
      isToday: isToday
      events: events

    # Internal: Format a hash of event data to an object ready to be sent to the template.
    #
    # boxedEvents - A boxed list of events
    #
    # Returns an object in the format specified by toJSON.
    formatResult: (boxedEvents) ->
      days: _.map(boxedEvents, @eventBoxToHash)
      meta:
        hasMore: !!@nextPageDate

    # Public: Creates the json for the template.
    #
    # Returns an Object:
    #   {
    #     days: [
    #       [date: 'some date', events: [event1.toJSON(), event2.toJSON()],
    #       [date: ...]
    #     ],
    #     meta: {
    #       hasMore: true/false
    #     }
    #   }
    toJSON: ->
      list = @sortedBoxBy(@collection, @formattedDayString)
      @formatResult(list)
