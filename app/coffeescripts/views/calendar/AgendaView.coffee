define [
  'i18n!calendar'
  'underscore'
  'Backbone'
  'compiled/collections/CalendarEventCollection'
  'jst/calendar/agendaView'
  'vendor/jquery.ba-tinypubsub'
], (I18n, _, Backbone, CalendarEventCollection, template) ->

  class AgendaView extends Backbone.View

    PER_PAGE: 50

    template: template

    events:
      'click .agenda-load-btn': 'loadMore'

    @optionProperty 'calendar'

    constructor: ->
      super
      @eventCollection      = new CalendarEventCollection
      @assignmentCollection = new CalendarEventCollection

    fetch: (contexts, start = new Date) ->
      end = new Date
      end.setYear(3000)

      start.setHours(0)
      start.setMinutes(0)
      start.setSeconds(0)

      @startDate = $.fudgeDateForProfileTimezone(start)

      $.publish('Calendar/loadStatus', true)

      p1 = @eventCollection.fetch
        data:
          context_codes: contexts
          end_date: $.dateToISO8601UTC(end)
          per_page: @PER_PAGE
          start_date: $.dateToISO8601UTC(start)
      p2 = @assignmentCollection.fetch
        data:
          context_codes: contexts
          end_date: $.dateToISO8601UTC(end)
          per_page: @PER_PAGE
          start_date: $.dateToISO8601UTC(start)
          type: 'assignment'
      $.when(p1, p2).then(@render)

    loadMore: (e) ->
      e.preventDefault()
      promises = _.map [@eventCollection, @assignmentCollection], (coll) ->
        coll.fetch(page: 'next') if coll.canFetch('next')
      $.when.apply($, _.compact(promises)).then(@render)

    render: =>
      super
      $.publish('Calendar/loadStatus', false)
      $.publish('Calendar/colorizeContexts')
      @$el.addClass('active')

    hasMore: ->
      @eventCollection.canFetch('next') or
        @assignmentCollection.canFetch('next')

    # Public: Helper function translate a model date string into a date object.
    #
    # m - A model instance.
    #
    # Returns a Date object.
    toDate: (m) -> new Date(m.get('start_at'))

    # Internal: Helper function to translate a model date into a timestamp.
    #
    # m - A model instance.
    #
    # Returns a timestamp integer.
    toTime: (m) => @toDate(m).getTime()

    # Internal: Helper function to translate a model date into a fudged date.
    #
    # m - A model instance or hash.
    # prop - The name of the date property (default: 'start_at').
    #
    # Returns a fudged date.
    toFudgedDate: (m, prop = 'start_at') =>
      d = if m.get then m.get(prop) else m[prop]
      $.fudgeDateForProfileTimezone(new Date(d))

    # Internal: Given two collections, determine the latest shared date.
    #
    # c1 - Collection object.
    # c2 - Collection object.
    #
    # Returns a date object or null if there is no limit.
    limitOf: (c1, c2) ->
      m1 = c1.max(@toTime)
      m2 = c2.max(@toTime)
      if c1.canFetch('next') and c2.canFetch('next')
        _.min([@toTime(m1), @toTime(m2)])
      else if c1.canFetch('next')
        @toTime(m1)
      else if c2.canFetch('next')
        @toTime(m2)
      else
        null

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

    # Internal: Do necessary changes on each event model in the list
    #
    # list - the list of the events to prepare
    #
    # Returns nothing.
    prepareEvents: (list) ->
      prepare = (event) ->
        event.set('start_at', @toFudgedDate(event))
        if assignment = event.get('assignment')
          assignment.due_at = @toFudgedDate(assignment, 'due_at')

      _.each(list, prepare, this)

    # Internal: returns the 'start_at' of the event formatted for the template
    #
    # event - the event to format
    #
    # Returns the formatted String
    formattedDayString: (event) =>
      I18n.l('#date.formats.short_with_weekday', @toDate(event))

    # Internal: change a box of events into an output hash for toJSON
    #
    # events - a box of events (all the events occur on the same day)
    #
    # Returns an Object with 'date' and 'events' keys.
    eventBoxToHash: (events) =>
      date: @formattedDayString(_.first(events))
      events: _.map(events, (e) -> e.toJSON())

    # Internal: Format a hash of event data to an object ready to be sent to the template.
    #
    # boxedEvents - A boxed list of events
    #
    # Returns an object in the format specified by toJSON.
    formatResult: (boxedEvents) ->
      days: _.map(boxedEvents, @eventBoxToHash)
      meta:
        hasMore: @hasMore()

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
      limit = @limitOf(@eventCollection, @assignmentCollection)
      list = _.union(@eventCollection.models, @assignmentCollection.models)
      list = _.filter(list, (e) => @toTime(e) < limit) if limit
      list = _.sortBy(list, @toTime)
      @prepareEvents(list)
      list = @sortedBoxBy(list, @formattedDayString)
      @formatResult(list)
