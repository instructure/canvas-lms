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

import type {StoreState as CoursePageStoreState} from '../../types'
import {type BlackoutDate, SyncState, type BlackoutDateState} from '../types'
import {Constants, type BlackoutDatesAction} from '../actions/blackout_dates'
import {getInitialBlackoutDates} from '../../reducers/original'

export const getBlackoutDates = (state: CoursePageStoreState): BlackoutDate[] => {
  return state.blackoutDates.blackoutDates
}

export const getBlackoutDatesSyncing = (state: CoursePageStoreState) => {
  return state.blackoutDates.syncing === SyncState.SYNCING
}

export const getBlackoutDatesUnsynced = (state: CoursePageStoreState) => {
  return state.blackoutDates.syncing === SyncState.UNSYNCED
}

/* Reducers */

export const blackoutDatesReducer = (
  state = {
    syncing: SyncState.SYNCED,
    blackoutDates: getInitialBlackoutDates(),
  },
  action: BlackoutDatesAction
): BlackoutDateState => {
  switch (action.type) {
    case Constants.UPDATE_BLACKOUT_DATES:
      return {
        syncing: SyncState.UNSYNCED,
        blackoutDates: action.payload.sort(compareBlackoutDatesByStartDate),
      }
    case Constants.BLACKOUT_DATES_SYNCING:
      return {...state, syncing: SyncState.SYNCING}
    case Constants.BLACKOUT_DATES_SYNCED:
      return {
        syncing: SyncState.SYNCED,
        blackoutDates: action.payload
          ? action.payload.sort((a, b) => {
              if (a.start_date.isBefore(b.start_date)) return -1
              if (a.start_date.isAfter(b.start_date)) return 1
              return 0
            })
          : state.blackoutDates,
      } as BlackoutDateState
    case Constants.BLACKOUT_DATES_SYNC_FAILED:
      return {...state, syncing: SyncState.UNSYNCED}
    case Constants.RESET_BLACKOUT_DATES:
      return {
        syncing: SyncState.SYNCED,
        blackoutDates: action.payload,
      }
    default:
      return state
  }
}

function compareBlackoutDatesByStartDate(a: BlackoutDate, b: BlackoutDate): number {
  if (a.start_date.isBefore(b.start_date)) return -1
  if (a.start_date.isAfter(b.start_date)) return 1
  return 0
}
