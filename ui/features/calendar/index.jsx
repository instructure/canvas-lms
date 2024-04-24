/*
 * Copyright (C) 2011 - present Instructure, Inc.
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

// this is responsible for gluing all the calendar parts together into a complete page
// the only thing on the erb page should be `calendarApp.init(<contexts>, <manageContexts>);`
import $ from 'jquery'
import Calendar from './jquery/index'
import ReactDOM from 'react-dom'
import React from 'react'
import MiniCalendar from './jquery/MiniCalendar'
import FindAppointment from './react/scheduler/components/FindAppointment'
import CalendarHeader from './backbone/views/CalendarHeader'
import drawSidebar from './jquery/sidebar'
import EventDataSource from '@canvas/calendar/jquery/EventDataSource'
import UndatedEventsList from './jquery/UndatedEventsList'
import configureSchedulerStore from './react/scheduler/store/configureStore'
import loadFullCalendarLocaleData from './ext/loadFullCalendarLocaleData'
import 'jquery-kyle-menu'
import {captureException} from '@sentry/react'

const eventDataSource = new EventDataSource(ENV.CALENDAR.CONTEXTS)
const schedulerStore = ENV.CALENDAR.SHOW_SCHEDULER ? configureSchedulerStore() : null
const start = () => {
  const header = new CalendarHeader({
    el: '#calendar_header',
    calendar2Only: ENV.CALENDAR.CAL2_ONLY,
  })

  if (ENV.FEATURES?.instui_header) {
    // we need to give time to the react component to be in the DOM
    return setTimeout(() => initializeDelayed(header), 200)
  }

  initializeDelayed(header)
}

const initializeDelayed = (header) => {
  const calendar = new Calendar(
    '#calendar-app',
    ENV.CALENDAR.CONTEXTS,
    ENV.CALENDAR.MANAGE_CONTEXTS,
    eventDataSource,
    {
      activateEvent: ENV.CALENDAR.ACTIVE_EVENT,
      viewStart: ENV.CALENDAR.VIEW_START,
      showScheduler: ENV.CALENDAR.SHOW_SCHEDULER,
      header,
      userId: ENV.current_user_id,
      schedulerStore,
      onLoadAppointmentGroups: agMap => {
        if (ENV.CALENDAR.SHOW_SCHEDULER) {
          const courses = eventDataSource.contexts.filter(context =>
            agMap.hasOwnProperty(context.asset_string)
          )
          if (courses.length > 0) {
            ReactDOM.render(
              <FindAppointment courses={courses} store={schedulerStore} />,
              $('#select-course-component')[0]
            )
          }
        }
      },
    }
  )
  const onContextsChange = additionalContexts => {
    calendar.syncNewContexts(additionalContexts)
    eventDataSource.syncNewContexts(additionalContexts)
  }

  new MiniCalendar('#minical', calendar)
  new UndatedEventsList('#undated-events', eventDataSource, calendar)
  drawSidebar(
    ENV.CALENDAR.CONTEXTS,
    ENV.CALENDAR.SELECTED_CONTEXTS,
    eventDataSource,
    onContextsChange
  )
}

const startAnyway = error => {
  // eslint-disable-next-line no-console
  console.error('Unable to load FullCalendar locale data for "%s" -- %s', ENV.MOMENT_LOCALE, error)
  start()
}

loadFullCalendarLocaleData(ENV.MOMENT_LOCALE).then(start, startAnyway).catch(captureException)

let keyboardUser = true

$('.calendar-button').on('mousedown', e => {
  keyboardUser = false
  $(e.target).find('.accessibility-warning').addClass('screenreader-only')
})

$(document).on('keydown', e => {
  if (e.which === 9) {
    // checking for tab press
    keyboardUser = true
  }
})

$('.calendar-button').on('focus', e => {
  if (keyboardUser) {
    $(e.target).find('.accessibility-warning').removeClass('screenreader-only')
  }
})

$('.calendar-button').on('focusout', e =>
  $(e.target).find('.accessibility-warning').addClass('screenreader-only')
)

$('.rs-section .accessibility-warning').on('focus', e =>
  $(e.target).removeClass('screenreader-only')
)

$('.rs-section .accessibility-warning').on('focusout', e =>
  $(e.target).addClass('screenreader-only')
)
