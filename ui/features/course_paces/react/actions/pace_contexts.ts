// @ts-nocheck
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
  PaceContextProgress,
  PaceContextsAsyncActionPayload,
  SortableColumn,
  StoreState,
} from '../types'
import {ThunkAction} from 'redux-thunk'
import {Action} from 'redux'
import {useScope as useI18nScope} from '@canvas/i18n'
import {CONTEXT_TYPE_MAP} from '../utils/utils'
import {coursePaceActions} from './course_paces'

const I18n = useI18nScope('pace_contexts_actions')

export interface FetchContextsActionParams {
  contextType: APIPaceContextTypes
  page?: number
  searchTerm?: string
  sortBy?: SortableColumn
  orderType?: OrderType
  contextIds?: string[]
  afterFetch?: (contexts) => void
}

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
  ADD_PUBLISHING_PACE = 'PACE_CONTEXTS/ADD_PUBLISHING_PACE',
  REMOVE_PUBLISHING_PACE = 'PACE_CONTEXTS/REMOVE_PUBLISHING_PACE',
  REPLACE_PACE_CONTEXTS = 'PACE_CONTEXTS/REPLACE_PACE_CONTEXTS',
  UPDATE_PUBLISHING_PACE = 'PACE_CONTEXTS/UPDATE_PUBLISHING_PACE',
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
  addPublishingPace: (paceContextProgress: PaceContextProgress) =>
    createAction(Constants.ADD_PUBLISHING_PACE, paceContextProgress),
  removePublishingPace: (paceContextProgress: PaceContextProgress) =>
    createAction(Constants.REMOVE_PUBLISHING_PACE, paceContextProgress),
  updatePublishingPaces: (paceContexts: PaceContextProgress[]) =>
    createAction(Constants.UPDATE_PUBLISHING_PACE, paceContexts),
  replacePaceContextPaces: (paceContexts: PaceContext[]) =>
    createAction(Constants.REPLACE_PACE_CONTEXTS, paceContexts),
}

const thunkActions = {
  fetchPaceContexts: ({
    contextType,
    page = 1,
    searchTerm = '',
    sortBy,
    orderType,
    contextIds,
    afterFetch,
  }: FetchContextsActionParams): ThunkAction<void, StoreState, void, Action> => {
    return async function fetchPaceContextsThunk(dispatch, getState) {
      dispatch(createAction(Constants.SET_LOADING, true))
      const {coursePace, paceContexts} = getState()
      const response = await Api.getPaceContexts({
        contextType,
        courseId: coursePace.course_id,
        page,
        entriesPerRequest: paceContexts.entriesPerRequest,
        searchTerm,
        sortBy,
        orderType,
        contextIds,
      })
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
      if (afterFetch) {
        afterFetch(response.pace_contexts)
      }
    }
  },
  syncPublishingPaces: (restart: boolean = false): ThunkAction<void, StoreState, void, Action> => {
    return (dispatch, getState) => {
      const {contextsPublishing, entries} = getState().paceContexts
      const loadedCodes = entries.map(({type, item_id}) => `${type}${item_id}`)
      const contextsToLoad = contextsPublishing.filter(
        ({pace_context, polling}) =>
          (restart || !polling) &&
          loadedCodes.includes(`${pace_context.type}${pace_context.item_id}`)
      )
      const updatedPaceContextsProgress = contextsToLoad.map(context => ({
        ...context,
        polling: true,
      }))
      contextsToLoad.forEach(({pace_context}) => {
        const contextType = CONTEXT_TYPE_MAP[pace_context.type]
        dispatch(
          coursePaceActions.loadLatestPaceByContext(contextType, pace_context.item_id, null, false)
        )
        dispatch(regularActions.updatePublishingPaces(updatedPaceContextsProgress))
      })
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
  refreshPublishedContext: (
    progressContextId: string
  ): ThunkAction<Promise<void>, StoreState, void, Action> => {
    return async (dispatch, getState) => {
      const {selectedContextType, contextsPublishing} = getState().paceContexts
      const {course_id: courseId} = getState().coursePace
      // We only need to refresh the pace context if the user is seeing the affected tab
      const contextToRefresh = contextsPublishing.find(
        context => context.progress_context_id === progressContextId
      )
      if (contextToRefresh) {
        const {pace_contexts: updatedPaceContexts} = await Api.getPaceContexts({
          contextType: selectedContextType,
          courseId,
          contextIds: [contextToRefresh.pace_context.item_id],
        })
        dispatch(regularActions.replacePaceContextPaces(updatedPaceContexts))
        dispatch(regularActions.removePublishingPace(contextToRefresh))
      }
    }
  },
}

export const paceContextsActions = {...regularActions, ...thunkActions}
export type PaceContextsAction = ActionsUnion<typeof thunkActions>
