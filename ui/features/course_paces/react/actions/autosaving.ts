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

import _ from 'lodash'
import {Action, Dispatch} from 'redux'
import {ThunkAction} from 'redux-thunk'
import {deepEqual} from '@instructure/ui-utils'

import {getCoursePace} from '../reducers/course_paces'
import {StoreState, CoursePace} from '../types'
import * as coursePaceAPI from '../api/course_pace_api'
import {actions as uiActions} from './ui'
import {coursePaceActions} from './course_paces'

const updateCoursePace = (
  dispatch: Dispatch<Action>,
  getState: () => StoreState,
  paceBefore: CoursePace,
  shouldBlock: boolean,
  extraSaveParams = {}
) => {
  const pace = getCoursePace(getState())

  if (paceBefore.id && pace.id !== paceBefore.id) {
    dispatch(uiActions.autoSaveCompleted())
    return
  }

  const persisted = !!pace.id
  const method = persisted ? coursePaceAPI.update : coursePaceAPI.create

  // Whether we should update the pace to match the state presented by the backend.
  // We don't do this all the time, because it results in race conditions that cause
  // the ui to get out of sync.
  const updateAfterRequest =
    !persisted || shouldBlock || (pace.hard_end_dates && pace.context_type === 'Enrollment')

  return method(pace, extraSaveParams) // Hit the API to update
    .then(updatedPace => {
      if (updateAfterRequest) {
        dispatch(coursePaceActions.paceCreated(updatedPace))
      }

      if (shouldBlock) {
        dispatch(uiActions.hideLoadingOverlay())
      }
      dispatch(uiActions.autoSaveCompleted()) // Update the UI state
      dispatch(uiActions.clearCategoryError('autosaving'))
    })
    .catch(error => {
      if (shouldBlock) {
        dispatch(uiActions.hideLoadingOverlay())
      }
      dispatch(uiActions.autoSaveCompleted())
      dispatch(uiActions.setCategoryError('autosaving', error?.toString()))
      console.error(error) // eslint-disable-line no-console
    })
}

const debouncedUpdateCoursePace = _.debounce(updateCoursePace, 1000, {
  trailing: true,
  maxWait: 2000
})

/*
   Given any action, returns a new thunked action that applies the action and
   then initiates the autosave (including updating the UI)

   action - pass any redux action that should initiate an auto save
   debounce - whether the action should be immediately autosaved, or debounced
   shouldBlock - whether you want the pace updated after the autosave and for a loading icon to block user interaction
     until that is complete
   extraSaveParams - params that should be passed to the backend during the API call
*/
export const createAutoSavingAction = (
  action: any,
  debounce = true,
  shouldBlock = false,
  extraSaveParams = {}
): ThunkAction<void, StoreState, void, Action> => {
  return (dispatch, getState) => {
    if (shouldBlock) {
      dispatch(uiActions.showLoadingOverlay('Updating...'))
    }

    const paceBefore = getCoursePace(getState())
    dispatch(action) // Dispatch the original action

    // Don't autosave if no changes have occured
    if (deepEqual(paceBefore, getCoursePace(getState()))) {
      return
    }

    dispatch(uiActions.startAutoSave())

    if (debounce) {
      return debouncedUpdateCoursePace(dispatch, getState, paceBefore, shouldBlock, extraSaveParams)
    } else {
      return updateCoursePace(dispatch, getState, paceBefore, shouldBlock, extraSaveParams)
    }
  }
}
