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

import {createSelector} from 'reselect'

import {StoreState, UIState} from '../types'
import {Constants as UIConstants, UIAction} from '../actions/ui'
import {getPacePlanType} from './pace_plans'

export const initialState: UIState = {
  autoSaving: false,
  errorMessage: '',
  divideIntoWeeks: true,
  planPublishing: false,
  selectedContextType: 'Course',
  selectedContextId: window.ENV.COURSE?.id || '',
  loadingMessage: '',
  editingBlackoutDates: false,
  showLoadingOverlay: false,
  responsiveSize: 'large',
  showProjections: false,
  adjustingHardEndDatesAfter: undefined
}

/* Selectors */

export const getAutoSaving = (state: StoreState) => state.ui.autoSaving
export const getErrorMessage = (state: StoreState) => state.ui.errorMessage
export const getDivideIntoWeeks = (state: StoreState) => state.ui.divideIntoWeeks
export const getPlanPublishing = (state: StoreState) => state.ui.planPublishing
export const getSelectedContextType = (state: StoreState) => state.ui.selectedContextType
export const getSelectedContextId = (state: StoreState) => state.ui.selectedContextId
export const getLoadingMessage = (state: StoreState) => state.ui.loadingMessage
export const getResponsiveSize = (state: StoreState) => state.ui.responsiveSize
export const getShowLoadingOverlay = (state: StoreState) => state.ui.showLoadingOverlay
export const getEditingBlackoutDates = (state: StoreState) => state.ui.editingBlackoutDates
export const getAdjustingHardEndDatesAfter = (state: StoreState) =>
  state.ui.adjustingHardEndDatesAfter

export const getShowProjections = createSelector(
  state => state.ui.showProjections,
  getPacePlanType,
  (showProjections, pacePlanType) => showProjections || pacePlanType === 'Enrollment'
)

/* Reducers */

export default (state = initialState, action: UIAction): UIState => {
  switch (action.type) {
    case UIConstants.START_AUTO_SAVING:
      return {...state, autoSaving: true}
    case UIConstants.AUTO_SAVE_COMPLETED:
      return {...state, autoSaving: false, adjustingHardEndDatesAfter: undefined}
    case UIConstants.SET_ERROR_MESSAGE:
      return {...state, errorMessage: action.payload}
    case UIConstants.TOGGLE_DIVIDE_INTO_WEEKS:
      return {...state, divideIntoWeeks: !state.divideIntoWeeks}
    case UIConstants.TOGGLE_SHOW_PROJECTIONS:
      return {...state, showProjections: !state.showProjections}
    case UIConstants.PUBLISH_PLAN_STARTED:
      return {...state, planPublishing: true}
    case UIConstants.PUBLISH_PLAN_FINISHED:
      return {...state, planPublishing: false}
    case UIConstants.SET_SELECTED_PLAN_CONTEXT:
      return {
        ...state,
        selectedContextType: action.payload.contextType,
        selectedContextId: action.payload.contextId
      }
    case UIConstants.SET_RESPONSIVE_SIZE:
      return {...state, responsiveSize: action.payload}
    case UIConstants.SHOW_LOADING_OVERLAY:
      return {...state, showLoadingOverlay: true, loadingMessage: action.payload}
    case UIConstants.HIDE_LOADING_OVERLAY:
      return {...state, showLoadingOverlay: false, loadingMessage: ''}
    case UIConstants.SET_ADJUSTING_HARD_END_DATES_AFTER:
      return {...state, adjustingHardEndDatesAfter: action.payload}
    case UIConstants.SET_EDITING_BLACKOUT_DATES:
      return {...state, editingBlackoutDates: action.payload}
    default:
      return state
  }
}
