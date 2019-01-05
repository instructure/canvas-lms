/*
 * Copyright (C) 2012 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

// TODO
//  * Make assignments (due date) events non-resizable. Having an end date on them doesn't
//    make sense.

import I18n from 'i18n!calendar'
import $ from 'jquery'
import _ from 'underscore'
import tz from 'timezone'
import moment from 'moment'
import {showFlashAlert} from 'jsx/shared/FlashAlert'
import withinMomentDates from 'jsx/shared/helpers/momentDateHelper'
import fcUtil from '../util/fcUtil'
import userSettings from '../userSettings'
import colorSlicer from 'color-slicer'
import calendarAppTemplate from 'jst/calendar/calendarApp'
import commonEventFactory from '../calendar/commonEventFactory'
import ShowEventDetailsDialog from '../calendar/ShowEventDetailsDialog'
import EditEventDetailsDialog from '../calendar/EditEventDetailsDialog'
import Scheduler from '../calendar/Scheduler'
import CalendarNavigator from '../views/calendar/CalendarNavigator'
import AgendaView from '../views/calendar/AgendaView'
import calendarDefaults from '../calendar/CalendarDefaults'
import ContextColorer from '../contextColorer'
import deparam from '../util/deparam'
import htmlEscape from 'str/htmlEscape'
import calendarEventFilter from '../calendar/CalendarEventFilter'
import schedulerActions from 'jsx/calendar/scheduler/actions'
import 'fullcalendar'
import 'fullcalendar/dist/lang-all'
import 'jsx/calendar/patches-to-fullcalendar'
import 'jquery.instructure_misc_helpers'
import 'jquery.instructure_misc_plugins'
import 'vendor/jquery.ba-tinypubsub'
import 'jqueryui/button'

// we use a <div> (with a <style> inside it) because you cant set .innerHTML directly on a
// <style> node in ie8
const $styleContainer = $('<div id="calendar_color_style_overrides" />').appendTo('body')

export default class Calendar {
  constructor(selector, contexts, manageContexts, dataSource, options) {
    this.today = this.today.bind(this)
    this.getEvents = this.getEvents.bind(this)
    this.windowResize = this.windowResize.bind(this)
    this.eventRender = this.eventRender.bind(this)
    this.eventAfterRender = this.eventAfterRender.bind(this)
    this.eventDragStart = this.eventDragStart.bind(this)
    this.eventResizeStart = this.eventResizeStart.bind(this)
    this.eventDrop = this.eventDrop.bind(this)
    this.eventResize = this.eventResize.bind(this)
    this.addEventClick = this.addEventClick.bind(this)
    this.eventClick = this.eventClick.bind(this)
    this.dayClick = this.dayClick.bind(this)
    this.viewRender = this.viewRender.bind(this)
    this.enableExternalDrags = this.enableExternalDrags.bind(this)
    this.drawNowLine = this.drawNowLine.bind(this)
    this.setDateTitle = this.setDateTitle.bind(this)
    this.drop = this.drop.bind(this)
    this.fragmentChange = this.fragmentChange.bind(this)
    this.reloadClick = this.reloadClick.bind(this)
    this.updateEvent = this.updateEvent.bind(this)
    this.eventDeleting = this.eventDeleting.bind(this)
    this.eventDeleted = this.eventDeleted.bind(this)
    this.handleUnreserve = this.handleUnreserve.bind(this)
    this.eventSaving = this.eventSaving.bind(this)
    this.eventSaved = this.eventSaved.bind(this)
    this.eventSaveFailed = this.eventSaveFailed.bind(this)
    this.updateOverrides = this.updateOverrides.bind(this)
    this.visibleContextListChanged = this.visibleContextListChanged.bind(this)
    this.ajaxStarted = this.ajaxStarted.bind(this)
    this.ajaxEnded = this.ajaxEnded.bind(this)
    this.refetchEvents = this.refetchEvents.bind(this)
    this.gotoDate = this.gotoDate.bind(this)
    this.navigateDate = this.navigateDate.bind(this)
    this.loadView = this.loadView.bind(this)
    this.renderDateRange = this.renderDateRange.bind(this)
    this.schedulerSingleDoneClick = this.schedulerSingleDoneClick.bind(this)
    this.colorizeContexts = this.colorizeContexts.bind(this)
    this.dataFromDocumentHash = this.dataFromDocumentHash.bind(this)
    this.onSchedulerStateChange = this.onSchedulerStateChange.bind(this)
    this.findAppointmentModeGroups = this.findAppointmentModeGroups.bind(this)
    this.visibleDateRange = this.visibleDateRange.bind(this)
    this.findNextAppointment = this.findNextAppointment.bind(this)

    this.contexts = contexts
    this.manageContexts = manageContexts
    this.dataSource = dataSource
    this.options = options
    this.contextCodes = (this.contexts || []).map(context => context.asset_string)
    this.visibleContextList = []
    // Display appointment slots for the specified appointment group
    this.displayAppointmentEvents = null
    this.activateEvent = this.options && this.options.activateEvent

    this.activeAjax = 0

    this.subscribeToEvents()
    this.header = this.options.header
    this.schedulerState = {}
    this.useBetterScheduler = !!this.options.schedulerStore
    if (this.options.schedulerStore) {
      this.schedulerStore = this.options.schedulerStore
      this.schedulerState = this.schedulerStore.getState()
      this.schedulerStore.subscribe(this.onSchedulerStateChange)
    }

    this.el = $(selector).html(calendarAppTemplate())

    // In theory this is no longer necessary, but it performs some function that
    // another file depends on or perhaps even this one. Whatever the dependency
    // is it is not clear, without more research, what effect this has on the
    // calendar system
    this.schedulerNavigator = new CalendarNavigator({el: $('.scheduler_navigator')})
    this.schedulerNavigator.hide()

    this.agenda = new AgendaView({
      el: $('.agenda-wrapper'),
      dataSource: this.dataSource,
      calendar: this
    })
    this.scheduler = new Scheduler('.scheduler-wrapper', this)

    const fullCalendarParams = this.initializeFullCalendarParams()

    const data = this.dataFromDocumentHash()
    if (!data.view_start && this.options && this.options.viewStart) {
      data.view_start = this.options.viewStart
      this.updateFragment(data, {replaceState: true})
    }

    fullCalendarParams.defaultDate = this.getCurrentDate()

    this.calendar = this.el.find('div.calendar').fullCalendar(fullCalendarParams)

    if (data.show && data.show !== '') {
      this.visibleContextList = data.show.split(',')
      for (let i = 0; i < this.visibleContextList.length; i++) {
        const visibleContext = this.visibleContextList[i]
        this.visibleContextList[i] = visibleContext.replace(/^group_(.*_.*)/, '$1')
      }
    }

    $(document).fragmentChange(this.fragmentChange)

    this.colorizeContexts()

    this.reservable_appointment_groups = {}
    this.hasAppointmentGroups = $.Deferred()
    if (this.options.showScheduler) {
      // Pre-load the appointment group list, for the badge
      this.dataSource.getAppointmentGroups(false, data => {
        let required = 0
        data.forEach(group => {
          if (group.requiring_action) {
            required += 1
          }
          group.context_codes.forEach(context_code => {
            if (!this.reservable_appointment_groups[context_code]) {
              this.reservable_appointment_groups[context_code] = []
            }
            this.reservable_appointment_groups[context_code].push(`appointment_group_${group.id}`)
          })
        })
        this.header.setSchedulerBadgeCount(required)
        if (this.options.onLoadAppointmentGroups) {
          this.options.onLoadAppointmentGroups(this.reservable_appointment_groups)
        }
        return this.hasAppointmentGroups.resolve()
      })
    } else {
      this.hasAppointmentGroups.resolve()
    }

    this.connectHeaderEvents()
    this.connectSchedulerNavigatorEvents()
    this.connectAgendaEvents()
    $('#flash_message_holder').on('click', '.gotoDate_link', event =>
      this.gotoDate(fcUtil.wrap($(event.target).data('date')))
    )

    this.header.selectView(this.getCurrentView())

    if (data.view_name === 'scheduler' && data.appointment_group_id) {
      this.scheduler.viewCalendarForGroupId(data.appointment_group_id)
    }

    // enter find-appointment mode via sign-up-for-things notification URL
    if (data.find_appointment && this.schedulerStore) {
      const course = ENV.CALENDAR.CONTEXTS.filter(
        context => context.asset_string === data.find_appointment
      )
      if (course.length) {
        this.schedulerStore.dispatch(schedulerActions.actions.setCourse(course[0]))
        this.schedulerStore.dispatch(schedulerActions.actions.setFindAppointmentMode(true))
      }
    }

    window.setInterval(this.drawNowLine, 1000 * 60)
  }

  subscribeToEvents() {
    $.subscribe({
      'CommonEvent/eventDeleting': this.eventDeleting,
      'CommonEvent/eventDeleted': this.eventDeleted,
      'CommonEvent/eventSaving': this.eventSaving,
      'CommonEvent/eventSaved': this.eventSaved,
      'CommonEvent/eventSaveFailed': this.eventSaveFailed,
      'Calendar/visibleContextListChanged': this.visibleContextListChanged,
      'EventDataSource/ajaxStarted': this.ajaxStarted,
      'EventDataSource/ajaxEnded': this.ajaxEnded,
      'Calendar/refetchEvents': this.refetchEvents,
      'CommonEvent/assignmentSaved': this.updateOverrides,
      'Calendar/colorizeContexts': this.colorizeContexts
    })
  }

  connectHeaderEvents() {
    this.header.on('navigatePrev', () => this.handleArrow('prev'))
    this.header.on('navigateToday', this.today)
    this.header.on('navigateNext', () => this.handleArrow('next'))
    this.header.on('navigateDate', this.navigateDate)
    this.header.on('week', () => this.loadView('week'))
    this.header.on('month', () => this.loadView('month'))
    this.header.on('agenda', () => this.loadView('agenda'))
    this.header.on('scheduler', () => this.loadView('scheduler'))
    this.header.on('createNewEvent', this.addEventClick)
    this.header.on('refreshCalendar', this.reloadClick)
    this.header.on('done', this.schedulerSingleDoneClick)
  }

  connectSchedulerNavigatorEvents() {
    this.schedulerNavigator.on('navigatePrev', () => this.handleArrow('prev'))
    this.schedulerNavigator.on('navigateToday', this.today)
    this.schedulerNavigator.on('navigateNext', () => this.handleArrow('next'))
    this.schedulerNavigator.on('navigateDate', this.navigateDate)
  }

  connectAgendaEvents() {
    this.agenda.on('agendaDateRange', this.renderDateRange)
  }

  initializeFullCalendarParams() {
    return _.defaults(
      {
        header: false,
        editable: true,
        buttonText: {
          today: I18n.t('today', 'Today')
        },
        defaultTimedEventDuration: '01:00:00',
        slotDuration: '00:30:00',
        scrollTime: '07:00:00',
        droppable: true,
        dropAccept: '.undated_event',
        events: this.getEvents,
        eventRender: this.eventRender,
        eventAfterRender: this.eventAfterRender,
        eventDragStart: this.eventDragStart,
        eventDrop: this.eventDrop,
        eventClick: this.eventClick,
        eventTimeFormat: this.eventTimeFormat(),
        eventResize: this.eventResize,
        eventResizeStart: this.eventResizeStart,
        dayClick: this.dayClick,
        addEventClick: this.addEventClick,
        viewRender: this.viewRender,
        windowResize: this.windowResize,
        drop: this.drop,

        dragRevertDuration: 0,
        dragAppendTo: {month: '#calendar-drag-and-drop-container'},
        dragZIndex: {month: 350},
        dragCursorAt: {month: {top: -5, left: -5}}
      },

      calendarDefaults
    )
  }

  // This is used to set a custom time format for regions who use 24 hours time.
  // We return null in the non 24 time case so that we can allow the fullcallendar npm package
  // to set whatever time format calendar events should be
  eventTimeFormat () {
    return I18n.lookup('time.formats.tiny_on_the_hour') === "%k:%M" ? "HH:mm" : null
  }

  today() {
    return this.gotoDate(fcUtil.now())
  }

  // FullCalendar callbacks
  getEvents(start, end, timezone, donecb, datacb) {
    this.gettingEvents = true
    const contexts = this.visibleContextList.concat(this.findAppointmentModeGroups())

    const _donecb = events => {
      if (this.displayAppointmentEvents) {
        return this.dataSource.getEventsForAppointmentGroup(this.displayAppointmentEvents, aEvents => {
          // Make sure any events in the current appointment group get marked -
          // order is important here, as some events in aEvents may also appear in
          // events. So clear events first, then mark aEvents. Our de-duping algorithm
          // will keep the duplicates at the end of the list first.
          events.forEach(event => event.removeClass('current-appointment-group'))
          aEvents.forEach(event => event.addClass('current-appointment-group'))
          this.gettingEvents = false
          donecb(calendarEventFilter(this.displayAppointmentEvents, events.concat(aEvents), this.schedulerState))
        })
      } else {
        this.gettingEvents = false
        if (datacb) {
          donecb([])
        } else {
          donecb(calendarEventFilter(this.displayAppointmentEvents, events, this.schedulerState))
        }
      }
    }

    let _datacb
    if (datacb) _datacb = events => datacb(calendarEventFilter(this.displayAppointmentEvents, events, this.schedulerState))

    return this.dataSource.getEvents(start, end, contexts, _donecb, _datacb)
  }


  // Close all event details popup on the page and have them cleaned up.
  closeEventPopups() {
    // Close any open popup as it gets detached when rendered
    $('.event-details').each(function() {
      const existingDialog = $(this).data('showEventDetailsDialog')
      if (existingDialog) {
        existingDialog.close()
      }
    })
  }

  windowResize(view) {
    this.closeEventPopups()
    this.drawNowLine()
  }

  eventRender(event, element, view) {
    const $element = $(element)

    const startDate = event.startDate()
    const endDate = event.endDate()
    const timeString = (() => {
      if (!endDate || +startDate === +endDate) {
        startDate.locale(calendarDefaults.lang)
        return startDate.format('LT')
      } else {
        startDate.locale(calendarDefaults.lang)
        endDate.locale(calendarDefaults.lang)
        return $.fullCalendar.formatRange(startDate, endDate, 'LT')
      }
    })()

    const screenReaderTitleHint = event.eventType.match(/assignment/)
      ? I18n.t('Assignment Title:')
      : event.eventType === 'planner_note' ? I18n.t('To Do:') : I18n.t('Event Title:')

    let reservedText = ''
    if (event.isAppointmentGroupEvent()) {
      if (event.appointmentGroupEventStatus === 'Reserved') {
        reservedText = `\n\n${I18n.t('Reserved By You')}`
      } else if (event.reservedUsers === '') {
        reservedText = `\n\n${I18n.t('Unreserved')}`
      } else {
        reservedText = `\n\n${I18n.t('Reserved By: ')} ${event.reservedUsers}`
      }
    }

    $element.attr(
      'title',
      $.trim(
        `${timeString}\n${$element.find('.fc-title').text()}\n\n${I18n.t('Calendar:')} ${htmlEscape(
          event.contextInfo.name
        )} ${htmlEscape(reservedText)}`
      )
    )
    $element
      .find('.fc-content')
      .prepend(
        $(
          `<span class='screenreader-only'>${
            htmlEscape(I18n.t('calendar_title', 'Calendar:'))
          } ${
            htmlEscape(event.contextInfo.name)
          }</span>`
        )
      )
    $element
      .find('.fc-title')
      .prepend($(`<span class='screenreader-only'>${htmlEscape(screenReaderTitleHint)} </span>`))
    $element.find('.fc-title').toggleClass('calendar__event--completed', event.isCompleted())
    element.find('.fc-content').prepend($('<i />', {class: `icon-${event.iconType()}`}))
    return true
  }

  eventAfterRender(event, element, view) {
    this.enableExternalDrags(element)
    if (event.isDueAtMidnight()) {
      // show the actual time instead of the midnight fudged time
      const time = element.find('.fc-time')
      let html = time.html()
      // the time element also contains the title for calendar events
      html = html && html.replace(/^\d+:\d+\w?/, event.startDate().format('h:mmt'))
      time.html(html)
      time.attr('data-start', event.startDate().format('h:mm'))
    }
    if (event.eventType.match(/assignment/) && view.name === 'agendaWeek') {
      element
        .height('') // this fixes it so it can wrap and not be forced onto 1 line
        .find('.ui-resizable-handle')
        .remove()
    }
    if (event.eventType.match(/assignment/) && event.isDueStrictlyAtMidnight() && view.name === 'month') {
      element.find('.fc-time').empty()
    }
    if (
      event.eventType === 'calendar_event' &&
      this.options &&
      this.options.activateEvent &&
      !this.gettingEvents &&
      event.id === `calendar_event_${this.options && this.options.activateEvent}`
    ) {
      this.options.activateEvent = null
      return this.eventClick(
        event,
        {
          // fake up the jsEvent
          currentTarget: element,
          pageX: element.offset().left + parseInt(element.width() / 2)
        },
        view
      )
    }
  }

  eventDragStart(event, jsEvent, ui, view) {
    $('.fc-highlight-skeleton').remove()
    this.lastEventDragged = event
    this.closeEventPopups()
  }

  eventResizeStart(event, jsEvent, ui, view) {
    this.closeEventPopups()
  }

  // event triggered by items being dropped from within the calendar
  eventDrop(event, delta, revertFunc, jsEvent, ui, view) {
    const minuteDelta = delta.asMinutes()
    return this._eventDrop(event, minuteDelta, event.allDay, revertFunc)
  }

  _eventDrop(event, minuteDelta, allDay, revertFunc) {
    let endDate, startDate
    if (this.currentView === 'week' && allDay && event.eventType === 'assignment') {
      revertFunc()
      return
    }

    if (
      event.eventType === 'assignment' &&
      event.assignment.unlock_at &&
      event.assignment.lock_at
    ) {
      startDate = moment(event.assignment.unlock_at)
      endDate = moment(event.assignment.lock_at)
      if (!withinMomentDates(event.start, startDate, endDate)) {
        revertFunc()
        showFlashAlert({
          message: I18n.t(
            'Assignment has a locked date. Due date cannot be set outside of locked date range.'
          ),
          err: null,
          type: 'error'
        })
        return
      }
    }

    if (event.midnightFudged) {
      event.start = fcUtil.addMinuteDelta(event.originalStart, minuteDelta)
    }

    // isDueAtMidnight() will read cached midnightFudged property
    if (event.eventType === 'assignment' && event.isDueAtMidnight() && minuteDelta === 0) {
      event.start.minutes(59)
    }

    // set event as an all day event if allDay
    if (event.eventType === 'calendar_event' && allDay) {
      event.allDay = true
    }

    // if a short event gets dragged, we don't want to change its duration

    if (event.endDate() && event.end) {
      const originalDuration = event.endDate() - event.startDate()
      event.end = fcUtil.clone(event.start).add(originalDuration, 'milliseconds')
    }

    event.saveDates(null, revertFunc)
    return true
  }

  eventResize(event, delta, revertFunc, jsEvent, ui, view) {
    return event.saveDates(null, revertFunc)
  }

  activeContexts() {
    const allowedContexts =
      userSettings.get('checked_calendar_codes') || _.pluck(this.contexts, 'asset_string')
    return _.filter(this.contexts, c => _.contains(allowedContexts, c.asset_string))
  }

  addEventClick(event, jsEvent, view) {
    if (this.displayAppointmentEvents) {
      // Don't allow new event creation while in scheduler mode
      return
    }

    // create a new dummy event
    event = commonEventFactory(null, this.activeContexts())
    event.date = this.getCurrentDate()
    return new EditEventDetailsDialog(event, this.useBetterScheduler).show()
  }

  eventClick(event, jsEvent, view) {
    const $event = $(jsEvent.currentTarget)
    if (!$event.hasClass('event_pending')) {
      if (event.can_change_context) {
        event.allPossibleContexts = this.activeContexts()
      }
      const detailsDialog = new ShowEventDetailsDialog(event, this.dataSource)
      $event.data('showEventDetailsDialog', detailsDialog)
      return detailsDialog.show(jsEvent)
    }
  }

  dayClick(date, jsEvent, view) {
    if (this.displayAppointmentEvents) {
      // Don't allow new event creation while in scheduler mode
      return
    }

    // create a new dummy event
    const event = commonEventFactory(null, this.activeContexts())
    event.date = date
    event.allDay = !date.hasTime()
    return new EditEventDetailsDialog(event, this.useBetterScheduler).show()
  }

  updateFragment(opts) {
    const replaceState = !!opts.replaceState
    opts = _.omit(opts, 'replaceState')
    const data = this.dataFromDocumentHash()
    let changed = false
    for (let k in opts) {
      let v = opts[k]
      if (data[k] !== v) changed = true
      if (v) {
        data[k] = v
      } else {
        delete data[k]
      }
    }
    if (changed) {
      const fragment = "#" + $.param(data, this)
      if (replaceState || location.hash === "") {
        return history.replaceState(null, "", fragment)
      } else {
        return location.href = fragment
      }
    }
  }

  viewRender(view) {
    this.setDateTitle(view.title)
    this.drawNowLine()
  }

  enableExternalDrags(eventEl) {
    return $(eventEl).draggable({
      zIndex: 999,
      revert: true,
      revertDuration: 0,
      refreshPositions: true,
      addClasses: false,
      appendTo: 'calendar-drag-and-drop-container',
      // clone doesn't seem to work :(
      helper: 'clone'
    })
  }

  isSameWeek(date1, date2) {
    const week1 = fcUtil
      .clone(date1)
      .weekday(0)
      .stripTime()
    const week2 = fcUtil
      .clone(date2)
      .weekday(0)
      .stripTime()
    return +week1 === +week2
  }

  drawNowLine() {
    if (this.currentView !== 'week') {
      return
    }

    if (!this.$nowLine) {
      this.$nowLine = $('<div />', {class: 'calendar-nowline'})
    }
    $('.fc-slats').append(this.$nowLine)

    const now = fcUtil.now()
    const midnight = fcUtil.now()
    midnight.hours(0)
    midnight.seconds(0)
    const seconds = moment.duration(now.diff(midnight)).asSeconds()
    this.$nowLine.toggle(this.isSameWeek(this.getCurrentDate(), now))

    this.$nowLine.css('width', $('.fc-body .fc-widget-content:first').css('width'))
    const secondHeight =
      (($('.fc-time-grid').css('height') || '').replace('px', '') || 0) / 24 / 60 / 60
    this.$nowLine.css('top', `${seconds * secondHeight}px`)
  }

  setDateTitle(title) {
    this.header.setHeaderText(title)
    return this.schedulerNavigator.setTitle(title)
  }

  // event triggered by items being dropped from outside the calendar
  drop(date, jsEvent, ui) {
    const eventId = $(ui.helper).data('event-id')
    const event = $(`[data-event-id=${eventId}]`).data('calendarEvent')
    if (!event) {
      return
    }
    event.start = date
    event.addClass('event_pending')
    const revertFunc = () => console.log('could not save date on undated event')

    if (!this._eventDrop(event, 0, false, revertFunc)) {
      return
    }
    return this.calendar.fullCalendar('renderEvent', event)
  }

  // callback from minicalendar telling us an event from here was dragged there
  dropOnMiniCalendar(date, allDay, jsEvent, ui) {
    const event = this.lastEventDragged
    if (!event) {
      return
    }
    const originalStart = fcUtil.clone(event.start)
    const originalEnd = fcUtil.clone(event.end)
    this.copyYMD(event.start, date)
    this.copyYMD(event.end, date)
    // avoid DST shifts by coercing the minute delta to a whole number of days (it always is for minical drop events)
    return this._eventDrop(
      event,
      Math.round(moment.duration(event.start.diff(originalStart)).asDays()) * 60 * 24,
      false,
      () => {
        event.start = originalStart
        event.end = originalEnd
        return this.updateEvent(event)
      }
    )
  }

  copyYMD(target, source) {
    if (!target) {
      return
    }
    target.year(source.year())
    target.month(source.month())
    return target.date(source.date())
  }

  // DOM callbacks

  fragmentChange(event, hash) {
    const data = this.dataFromDocumentHash()
    if ($.isEmptyObject(data)) {
      return
    }

    if (data.view_name !== this.currentView) {
      this.loadView(data.view_name)
    }

    return this.gotoDate(this.getCurrentDate())
  }

  reloadClick(event) {
    if (event != null) {
      event.preventDefault()
    }
    if (this.activeAjax === 0) {
      this.dataSource.clearCache()
      if (this.currentView === 'scheduler') {
        this.scheduler.loadData()
      }
      return this.calendar.fullCalendar('refetchEvents')
    }
  }

  // Subscriptions

  updateEvent(event) {
    // fullcalendar.js expects the argument to updateEvent to be an instance
    // of the event that it's manipulated into having _start and _end fields.
    // the event passed in here isn't necessarily one of those, but may be our
    // own management of the event instead. in lieu of figuring out how to get
    // the right copy of the event here, the one we have is good enough as
    // long as we put the expected fields in place
    if (event._start == null) {
      event._start = fcUtil.clone(event.start)
    }
    if (event._end == null) {
      event._end = event.end ? fcUtil.clone(event.end) : null
    }
    return this.calendar.fullCalendar('updateEvent', event)
  }

  eventDeleting(event) {
    event.addClass('event_pending')
    return this.updateEvent(event)
  }

  eventDeleted(event) {
    if (event.isAppointmentGroupEvent() && event.calendarEvent.parent_event_id) {
      this.handleUnreserve(event)
    }
    return this.calendar.fullCalendar('removeEvents', event.id)
  }

  // when an appointment event was deleted, clear the reserved flag and increment the available slot count on the parent
  handleUnreserve(event) {
    const parentEvent = this.dataSource.eventWithId(
      `calendar_event_${event.calendarEvent.parent_event_id}`
    )
    if (parentEvent) {
      parentEvent.calendarEvent.reserved = false
      parentEvent.calendarEvent.available_slots += 1
      // remove the unreserved event from the parent's children.
      parentEvent.calendarEvent.child_events = parentEvent.calendarEvent.child_events.filter(
        obj => obj.id !== event.calendarEvent.id
      )
      // need to update the appointmentGroupEventStatus to make sure it
      // correctly displays the new status in the calendar.
      parentEvent.appointmentGroupEventStatus = parentEvent.calculateAppointmentGroupEventStatus()
      this.dataSource.removeCachedReservation(event.calendarEvent)

      return this.refetchEvents()
    }
  }

  eventSaving(event) {
    if (!event.start) {
      return
    } // undated events can't be rendered
    event.addClass('event_pending')
    if (event.isNewEvent()) {
      return this.calendar.fullCalendar('renderEvent', event)
    } else {
      return this.updateEvent(event)
    }
  }

  eventSaved(event) {
    event.removeClass('event_pending')

    // If we just saved a new event then the id field has changed from what it
    // was in eventSaving. So we need to clear out the old _id that
    // fullcalendar stores for itself because the id has changed.
    // This is another reason to do a refetchEvents instead of just an update.
    delete event._id
    this.calendar.fullCalendar('refetchEvents')
    if (event && event.object && event.object.duplicates && event.object.duplicates.length > 0)
      this.reloadClick()
    // We'd like to just add the event to the calendar rather than fetching,
    // but the save may be as a result of moving an event from being undated
    // to dated, and in that case we don't know whether to just update it or
    // add it. Some new state would need to be kept to track that.
    this.closeEventPopups()
  }

  eventSaveFailed(event) {
    event.removeClass('event_pending')
    if (event.isNewEvent()) {
      return this.calendar.fullCalendar('removeEvents', event.id)
    } else {
      return this.updateEvent(event)
    }
  }

  // When an assignment event is updated, update its related overrides.
  updateOverrides(event) {
    _.each(this.dataSource.cache.contexts[event.contextCode()].events, (override, key) => {
      if (key.match(/override/) && event.assignment.id === override.assignment.id) {
        override.updateAssignmentTitle(event.title)
      }
    })
  }

  visibleContextListChanged(newList) {
    this.visibleContextList = newList
    if (this.currentView === 'agenda') {
      this.loadAgendaView()
    }
    return this.calendar.fullCalendar('refetchEvents')
  }

  ajaxStarted() {
    this.activeAjax += 1
    return this.header.animateLoading(true)
  }

  ajaxEnded() {
    this.activeAjax -= 1
    return this.header.animateLoading(this.activeAjax > 0)
  }

  refetchEvents() {
    return this.calendar.fullCalendar('refetchEvents')
  }

  // Methods

  // expects a fudged Moment object (use fcUtil
  // before calling if you must coerce)
  gotoDate(date) {
    this.calendar.fullCalendar('gotoDate', date)
    if (this.currentView === 'agenda') {
      this.agendaViewFetch(date)
    }
    this.setCurrentDate(date)
    this.drawNowLine()
  }

  navigateDate(d) {
    const date = fcUtil.wrap(d)
    this.gotoDate(date)
  }

  handleArrow(type) {
    let start
    this.calendar.fullCalendar(type)
    const calendarDate = this.calendar.fullCalendar('getDate')
    const now = fcUtil.now()
    if (this.currentView === 'month') {
      if (calendarDate.month() === now.month() && calendarDate.year() === now.year()) {
        start = now
      } else {
        start = fcUtil.clone(calendarDate)
        start.date(1)
      }
    } else if (this.isSameWeek(calendarDate, now)) {
      start = now
    } else {
      start = fcUtil.clone(calendarDate)
      start.date(start.date() - start.weekday())
    }

    this.setCurrentDate(start)
    this.drawNowLine()
  }

  // this expects a fudged moment object
  // use fcUtil to coerce if needed
  setCurrentDate(date) {
    this.updateFragment({
      view_start: date.format('YYYY-MM-DD'),
      replaceState: true
    })

    $.publish('Calendar/currentDate', date)
  }

  getCurrentDate() {
    const data = this.dataFromDocumentHash()
    if (data.view_start) {
      return fcUtil.wrap(data.view_start)
    } else {
      return fcUtil.now()
    }
  }

  setCurrentView(view) {
    this.updateFragment({
      view_name: view,
      replaceState: !_.has(this.dataFromDocumentHash(), 'view_name')
    }) // use replaceState if view_name wasn't set before

    this.currentView = view
    if (view !== 'scheduler') {
      return userSettings.set('calendar_view', view)
    }
  }

  getCurrentView() {
    let data
    if (this.currentView) {
      return this.currentView
    } else if ((data = this.dataFromDocumentHash()) && data.view_name) {
      return data.view_name
    } else if (
      userSettings.get('calendar_view') &&
      userSettings.get('calendar_view') !== 'scheduler'
    ) {
      return userSettings.get('calendar_view')
    } else {
      return 'month'
    }
  }

  loadView(view) {
    if (view === this.currentView) {
      return
    }
    this.setCurrentView(view)

    $('.agenda-wrapper').removeClass('active')
    this.header.showNavigator()
    this.header.showPrevNext()
    this.header.hideAgendaRecommendation()

    if (view !== 'scheduler') {
      this.updateFragment({appointment_group_id: null})
      this.scheduler.viewingGroup = null
      this.agenda.viewingGroup = null
    }

    if (view !== 'scheduler' && view !== 'agenda') {
      // rerender title so agenda title doesnt stay
      const viewObj = this.calendar.fullCalendar('getView')
      this.viewRender(viewObj)

      this.displayAppointmentEvents = null
      this.scheduler.hide()
      this.header.showAgendaRecommendation()
      this.calendar.show()
      this.schedulerNavigator.hide()
      this.calendar.fullCalendar('refetchEvents')
      this.calendar.fullCalendar('changeView', view === 'week' ? 'agendaWeek' : 'month')
      return this.calendar.fullCalendar('render')
    } else if (view === 'scheduler') {
      this.calendar.hide()
      this.header.showSchedulerTitle()
      this.schedulerNavigator.hide()
      return this.scheduler.show()
    } else {
      this.calendar.hide()
      this.scheduler.hide()
      return this.header.hidePrevNext()
    }
  }

  loadAgendaView() {
    const date = this.getCurrentDate()
    this.agendaViewFetch(date)
  }

  hideAgendaView() {
    return this.agenda.hide()
  }

  formatDate(date, format) {
    return tz.format(fcUtil.unwrap(date), format)
  }

  agendaViewFetch(start) {
    this.setDateTitle(this.formatDate(start, 'date.formats.medium'))
    return $.when(this.hasAppointmentGroups).then(() =>
      this.agenda.fetch(this.visibleContextList.concat(this.findAppointmentModeGroups()), start)
    )
  }

  renderDateRange(start, end) {
    this.agendaStart = fcUtil.unwrap(start)
    this.agendaEnd = fcUtil.unwrap(end)
    this.setDateTitle(
      `${this.formatDate(start, 'date.formats.medium')} – ${this.formatDate(
        end,
        'date.formats.medium'
      )}`
    )
    // for "load more" with voiceover, we want the alert to happen later so
    // the focus change doesn't interrupt it.
    window.setTimeout(() => {
      $.screenReaderFlashMessage(
        I18n.t('agenda_view_displaying_start_end', 'Now displaying %{start} through %{end}', {
          start: this.formatDate(start, 'date.formats.long'),
          end: this.formatDate(end, 'date.formats.long')
        })
      )
    }, 500)
  }

  showSchedulerSingle(group) {
    this.agenda.viewingGroup = group
    this.loadAgendaView()
    return this.header.showDoneButton()
  }

  schedulerSingleDoneClick() {
    this.agenda.viewingGroup = null
    this.scheduler.doneClick()
    this.header.showSchedulerTitle()
    return this.schedulerNavigator.hide()
  }

  colorizeContexts() {
    // Get any custom colors that have been set
    $.getJSON(`/api/v1/users/${this.options.userId}/colors/`, data => {
      const customColors = data.custom_colors
      const colors = colorSlicer.getColors(this.contextCodes.length, 275, {
        unsafe: !ENV.use_high_contrast
      })

      const newCustomColors = {}
      const html = this.contextCodes
        .map((contextCode, index) => {
          // Use a custom color if found.
          let color
          if (customColors[contextCode]) {
            color = customColors[contextCode]
          } else {
            color = colors[index]
            newCustomColors[contextCode] = color
          }

          color = htmlEscape(color)
          contextCode = htmlEscape(contextCode)
          return `
            .group_${contextCode},
            .group_${contextCode}:hover,
            .group_${contextCode}:focus{
              color: ${color};
              border-color: ${color};
              background-color: ${color};
            }
          `
        })
        .join('')

      ContextColorer.persistContextColors(newCustomColors, this.options.userId)

      $styleContainer.html(`<style>${html}</style>`)
    })
  }

  dataFromDocumentHash() {
    let data = {}
    try {
      const fragment = location.hash.substring(1)
      if (fragment.indexOf('=') !== -1) {
        data = deparam(location.hash.substring(1)) || {}
      } else {
        // legacy
        data = $.parseJSON($.decodeFromHex(location.hash.substring(1))) || {}
      }
    } catch (e) {
      data = {}
    }
    return data
  }

  onSchedulerStateChange() {
    const newState = this.schedulerStore.getState()
    const changed = this.schedulerState.inFindAppointmentMode !== newState.inFindAppointmentMode
    this.schedulerState = newState
    if (changed) {
      this.refetchEvents()
      if (this.schedulerState.inFindAppointmentMode) {
        this.findNextAppointment()
        this.ensureCourseVisible(this.schedulerState.selectedCourse)
      }
      if (this.currentView === 'agenda') {
        return this.loadAgendaView()
      }
    }
  }

  findAppointmentModeGroups() {
    if (this.schedulerState.inFindAppointmentMode && this.schedulerState.selectedCourse) {
      return (
        this.reservable_appointment_groups[this.schedulerState.selectedCourse.asset_string] || []
      )
    } else {
      return []
    }
  }

  ensureCourseVisible(course) {
    $.publish('Calendar/ensureCourseVisible', course.asset_string)
  }

  visibleDateRange() {
    const range = {}
    if (this.currentView === 'agenda') {
      range.start = this.agendaStart
      range.end = this.agendaEnd
    } else {
      const view = this.calendar.fullCalendar('getView')
      range.start = fcUtil.unwrap(view.intervalStart)
      range.end = fcUtil.unwrap(view.intervalEnd)
    }
    return range
  }

  findNextAppointment() {
    // determine whether any reservable appointment slots are visible
    const range = this.visibleDateRange()
    // FIXME attempted optimization, except these events aren't in the cache yet;
    // if we want to do this, it needs to happen after @refetchEvents completes (asynchronously)
    // which may actually make the UI less responsive
    // courseEvents = @dataSource.getEventsFromCacheForContext range.start, range.end, @schedulerState.selectedCourse.asset_string
    // return if _.any courseEvents, (event) ->
    //    event.isAppointmentGroupEvent() && event.calendarEvent.reserve_url &&
    //    !event.calendarEvent.reserved && event.calendarEvent.available_slots > 0

    // find the next reservable appointment and report its date
    const group_ids = _.map(this.findAppointmentModeGroups(), asset_string =>
      _.last(asset_string.split('_'))
    )
    if (!(group_ids.length > 0)) return

    return $.getJSON(
      `/api/v1/appointment_groups/next_appointment?${$.param({appointment_group_ids: group_ids})}`,
      data => {
        if (data.length > 0) {
          const nextDate = Date.parse(data[0].start_at)
          if (nextDate < range.start || nextDate >= range.end) {
            // fixme link
            $.flashMessage(
              I18n.t('The next available appointment in this course is on *%{date}*', {
                wrappers: [
                  `<a href='#' class='gotoDate_link' data-date='${nextDate.toISOString()}'>$1</a>`
                ],
                date: tz.format(nextDate, 'date.formats.long')
              }),
              30000
            )
          }
        } else {
          $.flashWarning(I18n.t('There are no available signups for this course.'))
        }
      }
    )
  }
}
