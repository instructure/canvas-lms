define 'compiled/calendar/MiniCalendar', [], () ->

  class
    constructor: (selector, mainCalendar) ->
      @mainCalendar = mainCalendar
      @calendar = $(selector).fullCalendar
        height: 240
        weekMode: "variable"
        allDayDefault: false
        lazyFetching: false
        ignoreTimezone: true
        header:
          left: "prev"
          center: "title"
          right: "next"
        dayClick: @dayClick
        events: @getEvents
        eventRender: @eventRender

        $.subscribe 
          "Calendar/visibleContextListChanged" : @visibleContextListChanged
          "Calendar/refetchEvents" : @refetchEvents

    getEvents: (start, end, cb) =>
      # Since we have caching (lazyFetching) turned off, we can rely on this
      # getting called every time we switch views, *before* the events are rendered.
      # That makes this a great place to clear out the previous classes.
      $(".fc-content td").removeClass "event"
      @mainCalendar.getEvents start, end, cb

    dayClick: (date) =>
      @mainCalendar.gotoDate(date)

    eventRender: (event, element, view) =>
      cell = view.dateCell(event.start)
      view.element
        .find("tr:nth-child(#{cell.row+1}) td:nth-child(#{cell.col+1})")
        .addClass("event")
      false # don't render the event

    visibleContextListChanged: (list) =>
      @calendar.fullCalendar('refetchEvents')

    refetchEvents: () =>
      @calendar.fullCalendar('refetchEvents')
