define [
  'jquery'
  'i18n!calendar'
  'underscore'
  'compiled/calendar/CalendarDefaults'
  'vendor/jquery.ba-tinypubsub'
], ($, I18n, _, calendarDefaults) ->
  class MiniCalendar
    constructor: (selector, @mainCalendar) ->
      @calendar = $(selector)
      @calendar.fullCalendar(_.defaults(
        height: 240
        header:
          left: "prev"
          center: "title"
          right: "next"
        dayClick: @dayClick
        events: @getEvents
        eventRender: @eventRender
        , calendarDefaults)
      ,
        $.subscribe
          "Calendar/visibleContextListChanged" : @visibleContextListChanged
          "Calendar/refetchEvents" : @refetchEvents
      )

    getEvents: (start, end, cb) =>
      # Since we have caching (lazyFetching) turned off, we can rely on this
      # getting called every time we switch views, *before* the events are rendered.
      # That makes this a great place to clear out the previous classes.
      @calendar.find(".fc-content td")
        .removeClass("event slot-available")
        .removeAttr('title')
      @mainCalendar.getEvents start, end, cb

    dayClick: (date) =>
      @mainCalendar.gotoDate(date)

    eventRender: (event, element, view) =>
      cell = view.dateCell(event.start)
      td = view.element.find("tr:nth-child(#{cell.row+1}) td:nth-child(#{cell.col+1})")
      td.addClass("event")
      tooltip = I18n.t 'event_on_this_day', 'There is an event on this day'
      appointmentGroupBeingViewed = @mainCalendar.displayAppointmentEvents?.id
      if appointmentGroupBeingViewed && appointmentGroupBeingViewed == event.calendarEvent?.appointment_group_id && event.object.available_slots
        td.addClass("slot-available")
        tooltip = I18n.t 'open_appointment_on_this_day', 'There is an open appointment on this day'
      td.attr('title', tooltip)
      false # don't render the event

    visibleContextListChanged: (list) =>
      @calendar.fullCalendar('refetchEvents')

    refetchEvents: () =>
      @calendar.fullCalendar('refetchEvents')
