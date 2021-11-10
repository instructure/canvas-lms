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

import {getPacePlan} from '../reducers/pace_plans'
import {StoreState, PacePlan} from '../types'
import * as pacePlanAPI from '../api/pace_plan_api'
import {actions as uiActions} from './ui'
import {pacePlanActions} from './pace_plans'

const updatePacePlan = async (
  dispatch: Dispatch<Action>,
  getState: () => StoreState,
  planBefore: PacePlan,
  shouldBlock: boolean,
  extraSaveParams = {}
) => {
  await pacePlanAPI.waitForActionCompletion(() => getState().ui.planPublishing)

  const plan = getPacePlan(getState())

  if (planBefore.id && plan.id !== planBefore.id) {
    dispatch(uiActions.autoSaveCompleted())
    return
  }

  const persisted = !!plan.id
  const method = persisted ? pacePlanAPI.update : pacePlanAPI.create

  // Whether we should update the plan to match the state presented by the backend.
  // We don't do this all the time, because it results in race conditions that cause
  // the ui to get out of sync.
  const updateAfterRequest =
    !persisted || shouldBlock || (plan.hard_end_dates && plan.context_type === 'Enrollment')

  return method(plan, extraSaveParams) // Hit the API to update
    .then(updatedPlan => {
      if (updateAfterRequest) {
        dispatch(pacePlanActions.planCreated(updatedPlan))
      }

      if (shouldBlock) {
        dispatch(uiActions.hideLoadingOverlay())
      }
      dispatch(uiActions.autoSaveCompleted()) // Update the UI state
      dispatch(uiActions.setErrorMessage(''))
    })
    .catch(error => {
      if (shouldBlock) {
        dispatch(uiActions.hideLoadingOverlay())
      }
      dispatch(uiActions.autoSaveCompleted())
      dispatch(uiActions.setErrorMessage('There was an error saving your changes'))
      console.error(error) // eslint-disable-line no-console
    })
}

const debouncedUpdatePacePlan = _.debounce(updatePacePlan, 1000, {trailing: true, maxWait: 2000})

/*
   Given any action, returns a new thunked action that applies the action and
   then initiates the autosave (including updating the UI)

   action - pass any redux action that should initiate an auto save
   debounce - whether the action should be immediately autosaved, or debounced
   shouldBlock - whether you want the plan updated after the autosave and for a loading icon to block user interaction
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

    const planBefore = getPacePlan(getState())
    dispatch(action) // Dispatch the original action

    // Don't autosave if no changes have occured
    if (deepEqual(planBefore, getPacePlan(getState()))) {
      return
    }

    dispatch(uiActions.startAutoSave())

    if (debounce) {
      return debouncedUpdatePacePlan(dispatch, getState, planBefore, shouldBlock, extraSaveParams)
    } else {
      return updatePacePlan(dispatch, getState, planBefore, shouldBlock, extraSaveParams)
    }
  }
}
