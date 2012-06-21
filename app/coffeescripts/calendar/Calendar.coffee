# TODO
#  * Make assignments (due date) events non-resizable. Having an end date on them doesn't
#    make sense.

# requires jQuery, and vendor/fullcalendar

define [
  'i18n!calendar'
  'jquery'
  'compiled/util/hsvToRgb'
  'jst/calendar/calendarApp'
  'compiled/calendar/EventDataSource'
  'compiled/calendar/commonEventFactory'
  'compiled/calendar/ShowEventDetailsDialog'
  'compiled/calendar/EditEventDetailsDialog'
  'compiled/calendar/Scheduler'
  'vendor/fullcalendar'

  'jquery.instructure_misc_helpers'
  'jquery.instructure_misc_plugins'
  'vendor/jquery.ba-tinypubsub'
  'jqueryui/button'
], (I18n, $, hsvToRgb, calendarAppTemplate, EventDataSource, commonEventFactory, ShowEventDetailsDialog, EditEventDetailsDialog, Scheduler) ->

  class Calendar
    constructor: (selector, @contexts, @manageContexts, @dataSource, @options) ->
      @contextCodes = (context.asset_string for context in contexts)
      @visibleContextList = []
      # Display appointment slots for the specified appointment group
      @displayAppointmentEvents = null
      @activateEvent = @options?.activateEvent

      @activeAjax = 0

      $.subscribe
        "CommonEvent/eventDeleting" : @eventDeleting
        "CommonEvent/eventDeleted" : @eventDeleted
        "CommonEvent/eventSaving" : @eventSaving
        "CommonEvent/eventSaved" : @eventSaved
        "CommonEvent/eventSaveError" : @eventSaveFailed
        "Calendar/visibleContextListChanged" : @visibleContextListChanged
        "EventDataSource/ajaxStarted" : @ajaxStarted
        "EventDataSource/ajaxEnded" : @ajaxEnded
        "Calendar/refetchEvents" : @refetchEvents

      weekColumnFormatter = """
        '<span class="agenda-col-wrapper">
          <span class="day-num">'d'</span>
          <span class="day-and-month">
            <span class="day-name">'dddd'</span><br />
            <span class="month-name">'MMM'</span>
          </span>
        </span>'
      """

      fullCalendarParams =
        header:
          left:   'prev,today,next,title'
          center: ''
          right:  ''
        editable: true
        columnFormat:
          month: 'dddd'
          week: weekColumnFormatter
        allDayDefault: false
        buttonText:
          today: I18n.t 'today', 'Today'
        defaultEventMinutes: 60
        weekMode: 'variable'
        slotMinutes: 30
        firstHour: 7
        droppable: true
        dropAccept: '.undated_event'
        # In order to display times in the time zone configured in the user's profile,
        # and NOT the system timezone, we tell fullcalendar to ignore timezones and
        # give it Date objects that have had times shifted appropriately.
        ignoreTimezone: true
        # We do our own caching with our EventDataSource, so there's no need for
        # fullcalendar to also cache.
        lazyFetching: false
        events: @getEvents
        eventRender: @eventRender
        eventAfterRender: @eventAfterRender
        eventDrop: @eventDrop
        eventClick: @eventClick
        eventResize: @eventResize
        dayClick: @dayClick
        titleFormat:
          week: "MMM d[ yyyy]{ '&ndash;'[ MMM] d, yyyy}"
        viewDisplay: @viewDisplay
        drop: @drop

      data = @dataFromDocumentHash()
      if not data.view_start and @options?.viewStart
        data.view_start = @options.viewStart
        location.hash = $.encodeToHex(JSON.stringify(data))
      if data.view_start
        date = $.fullCalendar.parseISO8601(data.view_start)
        if date
          fullCalendarParams.year = date.getFullYear()
          fullCalendarParams.month = date.getMonth()
          fullCalendarParams.date = date.getDate()

      @el = $(selector).html calendarAppTemplate()

      if data.view_name == 'month' || data.view_name == 'agendaWeek'
        radioId = if data.view_name == 'agendaWeek' then 'week' else 'month'
        $("##{radioId}").click()
        fullCalendarParams.defaultView = data.view_name

      if data.show && data.show != ''
        @visibleContextList = data.show.split(',')

      @calendar = @el.find("div.calendar").fullCalendar fullCalendarParams

      $(document).fragmentChange(@fragmentChange)

      @el.find('#calendar_views').buttonset().find('input').change (event) =>
        @loadView $(event.target).attr('id')

      @$refresh_calendar_link = @el.find('#refresh_calendar_link').click @reloadClick
      @colorizeContexts()

      @scheduler = new Scheduler(".scheduler-wrapper", this)
      $('html').addClass('calendar-loaded')

      # Pre-load the appointment group list, for the badge
      @dataSource.getAppointmentGroups false, (data) =>
        required = 0
        for group in data
          required += 1 if group.requiring_action
        @el.find("#calendar-header .counter-badge")
          .toggle(required > 0)
          .text(required)

      window.setTimeout =>
        if data.view_name == 'scheduler'
          $("#scheduler").click()
          if data.appointment_group_id
            @scheduler.viewCalendarForGroupId data.appointment_group_id

    # FullCalendar callbacks

    getEvents: (start, end, cb) =>
      # We want to filter events received from the datasource. It seems like you should be able
      # to do this at render time as well, and return "false" in eventRender, but on the agenda
      # view that still assumes that the item is taking up space even though it's not displayed.
      filterEvents = (events) =>
        # De-dupe, and remove any actual scheduled events (since we don't want to
        # display that among the placeholders.)
        eventIds = {}
        return events unless events.length > 0
        for idx in [events.length - 1..0] # CS doesn't have a way to iterate a list in reverse ?!
          event = events[idx]

          keep = true
          # De-dupe
          if eventIds[event.id]
            keep = false
          else if event.isAppointmentGroupEvent()
            if !@displayAppointmentEvents
              # Handle normal calendar view, not scheduler view
              if !event.calendarEvent.reserve_url
                # If there is not a reserve_url set, then it is an
                # actual, scheduled event and not just a placeholder.
                keep = true
              else if event.calendarEvent.child_events_count > 0 && !event.calendarEvent.reserved
                # If this *is* a placeholder, and it has child events, and it's not reserved by me,
                # that means people have signed up for it, so we want to display it.
                keep = true
              else
                keep = false
            else
              if @displayAppointmentEvents.id == event.calendarEvent?.appointment_group_id
                # If this is an actual event for an appointment, don't show it
                keep = !!event.calendarEvent.reserve_url
              else
                # If this is an appointment event for a different appointment group, and it's full, show it
                keep = !event.calendarEvent.reserve_url

          events.splice(idx, 1) unless keep
          eventIds[event.id] = true

        events

      @dataSource.getEvents $.unfudgeDateForProfileTimezone(start), $.unfudgeDateForProfileTimezone(end), @visibleContextList, (events) =>
        if @displayAppointmentEvents
          @dataSource.getEventsForAppointmentGroup @displayAppointmentEvents, (aEvents) =>
            # Make sure any events in the current appointment group get marked -
            # order is important here, as some events in aEvents may also appear in
            # events. So clear events first, then mark aEvents. Our de-duping algorithm
            # will keep the duplicates at the end of the list first.
            for event in events
              event.removeClass('current-appointment-group')
            for event in aEvents
              event.addClass('current-appointment-group')
            cb(filterEvents(events.concat(aEvents)))
        else
          cb(filterEvents(events))

    eventRender: (event, element, view) =>
      $element = $(element)
      if event.isAppointmentGroupEvent() && @displayAppointmentEvents &&
          @displayAppointmentEvents.id == event.calendarEvent.appointment_group_id
        # We are in the scheduler view, and this event is part of the currently
        # displayed appointment group. If it's a real event, and not a placeholder,
        # we don't want to display it.

        # If this is a time slot event, we don't actually want to display the title -
        # just the reservation status.
        status = "Available" # TODO: i18n
        if event.calendarEvent.available_slots > 0
          status = "#{event.calendarEvent.available_slots} Available"
        if event.calendarEvent.available_slots == 0
          status = "Filled" # TODO: i18n
        if event.calendarEvent.reserved == true
          status = "Reserved" # TODO: i18n
        $element.find('.fc-event-title').text(status)
      $element.attr('title', $.trim("#{$element.find('.fc-event-time').text()}\n#{$element.find('.fc-event-title').text()}"))
      true

    eventAfterRender: (event, element, view) =>
      if event.eventType == 'assignment' && event.isDueAtMidnight()
        element.find('.fc-event-time').remove()
      if event.eventType == 'assignment' && view.name == "agendaWeek"
        element.height('') # this fixes it so it can wrap and not be forced onto 1 line
          .find('.ui-resizable-handle').remove()
      if event.eventType == 'calendar_event' && @options?.activateEvent && event.id == "calendar_event_#{@options?.activateEvent}"
        @options.activateEvent = null
        @eventClick event,
          # fake up the jsEvent
          currentTarget: element
          pageX: element.offset().left + parseInt(element.width() / 2)
          view

    eventDrop: (event, dayDelta, minuteDelta, allDay, revertFunc, jsEvent, ui, view) =>
      # isDueAtMidnight() will read cached midnightFudged property
      if event.eventType == "assignment" && event.isDueAtMidnight() && minuteDelta == 0
        event.start.setMinutes(59)
      event.saveDates null, revertFunc

    eventClick: (event, jsEvent, view) =>
      (new ShowEventDetailsDialog(event)).show(jsEvent)

    dayClick: (date, allDay, jsEvent, view) =>
      if @displayAppointmentEvents
        # Don't allow new event creation while in scheduler mode
        return

      # create a new dummy event
      event = commonEventFactory(null, @contexts)
      event.allDay = allDay
      event.date = date

      (new EditEventDetailsDialog(event)).show()

    eventResize: (event, dayDelta, minuteDelta, revertFunc, jsEvent, ui, view) =>
      event.saveDates null, revertFunc

    updateFragment: (opts) ->
      data = @dataFromDocumentHash()
      for k, v of opts
        data[k] = v
      location.replace("#" + $.encodeToHex(JSON.stringify(data)))

    viewDisplay: (view) =>
      @updateFragment view_start: $.dateToISO8601UTC(view.start)

    drop: (date, allDay, jsEvent, ui) =>
      el = $(jsEvent.target)
      event = el.data('calendarEvent')
      if event
        event.start = date
        event.addClass 'event_pending'
        @calendar.fullCalendar('renderEvent', event)
        event.saveDates null, -> console.log("could not save date on undated event")


    # DOM callbacks

    fragmentChange: (event, hash) =>
      data = @dataFromDocumentHash()
      view = @calendar?.fullCalendar('getView')
      return unless view && !$.isEmptyObject(data)

      if (data.view_name == 'month' || data.view_name == 'agendaWeek') && data.view_name != view.name
        @calendar.fullCalendar('changeView', data.view_name)

      if data.view_start && data.view_start != $.dateToISO8601UTC(view.start)
        date = $.fullCalendar.parseISO8601(data.view_start)
        if date
          @calendar.fullCalendar('gotoDate', date)

    reloadClick: (event) =>
      event.preventDefault()
      if @activeAjax == 0
        @dataSource.clearCache()
        if @currentView == 'scheduler'
          @scheduler.loadData()
        @calendar.fullCalendar('refetchEvents')


    # Subscriptions

    eventDeleting: (event) =>
      event.addClass 'event_pending'
      @calendar.fullCalendar('updateEvent', event)

    eventDeleted: (event) =>
      @calendar.fullCalendar('removeEvents', event.id)

    eventSaving: (event) =>
      return unless event.start # undated events can't be rendered

      event.addClass 'event_pending'
      if event.isNewEvent()
        @calendar.fullCalendar('renderEvent', event)
      else
        @calendar.fullCalendar('updateEvent', event)

    eventSaved: (event) =>
      event.removeClass 'event_pending'
      @calendar.fullCalendar('refetchEvents')
      # We'd like to just add the event to the calendar rather than fetching,
      # but the save may be as a result of moving an event from being undated
      # to dated, and in that case we don't know whether to just update it or
      # add it. Some new state would need to be kept to track that.
      # @calendar.fullCalendar('updateEvent', event)

    eventSaveFailed: (event) =>
      event.removeClass 'event_pending'
      if event.isNewEvent()
        @calendar.fullCalendar('removeEvents', event.id)
      else
        @calendar.fullCalendar('updateEvent', event)

    visibleContextListChanged: (newList) =>
      @visibleContextList = newList
      @calendar.fullCalendar('refetchEvents')

    ajaxStarted: () =>
      @activeAjax += 1
      @$refresh_calendar_link.addClass('loading')

    ajaxEnded: () =>
      @activeAjax -= 1
      @$refresh_calendar_link.removeClass('loading') unless @activeAjax

    refetchEvents: () =>
      @calendar.fullCalendar('refetchEvents')


    # Methods

    gotoDate: (d) -> @calendar.fullCalendar("gotoDate", d)

    loadView: (view) =>
      @updateFragment view_name: view

      if view != 'scheduler'
        @currentView = view
        @calendar.removeClass('scheduler-mode')
        @displayAppointmentEvents = null
        @scheduler.hide()
        @calendar.show()
        @calendar.fullCalendar('refetchEvents')
        @calendar.fullCalendar('changeView', if view == 'week' then 'agendaWeek' else 'month')
      else
        @currentView = 'scheduler'
        @calendar.addClass('scheduler-mode')
        @calendar.hide()
        @scheduler.show()

    # Private

    # we use a <div> (with a <style> inside it) because you cant set .innerHTML directly on a
    # <style> node in ie8
    $styleContainer = $('<div />').appendTo('body')

    # these represent a base hue to get color values from
    # they are combined with standard saturations and brigness to color-code events for each contex
    hues = [43, 5, 205, 85, 289, 63, 230, 186, 115, 330]

    cssColor = (h,s,b) ->
      rgbArray = hsvToRgb(h,s,b)
      "rgb(#{rgbArray.join ' ,'})"

    colorizeContexts: ->
      [bgSaturation, bgBrightness]         = [30, 96]
      [textSaturation, textBrightness]     = [60, 40]
      [strokeSaturation, strokeBrightness] = [70, 70]

      html = for contextCode, index in @contextCodes
        hue = hues[index % hues.length]
        ".group_#{contextCode}{
           color: #{cssColor hue, textSaturation, textBrightness};
           border-color: #{cssColor hue, strokeSaturation, strokeBrightness};
           background-color: #{cssColor hue, bgSaturation, bgBrightness};
        }"
      $styleContainer.html "<style>#{html.join('')}</style>"

    dataFromDocumentHash: () =>
      data = {}
      try
        data = $.parseJSON($.decodeFromHex(location.hash.substring(1))) || {}
      catch e
        data = {}
      data
