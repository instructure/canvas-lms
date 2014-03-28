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
  'bower/color-slicer/dist/color-slicer'
  'jst/calendar/calendarApp'
  'compiled/calendar/EventDataSource'
  'compiled/calendar/commonEventFactory'
  'compiled/calendar/ShowEventDetailsDialog'
  'compiled/calendar/EditEventDetailsDialog'
  'compiled/calendar/Scheduler'
  'compiled/views/calendar/CalendarNavigator'
  'compiled/views/calendar/AgendaView'
  'compiled/calendar/CalendarDefaults'
  'compiled/util/deparam'

  'vendor/fullcalendar'
  'jquery.instructure_misc_helpers'
  'jquery.instructure_misc_plugins'
  'vendor/jquery.ba-tinypubsub'
  'jqueryui/button'
], (I18n, $, _, userSettings, hsvToRgb, colorSlicer, calendarAppTemplate, EventDataSource, commonEventFactory, ShowEventDetailsDialog, EditEventDetailsDialog, Scheduler, CalendarNavigator, AgendaView, calendarDefaults, deparam) ->

  class Calendar
    constructor: (selector, @contexts, @manageContexts, @dataSource, @options) ->
      @contextCodes = (context.asset_string for context in contexts)
      @visibleContextList = []
      # Display appointment slots for the specified appointment group
      @displayAppointmentEvents = null
      @activateEvent = @options?.activateEvent

      @activeAjax = 0

      @subscribeToEvents()
      @header = @options.header

      @el = $(selector).html calendarAppTemplate()

      @schedulerNavigator = new CalendarNavigator(el: $('.scheduler_navigator'))
      @schedulerNavigator.hide()

      @agenda = new AgendaView(el: $('.agenda-wrapper'), dataSource: @dataSource)
      @scheduler = new Scheduler(".scheduler-wrapper", this)

      fullCalendarParams = @initializeFullCalendarParams()

      data = @dataFromDocumentHash()
      if not data.view_start and @options?.viewStart
        data.view_start = @options.viewStart
        @updateFragment data
      if data.view_start
        date = $.fullCalendar.parseISO8601(data.view_start)
      else
        date = $.fudgeDateForProfileTimezone(new Date)
      fullCalendarParams.year = date.getFullYear()
      fullCalendarParams.month = date.getMonth()
      fullCalendarParams.date = date.getDate()

      @calendar = @el.find("div.calendar").fullCalendar fullCalendarParams

      if data.show && data.show != ''
        @visibleContextList = data.show.split(',')

      $(document).fragmentChange(@fragmentChange)

      @colorizeContexts()

      if @options.showScheduler
        # Pre-load the appointment group list, for the badge
        @dataSource.getAppointmentGroups false, (data) =>
          required = 0
          for group in data
            required += 1 if group.requiring_action
          @header.setSchedulerBadgeCount(required)

      @connectHeaderEvents()
      @connectSchedulerNavigatorEvents()
      @connectAgendaEvents()

      @header.selectView(@getCurrentView())

      if data.view_name == 'scheduler' && data.appointment_group_id
        @scheduler.viewCalendarForGroupId data.appointment_group_id

      window.setInterval(@drawNowLine, 1000 * 60)



    subscribeToEvents: ->
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

    connectHeaderEvents: ->
      @header.on('navigatePrev',  => @handleArrow('prev'))
      @header.on 'navigateToday', @today
      @header.on('navigateNext',  => @handleArrow('next'))
      @header.on('navigateDate', @gotoDate)
      @header.on('week', => @loadView('week'))
      @header.on('month', => @loadView('month'))
      @header.on('agenda', => @loadView('agenda'))
      @header.on('scheduler', => @loadView('scheduler'))
      @header.on('createNewEvent', @addEventClick)
      @header.on('refreshCalendar', @reloadClick)
      @header.on('done', @schedulerSingleDoneClick)

    connectSchedulerNavigatorEvents: ->
      @schedulerNavigator.on('navigatePrev',  => @handleArrow('prev'))
      @schedulerNavigator.on('navigateToday', @today)
      @schedulerNavigator.on('navigateNext',  => @handleArrow('next'))
      @schedulerNavigator.on('navigateDate', @gotoDate)

    connectAgendaEvents: ->
      @agenda.on('agendaDateRange', @renderDateRange)

    initializeFullCalendarParams: ->
      _.defaults(
        header: false
        editable: true
        columnFormat:
          month: 'ddd'
          week: 'ddd M/d'
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

        dragRevertDuration: { month: 0 }
        dragHelper: { month: 'clone' }
        dragAppendTo: { month: '#calendar-drag-and-drop-container' }
        dragZIndex: { month: 350 }
        dragCursorAt: { month: {top: -5, left: -5} }

        , calendarDefaults)

    today: =>
      now = $.fudgeDateForProfileTimezone(new Date)
      @gotoDate(now)

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

      @dataSource.getEvents start, end, @visibleContextList, (events) =>
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
      @drawNowLine()

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
      element.find('.fc-event-inner').prepend($('<i />', {'class': "icon-#{event.iconType()}"}))
      true

    eventAfterRender: (event, element, view) =>
      if event.isDueAtMidnight()
        # show the actual time instead of the midnight fudged time
        time = element.find('.fc-event-time')
        html = time.html()
        # the time element also contains the title for calendar events
        html = html.replace(/^\d+:\d+\w?/, @calendar.fullCalendar('formatDate', event.startDate(), 'h(:mm)t'))
        time.html(html)
      if event.eventType.match(/assignment/) && view.name == "agendaWeek"
        element.height('') # this fixes it so it can wrap and not be forced onto 1 line
          .find('.ui-resizable-handle').remove()
      if event.eventType.match(/assignment/) && event.isDueAtMidnight() && view.name == "month"
        element.find('.fc-event-time').empty()
      if event.eventType == 'calendar_event' && @options?.activateEvent && event.id == "calendar_event_#{@options?.activateEvent}"
        @options.activateEvent = null
        @eventClick event,
          # fake up the jsEvent
          currentTarget: element
          pageX: element.offset().left + parseInt(element.width() / 2)
          view

    eventDragStart: (event, jsEvent, ui, view) =>
      @lastEventDragged = event
      @closeEventPopups()

    eventResizeStart: (event, jsEvent, ui, view) =>
      @closeEventPopups()

    # event triggered by items being dropped from within the calendar
    eventDrop: (event, dayDelta, minuteDelta, allDay, revertFunc, jsEvent, ui, view) =>
      @_eventDrop(event, minuteDelta, allDay, revertFunc)

    _eventDrop: (event, minuteDelta, allDay, revertFunc) ->
      if @currentView == 'week' && allDay && event.eventType == "assignment"
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
      return true

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
      event.date = @getCurrentDate()

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
      changed = false
      for k, v of opts
        changed = true if data[k] != v
        data[k] = v
      location.href = "#" + $.param(data) if changed

    viewDisplay: (view) =>
      @setDateTitle(view.title)
      @drawNowLine()

    isSameWeek: (date1, date2) ->
      # Note that our date-js's getWeek is Monday-based.
      sunday = new Date(date1.getTime())
      sunday.setDate(sunday.getDate() - sunday.getDay())
      weekStart = sunday.getTime()
      weekEnd = weekStart + 7 * 24 * 3600 * 1000
      weekStart <= date2 <= weekEnd

    drawNowLine: =>
      return unless @currentView == 'week'

      if !@nowLine
        @nowLine = $('<div />', {'class': 'calendar-nowline'})
      $('.fc-agenda-slots').parent().append(@nowLine)

      now = $.fudgeDateForProfileTimezone(new Date)
      midnight = new Date(now.getTime())
      midnight.setHours(0, 0, 0)
      seconds = (now.getTime() - midnight.getTime())/1000

      @nowLine.toggle(@isSameWeek(@getCurrentDate(), now))

      @nowLine.css('width', $('.fc-agenda-slots .fc-widget-content:first').css('width'))
      secondHeight = $('.fc-agenda-slots').css('height').replace('px', '')/24/3600
      @nowLine.css('top', seconds*secondHeight + 'px')

    setDateTitle: (title) =>
      @header.setHeaderText(title)
      @schedulerNavigator.setTitle(title)

    # event triggered by items being dropped from outside the calendar
    drop: (date, allDay, jsEvent, ui) =>
      eventId    = $(ui.helper).data('event-id')
      event      = $("[data-event-id=#{eventId}]").data('calendarEvent')
      return unless event
      event.start = date
      event.addClass 'event_pending'
      revertFunc = -> console.log("could not save date on undated event")

      return unless @_eventDrop(event, 0, allDay, revertFunc)
      @calendar.fullCalendar('renderEvent', event)

    # callback from minicalendar telling us an event from here was dragged there
    dropOnMiniCalendar: (date, allDay, jsEvent, ui) ->
      event = @lastEventDragged
      return unless event
      originalStart = new Date(event.start.getTime())
      originalEnd = new Date(event.end?.getTime())
      @copyYMD(event.start, date)
      @copyYMD(event.end, date)
      @_eventDrop(event, 0, false, =>
        event.start = originalStart
        event.end = originalEnd
        @calendar.fullCalendar('updateEvent', event)
      )

    copyYMD: (target, source) ->
      return unless target
      target.setFullYear(source.getFullYear())
      target.setMonth(source.getMonth())
      target.setDate(source.getDate())

    # DOM callbacks

    fragmentChange: (event, hash) =>
      data = @dataFromDocumentHash()
      return if $.isEmptyObject(data)

      if data.view_name != @currentView
        @loadView(data.view_name)

      @gotoDate(@getCurrentDate())

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

    gotoDate: (d) =>
      @calendar.fullCalendar("gotoDate", d)
      @agendaViewFetch(d) if @currentView == 'agenda'
      @setCurrentDate(d)

    handleArrow: (type) ->
      @calendar.fullCalendar(type)
      calendarDate = @calendar.fullCalendar('getDate')
      now = $.fudgeDateForProfileTimezone(new Date)
      if @currentView == 'month'
        if calendarDate.getMonth() == now.getMonth() && calendarDate.getFullYear() == now.getFullYear()
          start = now
        else
          start = new Date(calendarDate.getTime())
          start.setDate(1)
      else
        if @isSameWeek(calendarDate, now)
          start = now
        else
          start = new Date(calendarDate.getTime())
          start.setDate(start.getDate() - start.getDay())
      @setCurrentDate(start)

    setCurrentDate: (d) ->
      @updateFragment view_start: d.toISOString()
      $.publish('Calendar/currentDate', d)

    getCurrentDate: () ->
      data = @dataFromDocumentHash()
      if data.view_start
        $.fullCalendar.parseISO8601(data.view_start)
      else
        $.fudgeDateForProfileTimezone(new Date)

    setCurrentView: (view) ->
      @updateFragment view_name: view
      @currentView = view
      userSettings.set('calendar_view', view)

    getCurrentView: ->
      if @currentView
        @currentView
      else if (data = @dataFromDocumentHash()) && data.view_name
        data.view_name
      else if userSettings.get('calendar_view')
        userSettings.get('calendar_view')
      else
        'month'

    loadView: (view) =>
      return if view == @currentView
      @setCurrentView(view)

      $('.agenda-wrapper').removeClass('active')
      @header.showNavigator()
      @header.showPrevNext()
      @header.hideAgendaRecommendation()
      if view != 'scheduler' and view != 'agenda'
        @calendar.removeClass('scheduler-mode').removeClass('agenda-mode')
        @displayAppointmentEvents = null
        @scheduler.hide()
        @header.showAgendaRecommendation()
        @calendar.show()
        @schedulerNavigator.hide()
        @calendar.fullCalendar('refetchEvents')
        @calendar.fullCalendar('changeView', if view == 'week' then 'agendaWeek' else 'month')
        @calendar.fullCalendar('render')
      else if view == 'scheduler'
        @calendar.addClass('scheduler-mode')
        @calendar.hide()
        @header.showSchedulerTitle()
        @schedulerNavigator.hide()
        @scheduler.show()
      else
        @calendar.hide()
        @scheduler.hide()
        @header.hidePrevNext()

    loadAgendaView: ->
      date = @getCurrentDate()
      @agendaViewFetch(date)

    agendaViewFetch: (start) ->
      start.setHours(0)
      start.setMinutes(0)
      start.setSeconds(0)
      @setDateTitle(I18n.l('#date.formats.medium', start))
      @agenda.fetch(@visibleContextList, start)

    renderDateRange: (start, end) =>
      @setDateTitle(I18n.l('#date.formats.medium', start)+' &ndash; '+I18n.l('#date.formats.medium', end))
      # for "load more" with voiceover, we want the alert to happen later so
      # the focus change doesn't interrupt it.
      window.setTimeout =>
        $.screenReaderFlashMessage I18n.t('agenda_view_displaying_start_end', "Now displaying %{start} through %{end}",
          start: I18n.l('#date.formats.long', start)
          end:   I18n.l('#date.formats.long', end)
        )
      , 500

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
      colors = colorSlicer.getColors(@contextCodes.length)
      html = for contextCode, index in @contextCodes
        color = colors[index]
        ".group_#{contextCode}{
           color: #{color};
           border-color: #{color};
           background-color: #{color};
        }"

      $styleContainer.html "<style>#{html.join('')}</style>"

    dataFromDocumentHash: () =>
      data = {}
      try
        fragment = location.hash.substring(1)
        if fragment.indexOf('=') != -1
          data = deparam(location.hash.substring(1)) || {}
        else
          # legacy
          data = $.parseJSON($.decodeFromHex(location.hash.substring(1))) || {}
      catch e
        data = {}
      data
