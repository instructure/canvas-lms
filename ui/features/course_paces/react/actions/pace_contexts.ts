/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import {createAction, ActionsUnion} from '../shared/types'
import * as Api from '../api/pace_contexts_api'
import {
  APIPaceContextTypes,
  OrderType,
  PaceContext,
  PaceContextsAsyncActionPayload,
  SortableColumn,
  StoreState,
} from '../types'
import {ThunkAction} from 'redux-thunk'
import {Action} from 'redux'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('pace_contexts_actions')

export enum Constants {
  SET_PACE_CONTEXTS = 'PACE_CONTEXTS/SET_PACE_CONTEXTS',
  SET_SELECTED_PACE_CONTEXT_TYPE = 'PACE_CONTEXTS/SET_SELECTED_PACE_CONTEXT_TYPE',
  SET_SELECTED_PACE_CONTEXT = 'PACE_CONTEXTS/SET_SELECTED_PACE_CONTEXT',
  SET_PAGE = 'PACE_CONTEXTS/SET_PAGE',
  SET_LOADING = 'PACE_CONTEXTS/SET_LOADING',
  SET_DEFAULT_PACE_LOADING = 'PACE_CONTEXTS/DEFAULT/SET_LOADING',
  SET_DEFAULT_PACE_CONTEXT = 'PACE_CONTEXTS/DEFAULT/SET_PACE_CONTEXT',
  SET_DEFAULT_PACE_CONTEXT_AS_SELECTED = 'PACE_CONTEXTS/DEFAULT/SET_PACE_CONTEXT_AS_SELECTED',
  SET_SEARCH_TERM = 'PACE_CONTEXTS/SET_SEARCH_TERM',
  SET_SORT_BY = 'PACE_CONTEXTS/SET_SORT_BY',
  SET_ORDER_TYPE = 'PACE_CONTEXTS/SET_ORDER_TYPE',
}

const regularActions = {
  setPage: (page: number) => createAction(Constants.SET_PAGE, page),
  setSelectedContextType: (paceContextType: APIPaceContextTypes) =>
    createAction(Constants.SET_SELECTED_PACE_CONTEXT_TYPE, paceContextType),
  setSelectedContext: (paceContext: PaceContext) =>
    createAction(Constants.SET_SELECTED_PACE_CONTEXT, paceContext),
  setDefaultPaceContextAsSelected: () =>
    createAction(Constants.SET_DEFAULT_PACE_CONTEXT_AS_SELECTED),
  setSearchTerm: (searchTerm: string) => createAction(Constants.SET_SEARCH_TERM, searchTerm),
  setSortBy: (sortBy: SortableColumn) => createAction(Constants.SET_SORT_BY, sortBy),
  setOrderType: (orderType: OrderType) => createAction(Constants.SET_ORDER_TYPE, orderType),
}

const thunkActions = {
  fetchPaceContexts: (
    contextType: APIPaceContextTypes,
    page: number = 1,
    searchTerm: string = '',
    sortBy?: SortableColumn,
    orderType?: OrderType
  ): ThunkAction<void, StoreState, void, Action> => {
    return async (dispatch, getState) => {
      dispatch(createAction(Constants.SET_LOADING, true))
      const {coursePace, paceContexts} = getState()
      const response = await Api.getPaceContexts(
        coursePace.course_id,
        contextType,
        page,
        paceContexts.entriesPerRequest,
        searchTerm,
        sortBy,
        orderType
      )
      if (!response?.pace_contexts) throw new Error(I18n.t('Response body was empty'))
      dispatch(
        createAction<Constants, PaceContextsAsyncActionPayload>(Constants.SET_PACE_CONTEXTS, {
          result: response,
          page,
          searchTerm,
          sortBy,
          orderType,
        })
      )
    }
  },
  fetchDefaultPaceContext: (): ThunkAction<void, StoreState, void, Action> => {
    return async (dispatch, getState) => {
      dispatch(createAction(Constants.SET_DEFAULT_PACE_LOADING, true))
      const {coursePace} = getState()
      const response = await Api.getDefaultPaceContext(coursePace.course_id)
      dispatch(
        createAction<Constants, PaceContextsAsyncActionPayload>(
          Constants.SET_DEFAULT_PACE_CONTEXT,
          {result: response}
        )
      )
    }
  },
}

export const paceContextsActions = {...regularActions, ...thunkActions}
export type PaceContextsAction = ActionsUnion<typeof thunkActions>
