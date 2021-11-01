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

/*
 * The actions in this file should encapsulate state variables that only effect the UI.
 */

import {Action} from 'redux'
import {ThunkAction} from 'redux-thunk'

import {PacePlan, PlanContextTypes, ResponsiveSizes, StoreState} from '../types'
import {createAction, ActionsUnion} from '../shared/types'
import {pacePlanActions} from './pace_plans'

export enum Constants {
  START_AUTO_SAVING = 'UI/START_AUTO_SAVING',
  AUTO_SAVE_COMPLETED = 'UI/AUTO_SAVE_COMPLETED',
  SET_ERROR_MESSAGE = 'UI/SET_ERROR_MESSAGE',
  TOGGLE_DIVIDE_INTO_WEEKS = 'UI/TOGGLE_DIVIDE_INTO_WEEKS',
  TOGGLE_SHOW_PROJECTIONS = 'UI/TOGGLE_SHOW_PROJECTIONS',
  PUBLISH_PLAN_STARTED = 'UI/PUBLISH_PLAN_STARTED',
  PUBLISH_PLAN_FINISHED = 'UI/PUBLISH_PLAN_FINISHED',
  SET_SELECTED_PLAN_CONTEXT = 'UI/SET_SELECTED_PLAN_CONTEXT',
  SET_RESPONSIVE_SIZE = 'UI/SET_RESPONSIVE_SIZE',
  SHOW_LOADING_OVERLAY = 'UI/SHOW_LOADING_OVERLAY',
  HIDE_LOADING_OVERLAY = 'UI/HIDE_LOADING_OVERLAY',
  SET_EDITING_BLACKOUT_DATES = 'UI/SET_EDITING_BLACKOUT_DATES',
  SET_ADJUSTING_HARD_END_DATES_AFTER = 'UI/SET_ADJUSTING_HARD_END_DATES_AFTER'
}

/* Action creators */

export const regularActions = {
  startAutoSave: () => createAction(Constants.START_AUTO_SAVING),
  autoSaveCompleted: () => createAction(Constants.AUTO_SAVE_COMPLETED),
  setErrorMessage: (message: string) => createAction(Constants.SET_ERROR_MESSAGE, message),
  toggleDivideIntoWeeks: () => createAction(Constants.TOGGLE_DIVIDE_INTO_WEEKS),
  toggleShowProjections: () => createAction(Constants.TOGGLE_SHOW_PROJECTIONS),
  publishPlanStarted: () => createAction(Constants.PUBLISH_PLAN_STARTED),
  publishPlanFinished: () => createAction(Constants.PUBLISH_PLAN_FINISHED),
  showLoadingOverlay: (message: string) => createAction(Constants.SHOW_LOADING_OVERLAY, message),
  hideLoadingOverlay: () => createAction(Constants.HIDE_LOADING_OVERLAY),
  setEditingBlackoutDates: (editing: boolean) =>
    createAction(Constants.SET_EDITING_BLACKOUT_DATES, editing),
  setSelectedPlanContext: (
    contextType: PlanContextTypes,
    contextId: string,
    newSelectedPlan: PacePlan
  ) => createAction(Constants.SET_SELECTED_PLAN_CONTEXT, {contextType, contextId, newSelectedPlan}),
  setResponsiveSize: (responsiveSize: ResponsiveSizes) =>
    createAction(Constants.SET_RESPONSIVE_SIZE, responsiveSize),
  setAdjustingHardEndDatesAfter: (position: number | undefined) =>
    createAction(Constants.SET_ADJUSTING_HARD_END_DATES_AFTER, position)
}

export const thunkActions = {
  setSelectedPlanContext: (
    contextType: PlanContextTypes,
    contextId: string
  ): ThunkAction<void, StoreState, void, Action> => {
    // Switch to the other plan type, and load the exact plan we should switch to
    return dispatch => {
      const afterLoadActionCreator = (newSelectedPlan: PacePlan): SetSelectedPlanType => {
        return {
          type: Constants.SET_SELECTED_PLAN_CONTEXT,
          payload: {contextType, contextId, newSelectedPlan}
        }
      }
      dispatch(
        pacePlanActions.loadLatestPlanByContext(contextType, contextId, afterLoadActionCreator)
      )
    }
  }
}

export const actions = {...regularActions, ...thunkActions}

export type UIAction = ActionsUnion<typeof regularActions>
export type SetSelectedPlanType = ReturnType<typeof regularActions.setSelectedPlanContext>
