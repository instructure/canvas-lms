// @ts-nocheck
/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import moment from 'moment-timezone'
import {BlackoutDate} from '../shared/types'
import * as DateHelpers from '../utils/date_stuff/date_helpers'
import doFetchApi, {DoFetchApiResults} from '@canvas/do-fetch-api-effect'
import {initialCalendarEventBlackoutDates} from '../reducers/original'

/* API methods */

export const sync = (course_id: string | number) => {
  if (!course_id) return
  const path = course_id
    ? `/api/v1/courses/${course_id}/blackout_dates`
    : '/api/v1/acccounts/???/blackout_dates' // this hasn't been worked out yet.

  return doFetchApi<ApiFormattedBlackoutDate[]>({
    path,
    method: 'PUT',
    body: {
      blackout_dates: [],
    },
  })
    .then(result => {
      if (!result.response.ok) {
        throw new Error(result.response.statusText)
      }
      return result
    })
    .then(result => {
      return ((result.json || []) as Array<ApiFormattedBlackoutDate>).map(bd =>
        transformBlackoutDateFromApi(bd)
      )
    })
}

export const calendarEventsSync = (
  blackoutDates: BlackoutDate[],
  course_id: string
): BlackoutDate[] => {
  if (!course_id) return []

  const originalEvents = initialCalendarEventBlackoutDates

  const deletedBlackoutDates = originalEvents.filter(bd => !blackoutDates.includes(bd))

  for (const event of deletedBlackoutDates) {
    deleteCalendarEvent(event)
  }

  const addedBlackoutDates = blackoutDates.filter(bd => !originalEvents.includes(bd))

  for (const event of addedBlackoutDates) {
    addCalendarEvent(event, course_id)
  }

  return blackoutDates
}

const deleteCalendarEvent = (event: BlackoutDate) => {
  const path = `/api/v1/calendar_events/${event.id}`

  return doFetchApi<ApiFormattedCalendarEventBlackoutDate>({
    path,
    method: 'DELETE',
    body: {
      calendar_event: event,
    },
  })
    .then(result => {
      if (!result.response.ok) {
        throw new Error(result.response.statusText)
      }
      return result
    })
    .then(result => {
      return toBlackoutDate(result)
    })
}

const addCalendarEvent = (event: BlackoutDate, course_id: string) => {
  const path = `/api/v1/calendar_events`

  return doFetchApi<ApiFormattedCalendarEventBlackoutDate>({
    path,
    method: 'POST',
    body: {
      calendar_event: toCalendarEvent(event, course_id),
    },
  })
    .then(result => {
      if (!result.response.ok) {
        throw new Error(result.response.statusText)
      }
      return result
    })
    .then(result => {
      return toBlackoutDate(result)
    })
}

const toBlackoutDate = (
  result: DoFetchApiResults<ApiFormattedCalendarEventBlackoutDate>
): BlackoutDate => {
  const event_title = result.json?.title || ''
  const start_date = moment(result.json?.start_at)
  const end_date = moment(result.json?.end_at)
  return {
    event_title,
    start_date,
    end_date,
    is_calendar_event: true,
    title: event_title,
    start_at: start_date,
    end_at: end_date,
  }
}

const toCalendarEvent = (blackoutDate: BlackoutDate, course_id: string) => {
  return {
    title: blackoutDate.event_title,
    start_at: blackoutDate.start_date,
    end_at: blackoutDate.end_date,
    blackout_date: true,
    context_code: `course_${course_id}`,
    all_day: true,
  }
}

/* API transformers */
interface ApiFormattedBlackoutDate {
  event_title: string
  start_date: string
  end_date: string
}

interface ApiFormattedCalendarEventBlackoutDate {
  title: string
  start_at: string
  end_at: string
}

function transformBlackoutDateForApi(blackoutDate: BlackoutDate): ApiFormattedBlackoutDate {
  const formattedBlackoutDate: ApiFormattedBlackoutDate = {
    event_title: blackoutDate.event_title,
    start_date: DateHelpers.formatDate(blackoutDate.start_date),
    end_date: DateHelpers.formatDate(blackoutDate.end_date),
  }
  return formattedBlackoutDate
}

export function transformBlackoutDatesForApi(
  blackoutDates: BlackoutDate[]
): ApiFormattedBlackoutDate[] {
  return blackoutDates.map(
    (bd: BlackoutDate): ApiFormattedBlackoutDate => transformBlackoutDateForApi(bd)
  )
}

function transformBlackoutDateFromApi(response: ApiFormattedBlackoutDate): BlackoutDate {
  const transformedBlackoutDate: BlackoutDate = {
    ...response,
    start_date: moment(response.start_date),
    end_date: moment(response.end_date),
  }
  return transformedBlackoutDate
}
