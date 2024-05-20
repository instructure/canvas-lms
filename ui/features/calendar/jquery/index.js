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

import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import {map, defaults, filter, omit, each, has, last, includes} from 'lodash'
import * as tz from '@canvas/datetime'
import {encodeQueryString} from '@canvas/query-string-encoding'
import moment from 'moment'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import decodeFromHex from '@canvas/util/decodeFromHex'
import withinMomentDates from '../momentDateHelper'
import fcUtil from '@canvas/calendar/jquery/fcUtil'
import userSettings from '@canvas/user-settings'
import colorSlicer from 'color-slicer'
import calendarAppTemplate from '../jst/calendarApp.handlebars'
import commonEventFactory from '@canvas/calendar/jquery/CommonEvent/index'
import ShowEventDetailsDialog from './ShowEventDetailsDialog'
import EditEventDetailsDialog from './EditEventDetailsDialog'
import AgendaView from '../backbone/views/AgendaView'
import calendarDefaults from '../CalendarDefaults'
import ContextColorer from '@canvas/util/contextColorer'
import deparam from 'deparam'
import htmlEscape from '@instructure/html-escape'
import calendarEventFilter from '../CalendarEventFilter'
import schedulerActions from '../react/scheduler/actions'
import 'fullcalendar'
// import '../ext/patches-to-fullcalendar'
import '@canvas/jquery/jquery.instructure_misc_helpers'
import '@canvas/jquery/jquery.instructure_misc_plugins'
import 'jquery-tinypubsub'
import 'jqueryui/button'
import 'jqueryui/tooltip'

const I18n = useI18nScope('calendar')

// we use a <div> (with a <style> inside it) because you cant set .innerHTML directly on a
// <style> node in ie8
const $styleContainer = $('<div id="calendar_color_style_overrides" />').appendTo('body')

function isSomethingFullscreen(document) {
  // safari requires webkit prefix
  return !!document.fullscreenElement || !!document.webkitFullscreenElement
}
export default class Calendar {
  constructor(selector, contexts, manageContexts, dataSource, options) {
    this.contexts = contexts
    this.manageContexts = manageContexts
    this.dataSource = dataSource
    this.options = options
    this.contextCodes = (this.contexts || []).map(context => context.asset_string)
    this.visibleContextList = []
    // Display appointment slots for the specified appointment group
    this.displayAppointmentEvents = null
    this.activateEvent = this.options && this.options.activateEvent

    this.prevWindowHeight = window.innerHeight
    this.prevWindowWidth = window.innerWidth
    this.somethingIsFullscreen = isSomethingFullscreen(document)

    this.activeAjax = 0

    this.subscribeToEvents()
    this.header = this.options.header
    this.schedulerState = {}
    this.useScheduler = !!this.options.schedulerStore
    if (this.options.schedulerStore) {
      this.schedulerStore = this.options.schedulerStore
      this.schedulerState = this.schedulerStore.getState()
      this.schedulerStore.subscribe(this.onSchedulerStateChange)
    }

    this.el = $(selector).html(calendarAppTemplate())

    this.agenda = new AgendaView({
      el: $('.agenda-wrapper'),
      dataSource: this.dataSource,
      calendar: this,
      contextObjects: this.contexts,
    })

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
      this.dataSource.getAppointmentGroups(false, appointmentGroupsData => {
        let required = 0
        appointmentGroupsData.forEach(group => {
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
    this.connectAgendaEvents()
    $('#flash_message_holder').on('click', '.gotoDate_link', event =>
      this.gotoDate(fcUtil.wrap($(event.target).data('date')))
    )

    this.header.selectView(this.getCurrentView())

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
      'CommonEvent/eventsDeletingFromSeries': this.eventsDeletingFromSeries,
      'CommonEvent/eventDeleted': this.eventDeleted,
      'CommonEvent/eventsDeletedFromSeries': this.eventsDeletedFromSeries,
      'CommonEvent/eventsUpdatedFromSeries': this.eventsUpdatedFromSeries,
      'CommonEvent/eventSaving': this.eventSaving,
      'CommonEvent/eventsSavingFromSeries': this.eventsSavingFromSeries,
      'CommonEvent/eventSaved': this.eventSaved,
      'CommonEvent/eventsSavedFromSeries': this.eventsSavedFromSeries,
      'CommonEvent/eventSaveFailed': this.eventSaveFailed,
      'CommonEvent/eventsSavedFromSeriesFailed': this.eventsSavedFromSeriesFailed,
      'Calendar/visibleContextListChanged': this.visibleContextListChanged,
      'EventDataSource/ajaxStarted': this.ajaxStarted,
      'EventDataSource/ajaxEnded': this.ajaxEnded,
      'Calendar/refetchEvents': this.refetchEvents,
      'CommonEvent/assignmentSaved': this.updateOverrides,
      'Calendar/colorizeContexts': this.colorizeContexts,
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
    this.header.on('createNewEvent', this.addEventClick)
    this.header.on('refreshCalendar', this.reloadClick)
  }

  connectAgendaEvents() {
    this.agenda.on('agendaDateRange', this.renderDateRange)
  }

  initializeFullCalendarParams() {
    return defaults(
      {
        header: false,
        editable: true,
        buttonText: {
          today: I18n.t('today', 'Today'),
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
        // on mobile phones tell it to let the contentHeight be "auto"
        // so it doesn't force you to scroll up and down just to see all the
        // dates on the calendar
        [window.innerWidth < 450 && 'contentHeight']: 'auto',

        dragRevertDuration: 0,
        dragAppendTo: {month: '#calendar-drag-and-drop-container'},
        dragZIndex: {month: 350},
        dragCursorAt: {month: {top: -5, left: -5}},
      },

      calendarDefaults
    )
  }

  // This is used to set a custom time format for regions who use 24 hours time.
  // We return null in the non 24 time case so that we can allow the fullcallendar npm package
  // to set whatever time format calendar events should be
  eventTimeFormat() {
    return I18n.lookup('time.formats.tiny_on_the_hour') === '%k:%M' ? 'HH:mm' : null
  }

  today = () => {
    return this.gotoDate(fcUtil.now())
  }

  // FullCalendar callbacks
  getEvents = (start, end, timezone, donecb, datacb) => {
    this.gettingEvents = true
    const contexts = this.visibleContextList.concat(this.findAppointmentModeGroups())

    const _donecb = events => {
      if (this.displayAppointmentEvents) {
        return this.dataSource.getEventsForAppointmentGroup(
          this.displayAppointmentEvents,
          aEvents => {
            // Make sure any events in the current appointment group get marked -
            // order is important here, as some events in aEvents may also appear in
            // events. So clear events first, then mark aEvents. Our de-duping algorithm
            // will keep the duplicates at the end of the list first.
            events.forEach(event => event.removeClass('current-appointment-group'))
            aEvents.forEach(event => event.addClass('current-appointment-group'))
            this.gettingEvents = false
            donecb(
              calendarEventFilter(
                this.displayAppointmentEvents,
                events.concat(aEvents),
                this.schedulerState
              )
            )
          }
        )
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
    if (datacb)
      _datacb = events =>
        datacb(calendarEventFilter(this.displayAppointmentEvents, events, this.schedulerState))

    return this.dataSource.getEvents(start, end, contexts, _donecb, _datacb)
  }

  // Close all event details popup on the page and have them cleaned up.
  closeEventPopups() {
    // Close any open popup as it gets detached when rendered
    $('.event-details').each(function () {
      const existingDialog = $(this).data('showEventDetailsDialog')
      if (existingDialog) {
        existingDialog.close()
      }
    })
  }

  windowResize = _view => {
    // The below hack to call .trigger('resize') for the weekly view also triggers this event handler,
    // which causes the pop-up to close if it is already open by the time the resize callback is called.
    // That hack doesn't rely on this handler to run, so let's just make sure that the window size has
    // actually changed before doing anything.
    if (
      this.prevWindowHeight === window.innerHeight &&
      this.prevWindowWidth === window.innerWidth
    ) {
      return
    }

    this.prevWindowHeight = window.innerHeight
    this.prevWindowWidth = window.innerWidth

    if (
      (!this.somethingIsFullscreen && isSomethingFullscreen(document)) ||
      (this.somethingIsFullscreen && !isSomethingFullscreen(document))
    ) {
      // something just transitioned into or out of fullscreen.
      // don't close the event popup
      this.somethingIsFullscreen = isSomethingFullscreen(document)
      return
    }
    this.closeEventPopups()
    this.drawNowLine()
    if (_view.name === 'month') {
      // add a delay to wait until the calendar elements get resized
      setTimeout(() => {
        $.each($('.fc-event'), (i, e) => this.renderTooltipIfNeeded($(e)))
      }, 1000)
    }
  }

  eventRender = (event, element, _view) => {
    const $element = $(element)

    const startDate = event.startDate()
    const endDate = event.endDate()
    const timeString = (() => {
      if (!endDate || +startDate === +endDate || event.blackout_date) {
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
      : event.eventType === 'planner_note'
      ? I18n.t('To Do:')
      : I18n.t('Event Title:')

    let reservedText = ''
    if (event.isAppointmentGroupEvent()) {
      if (event.appointmentGroupEventStatus === I18n.t('Reserved')) {
        reservedText = `\n\n${I18n.t('Reserved By You')}`
      } else if (event.reservedUsers === '') {
        reservedText = `\n\n${I18n.t('Unreserved')}`
      } else {
        reservedText = `\n\n${I18n.t('Reserved By: ')} ${event.reservedUsers}`
      }
    }

    const newTitle =
      _view.name === 'month'
        ? $.trim(htmlEscape(element.find('.fc-title').text()))
        : $.trim(
            `${timeString}\n${$element.find('.fc-title').text()}\n\n${I18n.t(
              'Calendar:'
            )} ${htmlEscape(event.contextInfo.name)} ${htmlEscape(reservedText)}`
          )

    $element.attr('title', newTitle)
    $element
      .find('.fc-content')
      .prepend(
        $(
          `<span class='screenreader-only'>${htmlEscape(
            I18n.t('calendar_title', 'Calendar:')
          )} ${htmlEscape(event.contextInfo.name)}</span>`
        )
      )
    $element
      .find('.fc-title')
      .prepend($(`<span class='screenreader-only'>${htmlEscape(screenReaderTitleHint)} </span>`))
    $element.find('.fc-title').toggleClass('calendar__event--completed', event.isCompleted())
    element.find('.fc-content').prepend($('<i />', {class: `icon-${event.iconType()}`}))
    return true
  }

  eventAfterRender = (event, element, view) => {
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
    if (
      event.eventType.match(/assignment/) &&
      event.isDueStrictlyAtMidnight() &&
      view.name === 'month'
    ) {
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
          pageX: element.offset().left + parseInt(element.width() / 2, 10),
        },
        view
      )
    }

    if (view.name === 'month') {
      this.renderTooltipIfNeeded(element)
    }
  }

  renderTooltipIfNeeded = element => {
    const availableWidth = element.find('.fc-content').width()
    const iconWidth = element.find('i').width()
    const timeWidth = element.find('.fc-time').width()
    const titleWidth = element.find('.fc-title').width()
    const requiredRowWidth = titleWidth + iconWidth + timeWidth
    if (requiredRowWidth > availableWidth) {
      element.tooltip({
        position: {my: 'center bottom', at: 'center top-10', collision: 'fit fit'},
        tooltipClass: 'center bottom vertical',
        show: {delay: 300},
      })
      element.data('title', element.attr('title'))
    } else if (element.data('ui-tooltip')) {
      element.tooltip('destroy')
      // sometimes unbinding the tooltip clears the title attribute of the element, let's add it back
      element.attr('title', element.data('title'))
    }
  }

  eventDragStart = (event, _jsEvent, _ui, _view) => {
    $('.fc-highlight-skeleton').remove()
    this.lastEventDragged = event
    this.closeEventPopups()
  }

  eventResizeStart = (_event, _jsEvent, _ui, _view) => {
    this.closeEventPopups()
  }

  // event triggered by items being dropped from within the calendar
  eventDrop = (event, delta, revertFunc, _jsEvent, _ui, _view) => {
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
      (event.assignment.unlock_at || event.assignment.lock_at)
    ) {
      startDate = event.assignment.unlock_at && moment(event.assignment.unlock_at)
      endDate = event.assignment.lock_at && moment(event.assignment.lock_at)
      if (!withinMomentDates(event.start, startDate, endDate)) {
        revertFunc()
        showFlashAlert({
          message: I18n.t(
            'Assignment has a locked date. Due date cannot be set outside of locked date range.'
          ),
          err: null,
          type: 'error',
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

  eventResize = (event, delta, revertFunc, _jsEvent, _ui, _view) => {
    return event.saveDates(null, revertFunc)
  }

  activeContexts() {
    const allowedContexts =
      userSettings.get('checked_calendar_codes') || map(this.contexts, 'asset_string')
    return filter(this.contexts, c => includes(allowedContexts, c.asset_string))
  }

  addEventClick = (event, _jsEvent, _view) => {
    if (this.displayAppointmentEvents) {
      // Don't allow new event creation while in scheduler mode
      return
    }

    if (!this.hasValidContexts()) {
      // Don't create the event if there are no active contexts
      return
    }

    // create a new dummy event
    event = commonEventFactory(null, this.activeContexts())
    event.date = this.getCurrentDate()
    return new EditEventDetailsDialog(event, this.useScheduler).show()
  }

  eventClick = (event, jsEvent, _view) => {
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

  dayClick = (date, _jsEvent, _view) => {
    if (this.displayAppointmentEvents) {
      // Don't allow new event creation while in scheduler mode
      return
    }

    if (!this.hasValidContexts()) {
      // Don't create the event if there are no active contexts
      return
    }

    // create a new dummy event
    const event = commonEventFactory(null, this.activeContexts())
    event.date = date
    event.allDay = !date.hasTime()
    return new EditEventDetailsDialog(event, this.useScheduler).show()
  }

  hasValidContexts = () => {
    const activeCtxs = this.activeContexts()
    if (activeCtxs.length === 0) {
      const alertContainer = $('.flashalert-message')
      if (alertContainer.length === 0) {
        showFlashAlert({
          message: I18n.t('You must select at least one calendar to create an event.'),
          type: 'info',
        })
      }
      return false
    }
    return true
  }

  updateFragment(opts) {
    const replaceState = !!opts.replaceState
    opts = omit(opts, 'replaceState')
    const data = this.dataFromDocumentHash()
    let changed = false
    for (const k in opts) {
      const v = opts[k]
      if (data[k] !== v) changed = true
      if (v) {
        data[k] = v
      } else {
        delete data[k]
      }
    }
    if (changed) {
      const fragment = '#' + encodeQueryString(data, this)
      if (replaceState || window.location.hash === '') {
        return window.history.replaceState(null, '', fragment)
      } else {
        return (window.location.href = fragment)
      }
    }
  }

  viewRender = view => {
    this.setDateTitle(view.title)
    this.drawNowLine()
  }

  enableExternalDrags = eventEl => {
    return $(eventEl).draggable({
      zIndex: 999,
      revert: true,
      revertDuration: 0,
      refreshPositions: true,
      addClasses: false,
      appendTo: 'calendar-drag-and-drop-container',
      // clone doesn't seem to work :(
      helper: 'clone',
    })
  }

  isSameWeek(date1, date2) {
    const week1 = fcUtil.clone(date1).weekday(0).stripTime()
    const week2 = fcUtil.clone(date2).weekday(0).stripTime()
    return +week1 === +week2
  }

  drawNowLine = () => {
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
    midnight.minutes(0)
    midnight.seconds(0)
    const seconds = moment.duration(now.diff(midnight)).asSeconds()
    this.$nowLine.toggle(this.isSameWeek(this.getCurrentDate(), now))

    this.$nowLine.css('width', $('.fc-body .fc-widget-content:first').css('width'))
    const secondHeight =
      (($('.fc-time-grid .fc-slats').css('height') || '').replace('px', '') || 0) / 24 / 60 / 60
    this.$nowLine.css('top', `${seconds * secondHeight}px`)
  }

  setDateTitle = title => {
    return this.header.setHeaderText(title)
  }

  // event triggered by items being dropped from outside the calendar
  drop = (date, jsEvent, ui) => {
    const eventId = $(ui.helper).data('event-id')
    const event = $(`[data-event-id=${eventId}]`).data('calendarEvent')
    if (!event) {
      return
    }
    event.start = date
    event.addClass('event_pending')
    const revertFunc = () => console.log('could not save date on undated event') // eslint-disable-line no-console

    if (!this._eventDrop(event, 0, false, revertFunc)) {
      return
    }
    return this.calendar.fullCalendar('renderEvent', event)
  }

  // callback from minicalendar telling us an event from here was dragged there
  dropOnMiniCalendar(date, _allDay, _jsEvent, _ui) {
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

  fragmentChange = (_event, _hash) => {
    const data = this.dataFromDocumentHash()
    if ($.isEmptyObject(data)) {
      return
    }

    if (data.view_name !== this.currentView) {
      this.loadView(data.view_name)
    }

    return this.gotoDate(this.getCurrentDate())
  }

  reloadClick = event => {
    if (event != null) {
      event.preventDefault()
    }
    if (this.activeAjax === 0) {
      this.dataSource.clearCache()
      return this.calendar.fullCalendar('refetchEvents')
    }
  }

  // Subscriptions

  updateEvent = event => {
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

  filterEventsWithSeriesIdAndWhich = (selectedEvent, which) => {
    const seriesId = selectedEvent.calendarEvent.series_uuid
    const eventSeries = this.calendar
      .fullCalendar('clientEvents')
      .filter(c => c.eventType === 'calendar_event' && c.calendarEvent.series_uuid === seriesId)

    let candidateEvents
    switch (which) {
      case 'one':
        candidateEvents = [selectedEvent]
        break
      case 'following':
        candidateEvents = eventSeries
          .sort((a, b) => a.calendarEvent.start_at.localeCompare(b.calendarEvent.start_at, 'en'))
          .filter(e => e.calendarEvent.start_at >= selectedEvent.calendarEvent.start_at)
        break
      case 'all':
        candidateEvents = eventSeries
        break
    }
    return candidateEvents
  }

  eventDeleting = event => {
    event.addClass('event_pending')
    return this.updateEvent(event)
  }

  // given the event selected by the user, and which
  // events in the series are being deleted (one, following, all)
  // find them all and handle it
  eventsDeletingFromSeries = ({selectedEvent, which}) => {
    const candidateEvents = this.filterEventsWithSeriesIdAndWhich(selectedEvent, which)
    candidateEvents.forEach(e => {
      $.publish('CommonEvent/eventDeleting', e)
    })
  }

  eventDeleted = event => {
    if (event.isAppointmentGroupEvent() && event.calendarEvent.parent_event_id) {
      this.handleUnreserve(event)
    }
    return this.calendar.fullCalendar('removeEvents', event.id)
  }

  // given the response from the delete api,
  // which is an array of calendar event objects,
  // remove the corresponding events from the calendar
  eventsDeletedFromSeries = ({deletedEvents}) => {
    const eventIds = deletedEvents.map(e => e.id)
    const eventsInContext = this.dataSource.cache.contexts[deletedEvents[0].context_code].events
    const deletedEventsFromSeries = []
    Object.keys(eventsInContext).forEach(key => {
      const e = eventsInContext[key]
      if (eventIds.includes(e.object.id)) {
        deletedEventsFromSeries.push(e)
      }
    })

    deletedEventsFromSeries.forEach(e => $.publish('CommonEvent/eventDeleted', e))
  }

  // when an appointment event was deleted, clear the reserved flag and increment the available slot count on the parent
  handleUnreserve = event => {
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

  eventSaving = event => {
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

  eventsSavingFromSeries = ({selectedEvent, which}) => {
    const candidateEvents = this.filterEventsWithSeriesIdAndWhich(selectedEvent, which)
    candidateEvents.forEach(e => {
      // when changing one event in the calendar, its contextInfo gets changed
      // in CalendarEventDetailsForm when the user submits. When updating
      // events in a series we need to update the rest of the matching events
      // from the series
      if (which !== 'one' && e.id !== selectedEvent.id && e.can_change_context) {
        e.old_context_code = e.calendarEvent.context_code
        e.contextInfo = selectedEvent.contextInfo
      }

      $.publish('CommonEvent/eventSaving', e)
    })
  }

  eventSaved = event => {
    event.removeClass('event_pending')

    // If we just saved a new event then the id field has changed from what it
    // was in eventSaving. So we need to clear out the old _id that
    // fullcalendar stores for itself because the id has changed.
    // This is another reason to do a refetchEvents instead of just an update.
    delete event._id
    // If is array means that it returned an array of event series, so we apply
    // the same approach when update/delete series
    if (Array.isArray(event.calendarEvent)) {
      this.dataSource.clearCache()
    }
    this.calendar.fullCalendar('refetchEvents')
    if (event && event.object && event.object.duplicates && event.object.duplicates.length > 0)
      this.reloadClick()
    // We'd like to just add the event to the calendar rather than fetching,
    // but the save may be as a result of moving an event from being undated
    // to dated, and in that case we don't know whether to just update it or
    // add it. Some new state would need to be kept to track that.
    this.closeEventPopups()
  }

  eventsSavedFromSeries = ({seriesEvents}) => {
    // do what eventSaved does
    seriesEvents.forEach(event => {
      event.removeClass('event_pending')
      delete event._id
    })
    this.closeEventPopups()
  }

  eventSaveFailed = event => {
    event.removeClass('event_pending')
    if (event.isNewEvent()) {
      return this.calendar.fullCalendar('removeEvents', event.id)
    } else {
      return this.updateEvent(event)
    }
  }

  eventsSavedFromSeriesFailed = ({selectedEvent, which}) => {
    const candidateEvents = this.filterEventsWithSeriesIdAndWhich(selectedEvent, which)
    candidateEvents.forEach(e => {
      $.publish('CommonEvent/eventSaveFailed', e)
    })
  }

  // When we delete an event + all following from a series
  // the remaining events get updated with a new rrule
  eventsUpdatedFromSeries = ({updatedEvents}) => {
    const candidateEventsInCalendar = this.calendar.fullCalendar('clientEvents').filter(c => {
      if (c.eventType === 'calendar_event') {
        const updatedEventIndex = updatedEvents.findIndex(e => c.calendarEvent.id === e.id)
        if (updatedEventIndex >= 0) {
          c.copyDataFromObject(updatedEvents[updatedEventIndex])
          return true
        }
      }
      return false
    })
    // with the jquery and fullcalendar version update, editing events in a series
    // would not update the contextInfo of the event the user initiated the change in
    // resulting in the wrong info being shown in the detail dialog when clicking on an event.
    // I cannot figure out where the contextInfo is failing to get updated. This fixes it.
    // This change also means we don't need to look for special cases where we need to clear
    // the cache, since it's always happening now.
    this.dataSource.resetContexts()

    candidateEventsInCalendar.forEach(e => {
      this.updateEvent(e)
    })
    $.publish('CommonEvent/eventsSavedFromSeries', {seriesEvents: candidateEventsInCalendar})

    this.calendar.fullCalendar('refetchEvents')
  }

  // When an assignment event is updated, update its related overrides.
  updateOverrides = event => {
    each(this.dataSource.cache.contexts[event.contextCode()].events, (override, key) => {
      if (key.match(/override/) && event.assignment.id === override.assignment.id) {
        override.updateAssignmentTitle(event.title)
      }
    })
  }

  visibleContextListChanged = newList => {
    this.visibleContextList = newList
    if (this.currentView === 'agenda') {
      this.loadAgendaView()
    }
    return this.calendar.fullCalendar('refetchEvents')
  }

  ajaxStarted = () => {
    this.activeAjax += 1
    return this.header.animateLoading(true)
  }

  ajaxEnded = () => {
    this.activeAjax -= 1
    return this.header.animateLoading(this.activeAjax > 0)
  }

  refetchEvents = () => {
    return this.calendar.fullCalendar('refetchEvents')
  }

  // Methods

  // expects a fudged Moment object (use fcUtil
  // before calling if you must coerce)
  gotoDate = date => {
    this.calendar.fullCalendar('gotoDate', date)
    if (this.currentView === 'agenda') {
      this.agendaViewFetch(date)
    }
    this.setCurrentDate(date)
    this.drawNowLine()
  }

  navigateDate = d => {
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
      replaceState: true,
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
      replaceState: !has(this.dataFromDocumentHash(), 'view_name'),
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

  loadView = view => {
    if (view === this.currentView) {
      return
    }
    this.setCurrentView(view)

    $('.agenda-wrapper').removeClass('active')
    this.header.showNavigator()
    this.header.showPrevNext()
    this.header.hideAgendaRecommendation()

    this.updateFragment({appointment_group_id: null})
    this.agenda.viewingGroup = null

    if (view !== 'agenda') {
      // rerender title so agenda title doesnt stay
      const viewObj = this.calendar.fullCalendar('getView')
      this.viewRender(viewObj)

      this.displayAppointmentEvents = null
      this.header.showAgendaRecommendation()
      this.calendar.show()
      this.calendar.fullCalendar('refetchEvents')
      this.calendar.fullCalendar('changeView', view === 'week' ? 'agendaWeek' : 'month')
      this.calendar.fullCalendar('render')
      // HACK: events often start out in the wrong place when the calendar view is initialized to the week view
      // and they snap into the right place after the window is resized.  so... pretend the window gets resized
      if (view === 'week') {
        setTimeout(() => {
          $(window).trigger('resize')
        }, 200)
      }
    } else {
      this.calendar.hide()
      this.header.hidePrevNext()
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

  renderDateRange = (start, end) => {
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
          end: this.formatDate(end, 'date.formats.long'),
        })
      )
    }, 500)
  }

  syncNewContexts = additionalContexts => {
    if (additionalContexts?.length > 0) {
      additionalContexts.forEach(additionalContext => {
        const context = this.contexts.find(c => c.asset_string === additionalContext.asset_string)
        if (!context) {
          this.contexts.push(additionalContext)
          this.contextCodes.push(additionalContext.asset_string)
        }
      })
      this.colorizeContexts()
    }
  }

  colorizeContexts = () => {
    // Get any custom colors that have been set
    $.getJSON(`/api/v1/users/${this.options.userId}/colors/`, data => {
      const customColors = data.custom_colors
      const colors = colorSlicer.getColors(this.contextCodes.length, 275)
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

  dataFromDocumentHash = () => {
    let data = {}
    try {
      const fragment = window.location.hash.substring(1)
      if (fragment.indexOf('=') !== -1) {
        data = deparam(window.location.hash.substring(1)) || {}
      } else {
        // legacy
        data = JSON.parse(decodeFromHex(window.location.hash.substring(1))) || {}
      }
    } catch (e) {
      data = {}
    }
    return data
  }

  onSchedulerStateChange = () => {
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

  findAppointmentModeGroups = () => {
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

  visibleDateRange = () => {
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

  findNextAppointment = () => {
    // determine whether any reservable appointment slots are visible
    const range = this.visibleDateRange()
    // FIXME attempted optimization, except these events aren't in the cache yet;
    // if we want to do this, it needs to happen after @refetchEvents completes (asynchronously)
    // which may actually make the UI less responsive
    // courseEvents = @dataSource.getEventsFromCacheForContext range.start, range.end, @schedulerState.selectedCourse.asset_string
    // return if _.some courseEvents, (event) ->
    //    event.isAppointmentGroupEvent() && event.calendarEvent.reserve_url &&
    //    !event.calendarEvent.reserved && event.calendarEvent.available_slots > 0

    // find the next reservable appointment and report its date
    const group_ids = map(this.findAppointmentModeGroups(), asset_string =>
      last(asset_string.split('_'))
    )
    if (!(group_ids.length > 0)) return

    return $.getJSON(
      `/api/v1/appointment_groups/next_appointment?${encodeQueryString({
        appointment_group_ids: group_ids,
      })}`,
      data => {
        if (data.length > 0) {
          const nextDate = Date.parse(data[0].start_at)
          if (nextDate < range.start || nextDate >= range.end) {
            // fixme link
            $.flashMessage(
              I18n.t('The next available appointment in this course is on *%{date}*', {
                wrappers: [
                  `<a href='#' class='gotoDate_link' data-date='${nextDate.toISOString()}'>$1</a>`,
                ],
                date: tz.format(nextDate, 'date.formats.long'),
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
