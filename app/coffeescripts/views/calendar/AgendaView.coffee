define [
  'i18n!calendar'
  'underscore'
  'Backbone'
  'compiled/collections/CalendarEventCollection'
  'jst/calendar/agendaView'
  'vendor/jquery.ba-tinypubsub'
], (I18n, _, Backbone, CalendarEventCollection, template) ->


  # Public: Helper function translate a model date string into a date object.
  #
  # m - A model instance.
  # prop - The name of the date property (default: 'start_at').
  toDate = _.compose(((d) -> new Date(d)),
                     ((m, prop = 'start_at') -> if m.get then m.get(prop) else m[prop]))

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

    # Public: Helper function to translate a model date into a timestamp.
    #
    # m - A model instance.
    # prop - The name of the date property (default: 'start_at').
    #
    # Returns a timestamp integer.
    toTime: _.compose(((d) -> d.getTime()), toDate)

    # Public: Helper function to translate a model date into a fudged date.
    #
    # m - A model instance.
    # prop - The name of the date property (default: 'start_at').
    #
    # Returns a fudged date.
    toFudgedDate: _.compose(((d) -> $.fudgeDateForProfileTimezone(d)), toDate)

    # Public: Given two collections, determine the latest shared date.
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

    # Public: Translate a list of event models to a hash.
    #
    # list - An array of model objects.
    # limit - A timestamp to stop returning events after (default: null).
    #
    # Returns a hash.
    eventListToHash: (list, limit = null) =>
      _.reduce(list, (result, event) =>
        return result if limit and limit < @toTime(event)

        event.set('start_at', @toFudgedDate(event))
        day = I18n.l('#date.formats.short_with_weekday', toDate(event))
        if assignment = event.get('assignment')
          assignment.due_at = @toFudgedDate(assignment, 'due_at')
        result[day] or= []
        result[day].push(event.toJSON())
        result
      , {})

    # Public: Format a hash of event data to an object ready to be sent to the template.
    #
    # result - A hash of event data from AgendaView#toJSON.
    #
    # Returns an object.
    formatResult: (events) =>
      result = {days: [], meta: {}}
      result.days.push(date: key, events: events[key]) for key of events
      result.meta.hasMore = @hasMore()
      result

    toJSON: ->
      limit  = @limitOf(@eventCollection, @assignmentCollection)
      list   = _.union(@eventCollection.models, @assignmentCollection.models)
      _.compose(@formatResult, @eventListToHash)(list, limit)
