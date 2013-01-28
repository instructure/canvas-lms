define [
  'jquery'
  'jst/calendar/undatedEvents'
  'compiled/calendar/EventDataSource'
  'compiled/calendar/ShowEventDetailsDialog'
  'jqueryui/draggable'
  'jquery.disableWhileLoading'
  'vendor/jquery.ba-tinypubsub'
], ($, undatedEventsTemplate, EventDataSource, ShowEventDetailsDialog) ->

  class UndatedEventsList
    constructor: (selector, @dataSource) ->
      @div = $(selector).html undatedEventsTemplate({})
      @hidden = true
      @visibleContextList = []

      $.subscribe
        "CommonEvent/eventDeleting" : @eventSaving
        "CommonEvent/eventDeleted" : @eventSaved
        "CommonEvent/eventSaving" : @eventSaving
        "CommonEvent/eventSaved" : @eventSaved
        "Calendar/visibleContextListChanged" : @visibleContextListChanged

      @div.on('click', '.event', @clickEvent)
          .on('click', '.undated_event_title', @clickEvent)
          .on('click', '.undated-events-link', @show)

    load: =>
      return if @hidden

      loadingDfd = new $.Deferred()
      @div.disableWhileLoading(loadingDfd, {
        buttons: ['.undated-events-link'],
        opacity: 1,
        lines: 8, length: 2, width: 2, radius: 3
      })

      @dataSource.getEvents null, null, @visibleContextList, (events) =>
        loadingDfd.resolve()
        for e in events
          e.details_url = e.fullDetailsURL()
          e.icon = if e.calendarEvent then 'calendar-day' else 'assignment'
        @div.html undatedEventsTemplate({ events: events })

        for e in events
          @div.find(".#{e.id}").data 'calendarEvent', e

        @div.find('.event').draggable
          revert: 'invalid'
          revertDuration: 0
          helper: 'clone'
          start: ->
            $(this).hide()
          stop: (e, ui) ->
            # Only show the element after the drag stops if it doesn't have a start date now
            # (meaning it wasn't dropped on the calendar)
            $(this).show() unless $(this).data('calendarEvent').start

    show: (event) =>
      event.preventDefault()
      @hidden = false
      @load()

    clickEvent: (jsEvent) =>
      jsEvent.preventDefault()
      eventId = $(jsEvent.target).data('event-id')
      # Support handling a contained element being clicked within an event
      eventId ||= $(jsEvent.target).closest('.event').data('event-id')
      event = @dataSource.eventWithId(eventId)
      if event
        new ShowEventDetailsDialog(event, @dataSource).show jsEvent

    visibleContextListChanged: (list) =>
      @visibleContextList = list
      @load() unless @hidden

    eventSaving: (event) =>
      @div.find(".#{event.id}").addClass('event_pending')

    eventSaved: =>
      @load()
