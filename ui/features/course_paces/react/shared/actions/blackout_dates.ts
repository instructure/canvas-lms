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

import type {Action} from 'redux'
import type {ThunkAction} from 'redux-thunk'

import {actions as uiActions} from '../../actions/ui'
import type {StoreState} from '../../types'
import {createAction, type ActionsUnion, type BlackoutDate} from '../types'
import * as BlackoutDatesApi from '../../api/blackout_dates_api'

export enum Constants {
  BLACKOUT_DATES_SYNCING = 'BLACKOUT_DATES/SYNCING',
  BLACKOUT_DATES_SYNCED = 'BLACKOUT_DATES/SYNCED',
  BLACKOUT_DATES_SYNC_FAILED = 'BLACKOUT_DATES/SYNC_FAILED',
  UPDATE_BLACKOUT_DATES = 'BLACKOUT_DATES/UPDATE',
  RESET_BLACKOUT_DATES = 'BLACKOUT_DATES/RESET',
}

/* Action Creators */

const regularActions = {
  blackoutDatesSyncing: () => createAction(Constants.BLACKOUT_DATES_SYNCING),
  blackoutDatesSynced: (blackoutDates?: BlackoutDate[]) =>
    createAction(Constants.BLACKOUT_DATES_SYNCED, blackoutDates),
  blackoutDatesSyncFailed: () => createAction(Constants.BLACKOUT_DATES_SYNC_FAILED),
  updateBlackoutDates: (blackoutDates: BlackoutDate[]) =>
    createAction(Constants.UPDATE_BLACKOUT_DATES, blackoutDates),
  resetBlackoutDates: (originalBlackoutDates: BlackoutDate[]) =>
    createAction(Constants.RESET_BLACKOUT_DATES, originalBlackoutDates),
}

const thunkActions = {
  resetBlackoutDates: (): ThunkAction<void, StoreState, void, Action> => {
    return (dispatch, getState) => {
      const originalBlackoutDates = getState().original.blackoutDates
      return dispatch(regularActions.resetBlackoutDates(originalBlackoutDates))
    }
  },
  syncBlackoutDates: (): ThunkAction<Promise<void>, StoreState, void, Action> => {
    return (dispatch, getState) => {
      dispatch(uiActions.clearCategoryError('blackout_dates'))

      const blackoutDates = getState().blackoutDates.blackoutDates
      const course_id = getState().coursePace.course_id
      dispatch(regularActions.blackoutDatesSyncing())

      return BlackoutDatesApi.sync(course_id)
        .then(() => {
          const remainingCalendarEvents = BlackoutDatesApi.calendarEventsSync(
            blackoutDates,
            course_id
          )
          dispatch(regularActions.blackoutDatesSynced(remainingCalendarEvents))
        })
        .catch((error: Error) => {
          dispatch(regularActions.blackoutDatesSyncFailed())
          dispatch(uiActions.setCategoryError('blackout_dates', error?.toString()))
          throw error
        })
    }
  },
}

export const actions = {...regularActions, ...thunkActions}
export type BlackoutDatesAction = ActionsUnion<typeof regularActions>
