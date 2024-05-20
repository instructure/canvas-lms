/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import type {CoursePace, OriginalState, StoreState} from '../types'
import type {BlackoutDate} from '../shared/types'
import {Constants as CoursePaceConstants} from '../actions/course_paces'
import {Constants as BlackoutDateConstants} from '../shared/actions/blackout_dates'
import {Constants as UIConstants} from '../actions/ui'

const initialBlackoutDates: BlackoutDate[] = (window.ENV.BLACKOUT_DATES || []) as BlackoutDate[]
initialBlackoutDates.forEach(blackoutDate => {
  blackoutDate.start_date = moment(blackoutDate.start_date)
  blackoutDate.end_date = moment(blackoutDate.end_date)
})
initialBlackoutDates.sort((a, b) => {
  if (a.start_date.isBefore(b.start_date)) return -1
  if (a.start_date.isAfter(b.start_date)) return 1
  return 0
})

export const initialCalendarEventBlackoutDates: BlackoutDate[] = (window.ENV
  .CALENDAR_EVENT_BLACKOUT_DATES || []) as BlackoutDate[]
initialCalendarEventBlackoutDates.forEach(blackoutDate => {
  blackoutDate.is_calendar_event = true
  blackoutDate.event_title = blackoutDate.title || 'Untitled'
  blackoutDate.start_date = moment(blackoutDate.start_at)
  blackoutDate.end_date = moment(blackoutDate.end_at)
})
initialCalendarEventBlackoutDates.sort((a, b) => {
  if (a.start_date.isBefore(b.start_date)) return -1
  if (a.start_date.isAfter(b.start_date)) return 1
  return 0
})

/* Selectors */

// the initial values on load
export const getInitialBlackoutDates = (): BlackoutDate[] => {
  const dates: BlackoutDate[] = initialBlackoutDates.concat(initialCalendarEventBlackoutDates)
  dates.sort((a, b) => {
    if (a.start_date.isBefore(b.start_date)) return -1
    if (a.start_date.isAfter(b.start_date)) return 1
    return 0
  })
  return dates
}
export const getInitialCoursePace = (): CoursePace => window.ENV.COURSE_PACE as CoursePace

// the current reference values
export const getOriginalPace = (state: StoreState): CoursePace => state.original.coursePace
export const getOriginalBlackoutDates = (state: StoreState): BlackoutDate[] =>
  state.original.blackoutDates

const initialState: OriginalState = {
  coursePace: getInitialCoursePace(),
  blackoutDates: getInitialBlackoutDates(),
}

/* Reducers */

export const originalReducer = (state = initialState, action: any): OriginalState => {
  switch (action.type) {
    case CoursePaceConstants.COURSE_PACE_SAVED:
      return {...state, coursePace: action.payload}
    case BlackoutDateConstants.BLACKOUT_DATES_SYNCED:
      return {...state, blackoutDates: action.payload}
    case UIConstants.SET_SELECTED_PACE_CONTEXT:
      return {...state, coursePace: action.payload.newSelectedPace}
    default:
      return state
  }
}
