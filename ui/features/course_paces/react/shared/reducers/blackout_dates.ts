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

import {StoreState as CoursePageStoreState} from '../../types'
import {BlackoutDate} from '../types'
import {Constants, BlackoutDatesAction} from '../actions/blackout_dates'
import {getInitialBlackoutDates} from '../../reducers/original'

export const getBlackoutDates = (state: CoursePageStoreState) => {
  return state.blackoutDates
}

/* Reducers */

export const blackoutDatesReducer = (
  state = getInitialBlackoutDates(),
  action: BlackoutDatesAction
): BlackoutDate[] => {
  switch (action.type) {
    // case Constants.ADD_BLACKOUT_DATE:
    //   return [...state, action.payload]
    // case Constants.DELETE_BLACKOUT_DATE:
    //   return state.filter(blackoutDate => blackoutDate.id !== action.payload)
    case Constants.UPDATE_BLACKOUT_DATES:
      return action.payload.sort((a, b) => {
        if (a.start_date.isBefore(b.start_date)) return -1
        if (a.start_date.isAfter(b.start_date)) return 1
        return 0
      }) as BlackoutDate[]
    case Constants.ADD_BACKEND_ID:
      return state.map(blackoutDate => {
        if (blackoutDate.temp_id === action.payload.tempId) {
          return {
            ...blackoutDate,
            temp_id: undefined,
            id: action.payload.id
          }
        } else {
          return blackoutDate
        }
      })
    default:
      return state
  }
}
