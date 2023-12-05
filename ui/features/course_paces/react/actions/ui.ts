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

import type {Action} from 'redux'
import type {ThunkAction} from 'redux-thunk'

import type {CoursePace, PaceContextTypes, ResponsiveSizes, StoreState} from '../types'
import {createAction, type ActionsUnion} from '../shared/types'
import {coursePaceActions} from './course_paces'

export enum Constants {
  START_AUTO_SAVING = 'UI/START_AUTO_SAVING',
  AUTO_SAVE_COMPLETED = 'UI/AUTO_SAVE_COMPLETED',
  SET_CATEGORY_ERROR = 'UI/SET_CATEGORY_ERROR',
  CLEAR_CATEGORY_ERROR = 'UI/CLEAR_CATEGORY_ERROR',
  TOGGLE_DIVIDE_INTO_WEEKS = 'UI/TOGGLE_DIVIDE_INTO_WEEKS',
  TOGGLE_SHOW_PROJECTIONS = 'UI/TOGGLE_SHOW_PROJECTIONS',
  SET_SELECTED_PACE_CONTEXT = 'UI/SET_SELECTED_PACE_CONTEXT',
  SET_RESPONSIVE_SIZE = 'UI/SET_RESPONSIVE_SIZE',
  SET_OUTER_RESPONSIVE_SIZE = 'UI/SET_OUTER_RESPONSIVE_SIZE',
  SHOW_LOADING_OVERLAY = 'UI/SHOW_LOADING_OVERLAY',
  HIDE_LOADING_OVERLAY = 'UI/HIDE_LOADING_OVERLAY',
  SHOW_PACE_MODAL = 'UI/SHOW_PACE_MODAL',
  HIDE_PACE_MODAL = 'UI/HIDE_PACE_MODAL',
  START_SYNCING = 'UI/START_SYNCING',
  SYNCING_COMPLETED = 'UI/SYNCING_COMPLETED',
  SET_SELECTED_PACE_CONTEXT_TYPE = 'UI/SET_SELECTED_PACE_CONTEXT_TYPE',
  SET_BLUEPRINT_LOCK = 'COURSE_PACE/SET_BLUEPRINT_LOCK',
}

/* Action creators */

export const regularActions = {
  startAutoSave: () => createAction(Constants.START_AUTO_SAVING),
  autoSaveCompleted: () => createAction(Constants.AUTO_SAVE_COMPLETED),
  setCategoryError: (category: string, error?: string) =>
    createAction(Constants.SET_CATEGORY_ERROR, {category, error: error || ''}),
  clearCategoryError: (category: string) => createAction(Constants.CLEAR_CATEGORY_ERROR, category),
  showLoadingOverlay: (message: string) => createAction(Constants.SHOW_LOADING_OVERLAY, message),
  hideLoadingOverlay: () => createAction(Constants.HIDE_LOADING_OVERLAY),
  showPaceModal: (pace: CoursePace) => createAction(Constants.SHOW_PACE_MODAL, pace),
  hidePaceModal: () => createAction(Constants.HIDE_PACE_MODAL),
  setSelectedPaceContext: (
    contextType: PaceContextTypes,
    contextId: string,
    newSelectedPace: CoursePace
  ) => createAction(Constants.SET_SELECTED_PACE_CONTEXT, {contextType, contextId, newSelectedPace}),
  setResponsiveSize: (responsiveSize: ResponsiveSizes) =>
    createAction(Constants.SET_RESPONSIVE_SIZE, responsiveSize),
  setOuterResponsiveSize: (outerResponsiveSize: ResponsiveSizes) =>
    createAction(Constants.SET_OUTER_RESPONSIVE_SIZE, outerResponsiveSize),
  startSyncing: () => createAction(Constants.START_SYNCING),
  syncingCompleted: () => createAction(Constants.SYNCING_COMPLETED),
  setSelectedContextType: (selectedContextType: PaceContextTypes) =>
    createAction(Constants.SET_SELECTED_PACE_CONTEXT_TYPE, selectedContextType),
  setBlueprintLocked: (locked?: boolean) => createAction(Constants.SET_BLUEPRINT_LOCK, locked),
}

export const thunkActions = {
  setSelectedPaceContext: (
    contextType: PaceContextTypes,
    contextId: string
  ): ThunkAction<void, StoreState, void, Action> => {
    // Switch to the other pace type, and load the exact pace we should switch to
    return dispatch => {
      const afterLoadActionCreator = (newSelectedPace: CoursePace): SetSelectedPaceType => {
        return {
          type: Constants.SET_SELECTED_PACE_CONTEXT,
          payload: {contextType, contextId, newSelectedPace},
        }
      }
      dispatch(
        coursePaceActions.loadLatestPaceByContext(contextType, contextId, afterLoadActionCreator)
      )
    }
  },
}

export const actions = {...regularActions, ...thunkActions}

export type UIAction = ActionsUnion<typeof regularActions>
export type SetSelectedPaceType = ReturnType<typeof regularActions.setSelectedPaceContext>
