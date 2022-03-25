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

import {Action} from 'redux'
import {ThunkAction} from 'redux-thunk'
import uuid from 'uuid/v1'

import {StoreState} from '../../types'
import {createAction, ActionsUnion, BlackoutDate} from '../types'
import * as BlackoutDatesApi from '../../api/blackout_dates_api'

export enum Constants {
  ADD_BLACKOUT_DATE = 'BLACKOUT_DATES/ADD',
  DELETE_BLACKOUT_DATE = 'BLACKOUT_DATES/DELETE',
  ADD_BACKEND_ID = 'BLACKOUT_DATES/ADD_BACKEND_ID',
  UPDATE_BLACKOUT_DATES = 'BLACKOUT_DATES/UPDATE'
}

/* Action Creators */

const regularActions = {
  addBackendId: (tempId: string, id: number | string) =>
    createAction(Constants.ADD_BACKEND_ID, {tempId, id}),
  deleteBlackoutDate: (id: number | string) => createAction(Constants.DELETE_BLACKOUT_DATE, id),
  addBlackoutDate: (blackoutDate: BlackoutDate) =>
    createAction(Constants.ADD_BLACKOUT_DATE, blackoutDate),
  updateBlackoutDates: (blackoutDates: BlackoutDate[]) =>
    createAction(Constants.UPDATE_BLACKOUT_DATES, blackoutDates)
}

const thunkActions = {
  addBlackoutDate: (blackoutDate: BlackoutDate): ThunkAction<void, StoreState, void, Action> => {
    return (dispatch, _getState) => {
      // Generate a tempId first that will be available to the api create callback closure,
      // that will allow us to update the correct blackout date after a save. This lets us
      // add the item immediately for the sake of UI, and then tie it to the correct ID laster
      // so it can be deleted.
      const tempId = uuid()
      const blackoutDateWithTempId: BlackoutDate = {
        ...blackoutDate,
        temp_id: tempId
      }

      dispatch(regularActions.addBlackoutDate(blackoutDateWithTempId))

      // BlackoutDatesApi.create(blackoutDateWithTempId)
      //   .then(newBlackoutDate => {
      //     if (!newBlackoutDate) throw new Error('Response body was empty')
      //     dispatch(actions.addBackendId(tempId, newBlackoutDate.id as number))
      //   })
      //   .catch(error => {
      //     console.error(error) // eslint-disable-line no-console
      //   })
    }
  },
  deleteBlackoutDate: (id: number | string): ThunkAction<void, StoreState, void, Action> => {
    return (dispatch, _getState) => {
      dispatch(regularActions.deleteBlackoutDate(id))
      BlackoutDatesApi.deleteBlackoutDate(id)
    }
  }
}

export const actions = {...regularActions, ...thunkActions}
export type BlackoutDatesAction = ActionsUnion<typeof regularActions>
