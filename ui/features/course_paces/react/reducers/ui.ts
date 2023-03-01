// @ts-nocheck
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
import {getCoursePaceType, getPacePublishing} from './course_paces'
import {getBlackoutDatesSyncing} from '../shared/reducers/blackout_dates'

export const initialState: UIState = {
  autoSaving: false,
  syncing: 0,
  errors: {},
  divideIntoWeeks: true,
  selectedContextType: 'Course',
  selectedContextId: window.ENV.COURSE?.id || '',
  loadingMessage: '',
  editingBlackoutDates: false,
  showLoadingOverlay: false,
  showPaceModal: false,
  responsiveSize: 'large',
  showProjections: true,
  blueprintLocked: window.ENV.MASTER_COURSE_DATA?.restricted_by_master_course,
}

/* Selectors */

export const getAutoSaving = (state: StoreState) => state.ui.autoSaving
// there is a window between when blackout dates finish updating and the pace
// begins publishing. use getSyncing to keep the ui consistent in the transition
export const getSyncing = (state: StoreState): boolean =>
  state.ui.syncing > 0 || getBlackoutDatesSyncing(state) || getPacePublishing(state)
export const getAnyActiveRequests = (state: StoreState): boolean => state.ui.syncing > 0
export const getErrors = (state: StoreState) => state.ui.errors
export const getCategoryError = (state: StoreState, category: string | string[]) => {
  if (Array.isArray(category)) {
    for (const cat in state.ui.errors) {
      if (category.includes(cat)) {
        return state.ui.errors[cat]
      }
    }
    return undefined
  }
  return state.ui.errors[category]
}
export const getDivideIntoWeeks = (state: StoreState) => state.ui.divideIntoWeeks
export const getSelectedContextType = (state: StoreState) => state.ui.selectedContextType
export const getSelectedContextId = (state: StoreState) => state.ui.selectedContextId
export const getLoadingMessage = (state: StoreState) => state.ui.loadingMessage
export const getResponsiveSize = (state: StoreState) => state.ui.responsiveSize
export const getOuterResponsiveSize = (state: StoreState) => state.ui.outerResponsiveSize
export const getShowLoadingOverlay = (state: StoreState) => state.ui.showLoadingOverlay
export const getShowPaceModal = (state: StoreState) => state.ui.showPaceModal
export const getEditingBlackoutDates = (state: StoreState) => state.ui.editingBlackoutDates
export const getIsSyncing = (state: StoreState) => state.ui.syncing
export const getBlueprintLocked = (state: StoreState) => state.ui.blueprintLocked

export const getShowProjections = createSelector(
  state => state.ui.showProjections,
  getCoursePaceType,
  (showProjections, coursePaceType) => showProjections || coursePaceType === 'Enrollment'
)

/* Reducers */

export default (state = initialState, action: UIAction): UIState => {
  switch (action.type) {
    case UIConstants.START_AUTO_SAVING:
      return {...state, autoSaving: true}
    case UIConstants.AUTO_SAVE_COMPLETED:
      return {...state, autoSaving: false}
    case UIConstants.START_SYNCING:
      return {...state, syncing: state.syncing + 1}
    case UIConstants.SYNCING_COMPLETED:
      return {...state, syncing: state.syncing > 0 ? state.syncing - 1 : state.syncing}
    case UIConstants.SET_CATEGORY_ERROR:
      return {...state, errors: {...state.errors, [action.payload.category]: action.payload.error}}
    case UIConstants.CLEAR_CATEGORY_ERROR: {
      const new_errors = {...state.errors}
      delete new_errors[action.payload]
      return {...state, errors: new_errors}
    }
    case UIConstants.TOGGLE_DIVIDE_INTO_WEEKS:
      return {...state, divideIntoWeeks: !state.divideIntoWeeks}
    case UIConstants.TOGGLE_SHOW_PROJECTIONS:
      return {...state, showProjections: !state.showProjections}
    case UIConstants.SET_SELECTED_PACE_CONTEXT:
      return {
        ...state,
        selectedContextType: action.payload.contextType,
        selectedContextId: action.payload.contextId,
      }
    case UIConstants.SET_RESPONSIVE_SIZE:
      return {...state, responsiveSize: action.payload}
    case UIConstants.SET_OUTER_RESPONSIVE_SIZE:
      return {...state, outerResponsiveSize: action.payload}
    case UIConstants.SHOW_LOADING_OVERLAY:
      return {...state, showLoadingOverlay: true, loadingMessage: action.payload}
    case UIConstants.HIDE_LOADING_OVERLAY:
      return {...state, showLoadingOverlay: false, loadingMessage: ''}
    case UIConstants.HIDE_PACE_MODAL:
      return {...state, showPaceModal: false}
    case UIConstants.SHOW_PACE_MODAL:
      return {...state, showPaceModal: true}
    case UIConstants.SET_SELECTED_PACE_CONTEXT_TYPE:
      return {...state, selectedContextType: action.payload}
    case UIConstants.SET_BLUEPRINT_LOCK:
      return {...state, blueprintLocked: action.payload}
    default:
      return state
  }
}
