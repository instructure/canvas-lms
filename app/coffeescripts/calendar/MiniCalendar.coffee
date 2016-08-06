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
        height: 185
        buttonSRText:
          prev: I18n.t('Previous month')
          next: I18n.t('Next month')
        header:
          left: "prev"
          center: "title"
          right: "next"
        dayClick: @dayClick
        events: @getEvents
        eventRender: @eventRender
        droppable: true
        dragRevertDuration: 0
        dropAccept: '*'
        dropAccept: '.fc-event,.undated_event'
        drop: @drop
        eventDrop: @drop
        eventReceive: @drop
        , calendarDefaults)
      ,
        $.subscribe
          "Calendar/visibleContextListChanged" : @visibleContextListChanged
          "Calendar/refetchEvents" : @refetchEvents
          "Calendar/currentDate" : @gotoDate
          "CommonEvent/eventDeleted" : @eventSaved
          "CommonEvent/eventSaved" : @eventSaved
      )

    getEvents: (start, end, timezone, donecb, datacb) =>
      # Since we have caching (lazyFetching) turned off, we can rely on this
      # getting called every time we switch views, *before* the events are rendered.
      # That makes this a great place to clear out the previous classes.

      @calendar.find(".fc-widget-content td")
        .removeClass("event slot-available")
        .removeAttr('title')
      @mainCalendar.getEvents start, end, timezone, donecb, datacb

    dayClick: (date) =>
      @mainCalendar.gotoDate(date)

    gotoDate: (date) =>
      @calendar.fullCalendar("gotoDate", date)

    eventRender: (event, element, view) =>
      evDate = event.start.format("YYYY-MM-DD")
      td = view.el.find("*[data-date=\"#{evDate}\"]")[0];

      $(td).addClass("event")
      tooltip = I18n.t 'event_on_this_day', 'There is an event on this day'
      appointmentGroupBeingViewed = @mainCalendar.displayAppointmentEvents?.id
      if appointmentGroupBeingViewed && appointmentGroupBeingViewed == event.calendarEvent?.appointment_group_id && event.object.available_slots
        $(td).addClass("slot-available")
        tooltip = I18n.t 'open_appointment_on_this_day', 'There is an open appointment on this day'
      $(td).attr('title', tooltip)
      false # don't render the event

    visibleContextListChanged: (list) =>
      @refetchEvents()

    eventSaved: =>
      @refetchEvents()

    refetchEvents: () =>
      return unless @calendar.is(':visible')
      @calendar.fullCalendar('refetchEvents')

    drop: (date, jsEvent, ui, view) =>
      allDay = view.options.allDayDefault
      if ui.helper.is('.undated_event')
        @mainCalendar.drop(date, allDay, jsEvent, ui)
      else if ui.helper.is('.fc-event')
        @mainCalendar.dropOnMiniCalendar(date, allDay, jsEvent, ui)

