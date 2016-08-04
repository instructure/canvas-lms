# TODO
#  * Make assignments (due date) events non-resizable. Having an end date on them doesn't
#    make sense.

# requires jQuery

define [
  'i18n!calendar'
  'jquery'
  'underscore'
  'timezone'
  'moment'
  'compiled/util/fcUtil'
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
  'compiled/contextColorer'
  'compiled/util/deparam'
  'str/htmlEscape'
  'compiled/calendar/CalendarEventFilter'

  'fullcalendar-with-lang-all'
  'jquery.instructure_misc_helpers'
  'jquery.instructure_misc_plugins'
  'vendor/jquery.ba-tinypubsub'
  'jqueryui/button'
], (I18n, $, _, tz, moment, fcUtil, userSettings, hsvToRgb, colorSlicer, calendarAppTemplate, EventDataSource, commonEventFactory, ShowEventDetailsDialog, EditEventDetailsDialog, Scheduler, CalendarNavigator, AgendaView, calendarDefaults, ContextColorer, deparam, htmlEscape, calendarEventFilter) ->

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

      # In theory this is no longer necessary, but it performs some function that
      # another file depends on or perhaps even this one. Whatever the dependency
      # is it is not clear, without more research, what effect this has on the
      # calendar system
      @schedulerNavigator = new CalendarNavigator(el: $('.scheduler_navigator'))
      @schedulerNavigator.hide()

      @agenda = new AgendaView(el: $('.agenda-wrapper'), dataSource: @dataSource, calendar: this)
      @scheduler = new Scheduler(".scheduler-wrapper", this)

      fullCalendarParams = @initializeFullCalendarParams()

      data = @dataFromDocumentHash()
      if not data.view_start and @options?.viewStart
        data.view_start = @options.viewStart
        @updateFragment data, replaceState: true

      fullCalendarParams.defaultDate = @getCurrentDate()

      @calendar = @el.find("div.calendar").fullCalendar fullCalendarParams

      if data.show && data.show != ''
        @visibleContextList = data.show.split(',')
        for visibleContext, i in @visibleContextList
          @visibleContextList[i] = visibleContext.replace(/^group_(.*_.*)/, '$1')

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
        "CommonEvent/eventSaveFailed" : @eventSaveFailed
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
      @header.on('navigateDate', @navigateDate)
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
      @schedulerNavigator.on('navigateDate', @navigateDate)

    connectAgendaEvents: ->
      @agenda.on('agendaDateRange', @renderDateRange)

    initializeFullCalendarParams: ->
      _.defaults(
        header: false
        editable: true
        buttonText:
          today: I18n.t 'today', 'Today'
        defaultTimedEventDuration: '01:00:00'
        slotDuration: '00:30:00'
        scrollTime: '07:00:00'
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
        viewRender: @viewRender
        windowResize: @windowResize
        drop: @drop

        dragRevertDuration: 0
        dragAppendTo: { month: '#calendar-drag-and-drop-container' }
        dragZIndex: { month: 350 }
        dragCursorAt: { month: {top: -5, left: -5} }

        , calendarDefaults)

    today: =>
      @gotoDate(fcUtil.now())

    # FullCalendar callbacks
    getEvents: (start, end, timezone, donecb, datacb) =>
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
            donecb(calendarEventFilter(@displayAppointmentEvents, events.concat(aEvents)))
        else
          if (datacb?)
            donecb([])
          else
            donecb(calendarEventFilter(@displayAppointmentEvents, events))
      , datacb && (events) =>
        datacb(calendarEventFilter(@displayAppointmentEvents, events))

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

      startDate = event.startDate()
      endDate = event.endDate()
      timeString = if !endDate || +startDate == +endDate
          startDate.locale(calendarDefaults.lang)
          startDate.format("LT")
        else
          startDate.locale(calendarDefaults.lang)
          endDate.locale(calendarDefaults.lang)
          $.fullCalendar.formatRange(startDate, endDate, "LT")

      screenReaderTitleHint = if event.eventType.match(/assignment/)
          I18n.t('event_assignment_title', 'Assignment Title:')
        else
          I18n.t('event_event_title', 'Event Title:')

      $element.attr('title', $.trim("#{timeString}\n#{$element.find('.fc-title').text()}\n\n#{I18n.t('calendar_title', 'Calendar:')} #{htmlEscape(event.contextInfo.name)}"))
      $element.find('.fc-content').prepend($("<span class='screenreader-only'>#{htmlEscape I18n.t('calendar_title', 'Calendar:')} #{htmlEscape(event.contextInfo.name)}</span>"))
      $element.find('.fc-title').prepend($("<span class='screenreader-only'>#{htmlEscape screenReaderTitleHint} </span>"))
      $element.find('.fc-title').toggleClass('calendar__event--completed', event.isCompleted())
      element.find('.fc-content').prepend($('<i />', {'class': "icon-#{event.iconType()}"}))
      true

    eventAfterRender: (event, element, view) =>
      @enableExternalDrags(element)
      if event.isDueAtMidnight()
        # show the actual time instead of the midnight fudged time
        time = element.find('.fc-time')
        html = time.html()
        # the time element also contains the title for calendar events
        html = html?.replace(/^\d+:\d+\w?/, event.startDate().format('h:mmt'))
        time.html(html)
        time.attr('data-start', event.startDate().format('h:mm'))
      if event.eventType.match(/assignment/) && view.name == "agendaWeek"
        element.height('') # this fixes it so it can wrap and not be forced onto 1 line
          .find('.ui-resizable-handle').remove()
      if event.eventType.match(/assignment/) && event.isDueAtMidnight() && view.name == "month"
        element.find('.fc-time').empty()
      if event.eventType == 'calendar_event' && @options?.activateEvent && event.id == "calendar_event_#{@options?.activateEvent}"
        @options.activateEvent = null
        @eventClick event,
          # fake up the jsEvent
          currentTarget: element
          pageX: element.offset().left + parseInt(element.width() / 2)
          view

    eventDragStart: (event, jsEvent, ui, view) =>
      $(".fc-highlight-skeleton").remove()
      @lastEventDragged = event
      @closeEventPopups()

    eventResizeStart: (event, jsEvent, ui, view) =>
      @closeEventPopups()

    # event triggered by items being dropped from within the calendar
    eventDrop: (event, delta, revertFunc, jsEvent, ui, view) =>
      minuteDelta = delta.asMinutes()
      @_eventDrop(event, minuteDelta, event.allDay, revertFunc)

    _eventDrop: (event, minuteDelta, allDay, revertFunc) ->
      if @currentView == 'week' && allDay && event.eventType == "assignment"
        revertFunc()
        return

      if event.midnightFudged
        event.start = fcUtil.clone(event.originalStart).add(minuteDelta, 'minutes')

      # isDueAtMidnight() will read cached midnightFudged property
      if event.eventType == "assignment" && event.isDueAtMidnight() && minuteDelta == 0
        event.start.minutes(59)

      # set event as an all day event if allDay
      if event.eventType == "calendar_event" && allDay
        event.allDay = true

      # if a short event gets dragged, we don't want to change its duration

      if event.endDate() && event.end
        originalDuration = event.endDate() - event.startDate()
        event.end = fcUtil.clone(event.start).add(originalDuration, 'milliseconds')

      event.saveDates(null, revertFunc)
      return true

    eventResize: ( event, delta, revertFunc, jsEvent, ui, view ) =>
      event.saveDates(null, revertFunc)

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

    dayClick: (date, jsEvent, view) =>
      if @displayAppointmentEvents
        # Don't allow new event creation while in scheduler mode
        return

      # create a new dummy event
      allowedContexts = userSettings.get('checked_calendar_codes') or _.pluck(@contexts, 'asset_string')
      activeContexts  = _.filter @contexts, (c) -> _.contains(allowedContexts, c.asset_string)
      event = commonEventFactory(null, activeContexts)
      event.date = date
      event.allDay = not date.hasTime()
      (new EditEventDetailsDialog(event)).show()

    updateFragment: (opts) ->
      replaceState = !!opts.replaceState
      opts = _.omit(opts, 'replaceState')

      data = @dataFromDocumentHash()
      changed = false
      for k, v of opts
        changed = true if data[k] != v
        if v
          data[k] = v
        else
          delete data[k]

      if changed
        fragment = "#" + $.param(data, @)
        if replaceState || location.hash == ""
          history.replaceState(null, "", fragment)
        else
          location.href = fragment

    viewRender: (view) =>
      @setDateTitle(view.title)
      @drawNowLine()

    enableExternalDrags: (eventEl) =>
      $(eventEl).draggable({
        zIndex: 999
        revert: true
        revertDuration: 0
        refreshPositions: true
        addClasses: false
        appendTo: "calendar-drag-and-drop-container"
        # clone doesn't seem to work :(
        helper: "clone"
      })

    isSameWeek: (date1, date2) ->
      week1 = fcUtil.clone(date1).weekday(0).stripTime()
      week2 = fcUtil.clone(date2).weekday(0).stripTime()
      +week1 == +week2

    drawNowLine: =>
      return unless @currentView == 'week'

      if !@$nowLine
        @$nowLine = $('<div />', {'class': 'calendar-nowline'})
      $('.fc-slats').append(@$nowLine)

      now = fcUtil.now()
      midnight = fcUtil.now()
      midnight.hours(0)
      midnight.seconds(0)
      seconds = moment.duration(now.diff(midnight)).asSeconds()
      @$nowLine.toggle(@isSameWeek(@getCurrentDate(), now))

      @$nowLine.css('width', $('.fc-body .fc-widget-content:first').css('width'))
      secondHeight = ($('.fc-time-grid')?.css('height')?.replace('px', '') || 0)/24/60/60
      @$nowLine.css('top', seconds*secondHeight + 'px')

    setDateTitle: (title) =>
      @header.setHeaderText(title)
      @schedulerNavigator.setTitle(title)

    # event triggered by items being dropped from outside the calendar
    drop: (date, jsEvent, ui) =>
      eventId    = $(ui.helper).data('event-id')
      event      = $("[data-event-id=#{eventId}]").data('calendarEvent')
      return unless event
      event.start = date
      event.addClass 'event_pending'
      revertFunc = -> console.log("could not save date on undated event")

      return unless @_eventDrop(event, 0, false, revertFunc)
      @calendar.fullCalendar('renderEvent', event)

    # callback from minicalendar telling us an event from here was dragged there
    dropOnMiniCalendar: (date, allDay, jsEvent, ui) ->
      event = @lastEventDragged
      return unless event
      originalStart = fcUtil.clone(event.start)
      originalEnd = fcUtil.clone(event.end)
      @copyYMD(event.start, date)
      @copyYMD(event.end, date)
      @_eventDrop(event, moment.duration(event.start.diff(originalStart)).asMinutes(), false, =>
        event.start = originalStart
        event.end = originalEnd
        @updateEvent(event)
      )

    copyYMD: (target, source) ->
      return unless target
      target.year(source.year())
      target.month(source.month())
      target.date(source.date())

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

    updateEvent: (event) =>
      # fullcalendar.js expects the argument to updateEvent to be an instance
      # of the event that it's manipulated into having _start and _end fields.
      # the event passed in here isn't necessarily one of those, but may be our
      # own management of the event instead. in lieu of figuring out how to get
      # the right copy of the event here, the one we have is good enough as
      # long as we put the expected fields in place
      event._start ?= fcUtil.clone(event.start)
      event._end ?= if event.end then fcUtil.clone(event.end) else null
      @calendar.fullCalendar('updateEvent', event)

    eventDeleting: (event) =>
      event.addClass 'event_pending'
      @updateEvent(event)

    eventDeleted: (event) =>
      @calendar.fullCalendar('removeEvents', event.id)

    eventSaving: (event) =>
      return unless event.start # undated events can't be rendered
      event.addClass 'event_pending'
      if event.isNewEvent()
        @calendar.fullCalendar('renderEvent', event)
      else
        @updateEvent(event)

    eventSaved: (event) =>
      event.removeClass 'event_pending'

      # If we just saved a new event then the id field has changed from what it
      # was in eventSaving. So we need to clear out the old _id that
      # fullcalendar stores for itself because the id has changed.
      # This is another reason to do a refetchEvents instead of just an update.
      delete event._id
      @calendar.fullCalendar('refetchEvents')
      @reloadClick() if event?.object?.duplicates?.length > 0
      # We'd like to just add the event to the calendar rather than fetching,
      # but the save may be as a result of moving an event from being undated
      # to dated, and in that case we don't know whether to just update it or
      # add it. Some new state would need to be kept to track that.
      @closeEventPopups()

    eventSaveFailed: (event) =>
      event.removeClass 'event_pending'
      if event.isNewEvent()
        @calendar.fullCalendar('removeEvents', event.id)
      else
        @updateEvent(event)

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

    # expects a fudged Moment object (use fcUtil
    # before calling if you must coerce)
    gotoDate: (date) =>
      @calendar.fullCalendar("gotoDate", date)
      @agendaViewFetch(date) if @currentView == 'agenda'
      @setCurrentDate(date)
      @drawNowLine()

    navigateDate: (d) =>
      date = fcUtil.wrap(d)
      @gotoDate(date)

    handleArrow: (type) ->
      @calendar.fullCalendar(type)
      calendarDate = @calendar.fullCalendar('getDate')
      now = fcUtil.now()
      if @currentView == 'month'
        if calendarDate.month() == now.month() && calendarDate.year() == now.year()
          start = now
        else
          start = fcUtil.clone(calendarDate)
          start.date(1)
      else
        if @isSameWeek(calendarDate, now)
          start = now
        else
          start = fcUtil.clone(calendarDate)
          start.date(start.date() - start.weekday())

      @setCurrentDate(start)
      @drawNowLine()

    # this expects a fudged moment object
    # use fcUtil to coerce if needed
    setCurrentDate: (date) ->
      @updateFragment
        view_start: date.format('YYYY-MM-DD')
        replaceState: true

      $.publish('Calendar/currentDate', date)

    getCurrentDate: () ->
      data = @dataFromDocumentHash()
      if data.view_start
        fcUtil.wrap(data.view_start)
      else
        fcUtil.now()

    setCurrentView: (view) ->
      @updateFragment
        view_name: view
        replaceState: !_.has(@dataFromDocumentHash(), 'view_name') # use replaceState if view_name wasn't set before

      @currentView = view
      userSettings.set('calendar_view', view) unless view is 'scheduler'

    getCurrentView: ->
      if @currentView
        @currentView
      else if (data = @dataFromDocumentHash()) && data.view_name
        data.view_name
      else if userSettings.get('calendar_view') and userSettings.get('calendar_view') isnt 'scheduler'
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

      if view != 'scheduler'
        @updateFragment appointment_group_id: null
        @scheduler.viewingGroup = null
        @agenda.viewingGroup = null

      if view != 'scheduler' and view != 'agenda'
        # rerender title so agenda title doesnt stay
        viewObj = @calendar.fullCalendar('getView')
        @viewRender(viewObj)

        @displayAppointmentEvents = null
        @scheduler.hide()
        @header.showAgendaRecommendation()
        @calendar.show()
        @schedulerNavigator.hide()
        @calendar.fullCalendar('refetchEvents')
        @calendar.fullCalendar('changeView', if view == 'week' then 'agendaWeek' else 'month')
        @calendar.fullCalendar('render')
      else if view == 'scheduler'
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

    hideAgendaView: ->
      @agenda.hide()

    formatDate: (date, format) ->
      tz.format(fcUtil.unwrap(date), format)

    agendaViewFetch: (start) ->
      @setDateTitle(@formatDate(start, 'date.formats.medium'))
      @agenda.fetch(@visibleContextList, start)

    renderDateRange: (start, end) =>
      @setDateTitle(@formatDate(start, 'date.formats.medium')+' – '+@formatDate(end, 'date.formats.medium'))
      # for "load more" with voiceover, we want the alert to happen later so
      # the focus change doesn't interrupt it.
      window.setTimeout =>
        $.screenReaderFlashMessage I18n.t('agenda_view_displaying_start_end', "Now displaying %{start} through %{end}",
          start: @formatDate(start, 'date.formats.long')
          end:   @formatDate(end, 'date.formats.long')
        )
      , 500

    showSchedulerSingle: (group) ->
      @agenda.viewingGroup = group
      @loadAgendaView()
      @header.showDoneButton()

    schedulerSingleDoneClick: =>
      @agenda.viewingGroup = null
      @scheduler.doneClick()
      @header.showSchedulerTitle()
      @schedulerNavigator.hide()

    # Private

    # we use a <div> (with a <style> inside it) because you cant set .innerHTML directly on a
    # <style> node in ie8
    $styleContainer = $('<div id="calendar_color_style_overrides" />').appendTo('body')

    colorizeContexts: =>
      # Get any custom colors that have been set
      $.getJSON(
          '/api/v1/users/' + @options.userId + '/colors/'
          (data) =>
            customColors = data.custom_colors
            colors = colorSlicer.getColors(@contextCodes.length, 275, {unsafe: !ENV.use_high_contrast})

            newCustomColors = {}
            html = (for contextCode, index in @contextCodes
              # Use a custom color if found.
              if customColors[contextCode]
                color = customColors[contextCode]
              else
                color = colors[index]
                newCustomColors[contextCode] = color

              color = htmlEscape(color)
              contextCode = htmlEscape(contextCode)
              ".group_#{contextCode},
               .group_#{contextCode}:hover,
               .group_#{contextCode}:focus{
                 color: #{color};
                 border-color: #{color};
                 background-color: #{color};
              }

              "
            ).join('')

            ContextColorer.persistContextColors(newCustomColors, @options.userId)

            $styleContainer.html "<style>#{html}</style>"
      )

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
