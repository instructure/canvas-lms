# TODO
#  * Make assignments (due date) events non-resizable. Having an end date on them doesn't
#    make sense.

# requires jQuery, and vendor/fullcalendar

define [
  'i18n!calendar'
  'jquery'
  'underscore'
  'compiled/userSettings'
  'compiled/util/hsvToRgb'
  'compiled/util/colorSlicer'
  'jst/calendar/calendarApp'
  'compiled/calendar/EventDataSource'
  'compiled/calendar/commonEventFactory'
  'compiled/calendar/ShowEventDetailsDialog'
  'compiled/calendar/EditEventDetailsDialog'
  'compiled/calendar/Scheduler'
  'compiled/views/calendar/CalendarNavigator'
  'compiled/views/calendar/AgendaView'
  'compiled/calendar/CalendarDefaults'
  'vendor/fullcalendar'

  'jquery.instructure_misc_helpers'
  'jquery.instructure_misc_plugins'
  'vendor/jquery.ba-tinypubsub'
  'jqueryui/button'
], (I18n, $, _, userSettings, hsvToRgb, colorSlicer, calendarAppTemplate, EventDataSource, commonEventFactory, ShowEventDetailsDialog, EditEventDetailsDialog, Scheduler, CalendarNavigator, AgendaView, calendarDefaults) ->

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
        'CommonEvent/assignmentSaved' : @updateOverrides
        'Calendar/colorizeContexts': @colorizeContexts

      weekColumnFormatter = """
        '<span class="agenda-col-wrapper">
          <span class="day-num">'d'</span>
          <span class="day-and-month">
            <span class="day-name">'dddd'</span><br />
            <span class="month-name">'MMM'</span>
          </span>
        </span>'
      """

      @header = @options.header

      fullCalendarParams = _.defaults(
        header: false
        editable: true
        columnFormat:
          month: if ENV.CALENDAR.SHOW_AGENDA then 'ddd' else 'dddd'
          week: weekColumnFormatter
        buttonText:
          today: I18n.t 'today', 'Today'
        defaultEventMinutes: 60
        slotMinutes: 30
        firstHour: 7
        droppable: true
        dropAccept: '.undated_event'
        events: @getEvents
        eventRender: @eventRender
        eventAfterRender: @eventAfterRender
        eventDragStart: @eventDragStart
        eventDrop: @eventDrop
        eventClick: @eventClick
        eventResize: @eventResize
        eventResizeStart: @eventResizeStart
        dayClick: @dayClick
        addEventClick: @addEventClick
        titleFormat:
          week: "MMM d[ yyyy]{ '&ndash;'[ MMM] d, yyyy}"
        viewDisplay: @viewDisplay
        windowResize: @windowResize
        drop: @drop
        , calendarDefaults)

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

      @schedulerNavigator = new CalendarNavigator(el: $('.scheduler_navigator'), showAgenda: @options.showAgenda)
      @schedulerNavigator.hide()

      data.view_name = 'agendaWeek' if data.view_name == 'week'
      if data.view_name == 'month' || data.view_name == 'agendaWeek'
        viewName = if data.view_name == 'agendaWeek' then 'week' else 'month'
        @header.selectView(viewName)
        fullCalendarParams.defaultView = data.view_name
      else if data.view_name == 'agenda'
        @header.selectView(data.view_name)

      if data.show && data.show != ''
        @visibleContextList = data.show.split(',')

      @calendar = @el.find("div.calendar").fullCalendar fullCalendarParams

      $(document).fragmentChange(@fragmentChange)

      @colorizeContexts()

      @scheduler = new Scheduler(".scheduler-wrapper", this)

      if @options.showScheduler
        # Pre-load the appointment group list, for the badge
        @dataSource.getAppointmentGroups false, (data) =>
          required = 0
          for group in data
            required += 1 if group.requiring_action
          @header.setSchedulerBadgeCount(required)

      @connectHeaderEvents()
      @connectSchedulerNavigatorEvents()
      @agenda = new AgendaView(el: $('.agenda-wrapper'))
      @loadView('agenda') if data.view_name is 'agenda'

      window.setTimeout =>
        if data.view_name == 'scheduler'
          @header.selectView('scheduler')
          if data.appointment_group_id
            @scheduler.viewCalendarForGroupId data.appointment_group_id

    connectHeaderEvents: ->
      @header.on('navigatePrev',  => @calendar.fullCalendar('prev'))
      @header.on 'navigateToday', =>
        @calendar.fullCalendar('today')
        @agendaViewFetch(new Date) if @currentView == 'agenda'
      @header.on('navigateNext',  => @calendar.fullCalendar('next'))
      @header.on('navigateDate',  (selectedDate) => @selectDate(selectedDate))
      @header.on('week', => @loadView('week'))
      @header.on('month', => @loadView('month'))
      @header.on('agenda', => @loadView('agenda'))
      @header.on('scheduler', => @loadView('scheduler'))
      @header.on('createNewEvent', @addEventClick)
      @header.on('refreshCalendar', @reloadClick)
      @header.on('done', @schedulerSingleDoneClick)

    connectSchedulerNavigatorEvents: ->
      @schedulerNavigator.on('navigatePrev',  => @calendar.fullCalendar('prev'))
      @schedulerNavigator.on('navigateToday', => @calendar.fullCalendar('today'))
      @schedulerNavigator.on('navigateNext',  => @calendar.fullCalendar('next'))
      @schedulerNavigator.on('navigateDate',  (selectedDate) => @selectDate(selectedDate))

    selectDate: (selectedDate) ->
      @calendar.fullCalendar('gotoDate', selectedDate)
      @agendaViewFetch(selectedDate) if @currentView == 'agenda'

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
              else if event.calendarEvent.child_events_count > 0 && !event.calendarEvent.reserved && event.can_edit
                # If this *is* a placeholder, and it has child events, and it's not reserved by me,
                # that means people have signed up for it, so we want to display it if I am able to
                #  manage it (as a teacher or TA might)
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

    # Close all event details popup on the page and have them cleaned up.
    closeEventPopups: ->
      # Close any open popup as it gets detached when rendered
      $('.event-details').each ->
        existingDialog = $(this).data('showEventDetailsDialog')
        if existingDialog
          existingDialog.close()

    windowResize: (view) =>
      @closeEventPopups()

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
      
      # TODO: i18n
      timeString = if !event.endDate() || event.startDate().getTime() == event.endDate().getTime()
          @calendar.fullCalendar('formatDate', event.startDate(), 'h:mmtt')
        else
          @calendar.fullCalendar('formatDates', event.startDate(), event.endDate(), 'h:mmtt{ – h:mmtt}')
      screenReaderTitleHint = if event.eventType.match(/assignment/)
          I18n.t('event_assignment_title', 'Assignment Title: ')
        else
          I18n.t('event_event_title', 'Event Title: ')

      $element.attr('title', $.trim("#{timeString}\n#{$element.find('.fc-event-title').text()}\n\n#{I18n.t('calendar_title', 'Calendar:')} #{event.contextInfo.name}"))
      $element.find('.fc-event-inner').prepend($("<span class='screenreader-only'>#{I18n.t('calendar_title', 'Calendar:')} #{event.contextInfo.name}</span>"));
      $element.find('.fc-event-title').prepend($("<span class='screenreader-only'>#{screenReaderTitleHint}</span>"))

      if ENV.CALENDAR.SHOW_AGENDA && event.eventType.match(/assignment/)
        isQuiz = event.assignment.submission_types?.length && event.assignment.submission_types[0] == 'online_quiz'
        element.find('.fc-event-inner').prepend($('<i />', {'class': if isQuiz then 'icon-quiz' else 'icon-assignment'}))
      true

    eventAfterRender: (event, element, view) =>
      if event.isDueAtMidnight()
        # show the actual time instead of the midnight fudged time
        element.find('.fc-event-time').html @calendar.fullCalendar('formatDate', event.startDate(), 'h(:mm)t')
      if event.eventType.match(/assignment/) && view.name == "agendaWeek"
        element.height('') # this fixes it so it can wrap and not be forced onto 1 line
          .find('.ui-resizable-handle').remove()
      if ENV.CALENDAR.SHOW_AGENDA
        if event.eventType.match(/assignment/) && event.isDueAtMidnight()
          element.find('.fc-event-time').empty()
      else
        if event.eventType.match(/assignment/)
          element.find('.fc-event-time').html I18n.t('labels.due', 'due')
      if event.eventType == 'calendar_event' && @options?.activateEvent && event.id == "calendar_event_#{@options?.activateEvent}"
        @options.activateEvent = null
        @eventClick event,
          # fake up the jsEvent
          currentTarget: element
          pageX: element.offset().left + parseInt(element.width() / 2)
          view

    eventDragStart: (event, jsEvent, ui, view) =>
      @closeEventPopups()

    eventResizeStart: (event, jsEvent, ui, view) =>
      @closeEventPopups()

    # event triggered by items being dropped from within the calendar
    eventDrop: (event, dayDelta, minuteDelta, allDay, revertFunc, jsEvent, ui, view) =>

      if event.eventType == "assignment" && allDay
        revertFunc()
        return

      # isDueAtMidnight() will read cached midnightFudged property
      if event.eventType == "assignment" && event.isDueAtMidnight() && minuteDelta == 0
        event.start.setMinutes(59)

      # set event as an all day event if allDay
      if event.eventType == "calendar_event" && allDay
        event.allDay = true

      # if a short event gets dragged, we don't want to change its duration
      if event.end && event.endDate()
        originalDuration = event.endDate().getTime() - event.startDate().getTime()
        event.end = new Date(event.start.getTime() + originalDuration)

      event.saveDates null, revertFunc

    eventResize: (event, dayDelta, minuteDelta, revertFunc, jsEvent, ui, view) =>
      # assignments can't be resized
      # if short events are being resized, assume the user knows what they're doing
      event.saveDates null, revertFunc

    addEventClick: (event, jsEvent, view) =>
      if @displayAppointmentEvents
        # Don't allow new event creation while in scheduler mode
        return

      # create a new dummy event
      allowedContexts = userSettings.get('checked_calendar_codes') or _.pluck(@contexts, 'asset_string')
      activeContexts  = _.filter @contexts, (c) -> _.contains(allowedContexts, c.asset_string)
      event = commonEventFactory(null, activeContexts)

      new EditEventDetailsDialog(event).show()

    eventClick: (event, jsEvent, view) =>
      $event = $(jsEvent.currentTarget)
      if !$event.hasClass('event_pending')
        detailsDialog = new ShowEventDetailsDialog(event)
        $event.data('showEventDetailsDialog', detailsDialog)
        detailsDialog.show jsEvent

    dayClick: (date, allDay, jsEvent, view) =>
      if @displayAppointmentEvents
        # Don't allow new event creation while in scheduler mode
        return

      # create a new dummy event
      allowedContexts = userSettings.get('checked_calendar_codes') or _.pluck(@contexts, 'asset_string')
      activeContexts  = _.filter @contexts, (c) -> _.contains(allowedContexts, c.asset_string)
      event = commonEventFactory(null, activeContexts)
      event.allDay = allDay
      event.date = date

      (new EditEventDetailsDialog(event)).show()

    updateFragment: (opts) ->
      data = @dataFromDocumentHash()
      for k, v of opts
        data[k] = v
      location.replace("#" + $.encodeToHex(JSON.stringify(data)))

    viewDisplay: (view) =>
      @updateFragment view_start: $.dateToISO8601UTC(view.start)
      @setDateTitle(view.title)

    setDateTitle: (title) =>
      @header.setHeaderText(title)
      @schedulerNavigator.setTitle(title)

    # event triggered by items being dropped from outside the calendar
    drop: (date, allDay, jsEvent, ui) =>
      eventId    = $(ui.helper).data('event-id')
      event      = $("[data-event-id=#{eventId}]").data('calendarEvent')
      revertFunc = -> console.log("could not save date on undated event")

      if event
        event.start = date
        event.addClass 'event_pending'

        if event.eventType == "assignment" && allDay
          revertFunc()
          return

        # isDueAtMidnight() will read cached midnightFudged property
        if event.eventType == "assignment" && event.isDueAtMidnight() && minuteDelta == 0
          event.start.setMinutes(59)

        # set event as an all day event if allDay
        if event.eventType == "calendar_event" && allDay
          event.allDay = true

        # if a short event gets dragged, we don't want to change its duration
        if event.end && event.endDate()
          originalDuration = event.endDate().getTime() - event.startDate().getTime()
          event.end = new Date(event.start.getTime() + originalDuration)

        @calendar.fullCalendar('renderEvent', event)
        event.saveDates null, revertFunc

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
      event?.preventDefault()
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

      # If we just saved a new event then the id field has changed from what it
      # was in eventSaving. So we need to clear out the old _id that
      # fullcalendar stores for itself because the id has changed.
      # This is another reason to do a refetchEvents instead of just an update.
      delete event._id
      @calendar.fullCalendar('refetchEvents')
      # We'd like to just add the event to the calendar rather than fetching,
      # but the save may be as a result of moving an event from being undated
      # to dated, and in that case we don't know whether to just update it or
      # add it. Some new state would need to be kept to track that.
      # @calendar.fullCalendar('updateEvent', event)
      @closeEventPopups()

    eventSaveFailed: (event) =>
      event.removeClass 'event_pending'
      if event.isNewEvent()
        @calendar.fullCalendar('removeEvents', event.id)
      else
        @calendar.fullCalendar('updateEvent', event)

    # When an assignment event is updated, update its related overrides.
    updateOverrides: (event) =>
      _.each @dataSource.cache.contexts[event.contextCode()].events, (override, key) ->
        if key.match(/override/) and event.assignment.id == override.assignment.id
          override.updateAssignmentTitle(event.title)

    visibleContextListChanged: (newList) =>
      @visibleContextList = newList
      @loadAgendaView() if @currentView == 'agenda'
      @calendar.fullCalendar('refetchEvents')

    ajaxStarted: () =>
      @activeAjax += 1
      @header.animateLoading(true)

    ajaxEnded: () =>
      @activeAjax -= 1
      @header.animateLoading(@activeAjax > 0)

    refetchEvents: () =>
      @calendar.fullCalendar('refetchEvents')


    # Methods

    gotoDate: (d) -> @calendar.fullCalendar("gotoDate", d)

    loadView: (view) =>
      @updateFragment view_name: view

      $('.agenda-wrapper').removeClass('active')
      if view != 'scheduler' and view != 'agenda'
        @currentView = view
        @calendar.removeClass('scheduler-mode').removeClass('agenda-mode')
        @displayAppointmentEvents = null
        @scheduler.hide()
        @calendar.show()
        @header.showNavigator()
        @schedulerNavigator.hide()
        @calendar.fullCalendar('refetchEvents')
        @calendar.fullCalendar('changeView', if view == 'week' then 'agendaWeek' else 'month')
        @calendar.fullCalendar('render')
      else if view == 'scheduler'
        @currentView = 'scheduler'
        @calendar.addClass('scheduler-mode')
        @calendar.hide()
        @header.showSchedulerTitle()
        @schedulerNavigator.hide()
        @scheduler.show()
      else
        @loadAgendaView()
        @calendar.hide()
        @scheduler.hide()
        @header.showNavigator()

    loadAgendaView: ->
      oldView = @currentView
      calendarDate = @calendar.fullCalendar('getDate')
      now = $.fudgeDateForProfileTimezone(new Date)
      if oldView == 'month'
        if calendarDate.getMonth() == now.getMonth()
          start = now
        else
          start = new Date(calendarDate.getTime())
          start.setDate(1)
      else if oldView == 'week'
        if calendarDate.getWeek() == now.getWeek()
          start = now
        else
          start = new Date(calendarDate.getTime())
          until start.getDay() == 0
            start.setDate(start.getDate() - 1)
      else
        start = now

      @currentView = 'agenda'
      @agendaViewFetch(start)

    agendaViewFetch: (start) ->
      start.setHours(0)
      start.setMinutes(0)
      start.setSeconds(0)
      @setDateTitle(I18n.l('#date.formats.medium', start))
      @agenda.fetch(@visibleContextList, start)

    showSchedulerSingle: ->
      @calendar.show()
      @calendar.fullCalendar('changeView', 'agendaWeek')
      @header.showDoneButton()
      @schedulerNavigator.show()

    schedulerSingleDoneClick: =>
      @scheduler.doneClick()
      @header.showSchedulerTitle()
      @schedulerNavigator.hide()

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

    colorizeContexts: =>
      if ENV.CALENDAR.SHOW_AGENDA
        colors = colorSlicer.getColors(@contextCodes.length)
        html = for contextCode, index in @contextCodes
          color = colors[index]
          ".group_#{contextCode}{
             color: #{color};
             border-color: #{color};
             background-color: #{color};
          }"
      else
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
