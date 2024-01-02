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

import $ from 'jquery'
import {useScope as useI18nScope} from '@canvas/i18n'
import {defaults} from 'lodash'
import calendarDefaults from '../CalendarDefaults'
import 'jquery-tinypubsub'

const I18n = useI18nScope('calendar')

export default class MiniCalendar {
  constructor(selector, mainCalendar) {
    this.mainCalendar = mainCalendar
    this.calendar = $(selector)
    this.calendar.fullCalendar(
      defaults(
        {
          height: 185,
          buttonSRText: {
            prev: I18n.t('Previous month'),
            next: I18n.t('Next month'),
          },
          header: {
            left: 'prev',
            center: 'title',
            right: 'next',
          },
          dayClick: this.dayClick,
          events: this.getEvents,
          eventRender: this.eventRender,
          droppable: true,
          dragRevertDuration: 0,
          dropAccept: '.fc-event,.undated_event',
          drop: this.drop,
          eventDrop: this.drop,
          eventReceive: this.drop,
        },
        calendarDefaults
      ),
      $.subscribe({
        'Calendar/visibleContextListChanged': this.visibleContextListChanged,
        'Calendar/refetchEvents': this.refetchEvents,
        'Calendar/currentDate': this.gotoDate,
        'CommonEvent/eventDeleted': this.eventSaved,
        'CommonEvent/eventSaved': this.eventSaved,
        'CommonEvent/eventsSavedFromSeries': this.eventsSavedFromSeries,
      })
    )
  }

  getEvents = (start, end, timezone, donecb, datacb) => {
    // Since we have caching (lazyFetching) turned off, we can rely on this
    // getting called every time we switch views, *before* the events are rendered.
    // That makes this a great place to clear out the previous classes.

    this.calendar
      .find('.fc-widget-content td')
      .removeClass('event slot-available')
      .removeAttr('title')
    return this.mainCalendar.getEvents(start, end, timezone, donecb, datacb)
  }

  dayClick = date => this.mainCalendar.gotoDate(date)

  gotoDate = date => this.calendar.fullCalendar('gotoDate', date)

  eventRender = (event, element, view) => {
    const evDate = event.start.format('YYYY-MM-DD')
    const td = view.el.find(`*[data-date=\"${evDate}\"]`)[0]

    $(td).addClass('event')
    let tooltip = I18n.t('event_on_this_day', 'There is an event on this day')
    const appointmentGroupBeingViewed =
      this.mainCalendar.displayAppointmentEvents && this.mainCalendar.displayAppointmentEvents.id
    if (
      appointmentGroupBeingViewed &&
      appointmentGroupBeingViewed ===
        (event.calendarEvent && event.calendarEvent.appointment_group_id) &&
      event.object.available_slots
    ) {
      $(td).addClass('slot-available')
      tooltip = I18n.t('open_appointment_on_this_day', 'There is an open appointment on this day')
    }
    $(td).attr('title', tooltip)
    return false // don't render the event
  }

  visibleContextListChanged = _list => this.refetchEvents()

  eventSaved = () => this.refetchEvents()

  eventsSavedFromSeries = () => {
    this.refetchEvents()
  }

  refetchEvents = () => {
    if (!this.calendar.is(':visible')) return
    return this.calendar.fullCalendar('refetchEvents')
  }

  drop = (date, jsEvent, ui, view) => {
    const allDay = view.options.allDayDefault
    if (ui.helper.is('.undated_event')) {
      return this.mainCalendar.drop(date, allDay, jsEvent, ui)
    } else if (ui.helper.is('.fc-event')) {
      return this.mainCalendar.dropOnMiniCalendar(date, allDay, jsEvent, ui)
    }
  }
}
