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
import moment from 'moment-timezone'

import {PacePlan, PlanContextTypes, StoreState, PublishOptions} from '../types'
import {createAction, ActionsUnion, BlackoutDate} from '../shared/types'
import {actions as uiActions} from './ui'
import {createAutoSavingAction} from './autosaving'
import * as DateHelpers from '../utils/date_stuff/date_helpers'
import * as Api from '../api/pace_plan_api'
import {getPacePlan} from '../reducers/pace_plans'

export enum Constants {
  SET_END_DATE = 'PACE_PLAN/SET_END_DATE',
  SET_START_DATE = 'PACE_PLAN/SET_START_DATE',
  PUBLISH_PLAN = 'PACE_PLAN/PUBLISH_PLAN',
  SET_PLAN_DAYS = 'PACE_PLAN/SET_PLAN_DAYS',
  TOGGLE_EXCLUDE_WEEKENDS = 'PACE_PLAN/TOGGLE_EXCLUDE_WEEKENDS',
  SET_PACE_PLAN = 'PACE_PLAN/SET_PACE_PLAN',
  PLAN_CREATED = 'PACE_PLAN/PLAN_CREATED',
  SET_UNPUBLISHED_CHANGES = 'PACE_PLAN/SET_UNPUBLISHED_CHANGES',
  TOGGLE_HARD_END_DATES = 'PACE_PLAN/TOGGLE_HARD_END_DATES',
  SET_LINKED_TO_PARENT = 'PACE_PLAN/SET_LINKED_TO_PARENT'
}

/* Action creators */

type LoadingAfterAction = (plan: PacePlan) => any
// Without this, we lose the ReturnType through our mapped ActionsUnion (because of setPlanDays), and the type just becomes any.
type SetEndDate = {type: Constants.SET_END_DATE; payload: string}

const regularActions = {
  setPacePlan: (plan: PacePlan) => createAction(Constants.SET_PACE_PLAN, plan),
  setStartDate: (date: string) => createAction(Constants.SET_START_DATE, date),
  setEndDate: (date: string): SetEndDate => createAction(Constants.SET_END_DATE, date),
  planCreated: (plan: PacePlan) => createAction(Constants.PLAN_CREATED, plan),
  toggleExcludeWeekends: () => createAction(Constants.TOGGLE_EXCLUDE_WEEKENDS),
  toggleHardEndDates: () => createAction(Constants.TOGGLE_HARD_END_DATES),
  setLinkedToParent: (linked: boolean) => createAction(Constants.SET_LINKED_TO_PARENT, linked),
  setUnpublishedChanges: (unpublishedChanges: boolean) =>
    createAction(Constants.SET_UNPUBLISHED_CHANGES, unpublishedChanges),
  setPlanDays: (planDays: number, plan: PacePlan, blackoutDates: BlackoutDate[]): SetEndDate => {
    // This calculates the new end date based off of the number of plan days specified and invokes
    // a setEndDate action. This would potentially be better with a thunked action, but I'm not
    // sure how to get that to work with a typesafe-actions createAction call.
    let newEndDate: string | undefined

    if (planDays === 0) {
      newEndDate = plan.start_date
    } else {
      // Subtract one day from planDays to make it include the start date
      const start = moment(plan.start_date).subtract(1, 'day')
      newEndDate = DateHelpers.addDays(start, planDays, plan.exclude_weekends, blackoutDates)
    }

    return pacePlanActions.setEndDate(newEndDate)
  }
}

const thunkActions = {
  publishPlan: (
    publishForOption: PublishOptions,
    publishForSectionIds: Array<string>,
    publishForEnrollmentIds: Array<string>
  ): ThunkAction<void, StoreState, void, Action> => {
    return (dispatch, getState) => {
      dispatch(uiActions.showLoadingOverlay('Publishing...'))
      dispatch(uiActions.publishPlanStarted())

      Api.waitForActionCompletion(() => getState().ui.autoSaving)

      return Api.publish(
        getState().pacePlan,
        publishForOption,
        publishForSectionIds,
        publishForEnrollmentIds
      )
        .then(response => {
          const newDraft: PacePlan = response.data.new_draft_plan
          dispatch(pacePlanActions.setPacePlan(newDraft))
          dispatch(uiActions.hideLoadingOverlay())
          dispatch(uiActions.publishPlanFinished())
        })
        .catch(error => {
          dispatch(uiActions.hideLoadingOverlay())
          dispatch(uiActions.publishPlanFinished())
          dispatch(uiActions.setErrorMessage('There was an error publishing your plan.'))
          console.error(error) // eslint-disable-line no-console
        })
    }
  },
  resetToLastPublished: (
    contextType: PlanContextTypes,
    contextId: string
  ): ThunkAction<void, StoreState, void, Action> => {
    return async (dispatch, getState) => {
      dispatch(uiActions.showLoadingOverlay('Loading...'))

      await Api.waitForActionCompletion(
        () => getState().ui.autoSaving || getState().ui.planPublishing
      )

      return Api.resetToLastPublished(contextType, contextId)
        .then(response => {
          const plan: PacePlan = response.data.pace_plan
          dispatch(pacePlanActions.setPacePlan(plan))
          dispatch(uiActions.hideLoadingOverlay())
        })
        .catch(error => {
          dispatch(uiActions.hideLoadingOverlay())
          dispatch(uiActions.setErrorMessage('There was an error resetting to the previous plan.'))
          console.error(error) // eslint-disable-line no-console
        })
    }
  },
  loadLatestPlanByContext: (
    contextType: PlanContextTypes,
    contextId: string,
    afterAction: LoadingAfterAction = pacePlanActions.setPacePlan
  ): ThunkAction<void, StoreState, void, Action> => {
    return async (dispatch, getState) => {
      dispatch(uiActions.showLoadingOverlay('Loading...'))

      await Api.waitForActionCompletion(() => getState().ui.autoSaving)

      return Api.getLatestDraftFor(contextType, contextId)
        .then(response => {
          const plan: PacePlan = response.data.pace_plan
          dispatch(afterAction(plan))
          dispatch(uiActions.hideLoadingOverlay())
        })
        .catch(error => {
          dispatch(uiActions.hideLoadingOverlay())
          dispatch(uiActions.setErrorMessage('There was an error loading the plan.'))
          console.error(error) // eslint-disable-line no-console
        })
    }
  },
  relinkToParentPlan: (): ThunkAction<void, StoreState, void, Action> => {
    return async (dispatch, getState) => {
      dispatch(uiActions.showLoadingOverlay('Relinking plans...'))

      await Api.waitForActionCompletion(() => getState().ui.autoSaving)

      return Api.relinkToParentPlan(getState().pacePlan.id)
        .then(response => {
          const plan: PacePlan = response.data.pace_plan
          dispatch(pacePlanActions.setPacePlan(plan))
          dispatch(uiActions.hideLoadingOverlay())
        })
        .catch(error => {
          dispatch(uiActions.hideLoadingOverlay())
          dispatch(uiActions.setErrorMessage('There was an error linking plan.'))
          console.error(error) // eslint-disable-line no-console
        })
    }
  }
}

export const autoSavingActions = {
  setStartDate: (date: string) => {
    return createAutoSavingAction(pacePlanActions.setStartDate(date))
  },
  setEndDate: (date: string) => {
    return createAutoSavingAction(pacePlanActions.setEndDate(date))
  },
  setPlanDays: (planDays: number, plan: PacePlan, blackoutDates: BlackoutDate[]) => {
    return createAutoSavingAction(pacePlanActions.setPlanDays(planDays, plan, blackoutDates))
  },
  toggleExcludeWeekends: (extraSaveParams = {}) => {
    return createAutoSavingAction(
      pacePlanActions.toggleExcludeWeekends(),
      true,
      false,
      extraSaveParams
    )
  },
  toggleHardEndDates: (): ThunkAction<void, StoreState, void, Action> => {
    return (dispatch, getState) => {
      const plan = getPacePlan(getState())
      // If we're an enrollment plan and we're setting hard end dates, we should block the UI until the backend
      // re-adjusts the assignment due dates
      const shouldWaitForSave = plan.context_type === 'Enrollment' && !plan.hard_end_dates
      dispatch(
        createAutoSavingAction(pacePlanActions.toggleHardEndDates(), true, shouldWaitForSave)
      )
    }
  }
}

export const pacePlanActions = {...regularActions, ...thunkActions}
export type PacePlanAction = ActionsUnion<typeof regularActions>
