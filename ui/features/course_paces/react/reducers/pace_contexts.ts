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

import {
  PaceContext,
  PaceContextsAsyncActionPayload,
  PaceContextsApiResponse,
  PaceContextsState,
  StoreState,
  PaceContextProgress,
} from '../types'
import {Constants as PaceContextsConstants} from '../actions/pace_contexts'
import uniqBy from 'lodash/uniqBy'

const pacesPublishing: PaceContextProgress[] = window.ENV.PACES_PUBLISHING || []
const uniqPaces = uniqBy(pacesPublishing, 'progress_context_id').map(paceProgress => ({
  ...paceProgress,
  polling: false,
}))

export interface PaceProgress {
  paceId: string
  paceName: string
  contextCode: string
}

export const paceContextsInitialState: PaceContextsState = {
  selectedContextType: 'section',
  selectedContext: null,
  entries: [],
  pageCount: 1,
  page: 1,
  entriesPerRequest: 10,
  isLoading: true,
  defaultPaceContext: null,
  isLoadingDefault: false,
  searchTerm: '',
  sortBy: 'name',
  order: 'asc',
  contextsPublishing: uniqPaces,
}

export const getSelectedPaceContext = (state: StoreState): PaceContext | null =>
  state.paceContexts.selectedContext

export const paceContextsReducer = (
  state = paceContextsInitialState,
  action
): PaceContextsState => {
  switch (action.type) {
    case PaceContextsConstants.SET_PACE_CONTEXTS: {
      const payload: PaceContextsAsyncActionPayload = action.payload
      const payloadResult = payload.result as PaceContextsApiResponse
      const pageCount = Math.ceil(payloadResult.total_entries / state.entriesPerRequest)
      return {
        ...state,
        entries: payloadResult.pace_contexts,
        page: payload.page || 1,
        searchTerm: payload.searchTerm || '',
        sortBy: payload.sortBy!,
        order: payload.orderType!,
        isLoading: false,
        pageCount,
      }
    }
    case PaceContextsConstants.SET_PAGE:
      return {
        ...state,
        page: action.payload,
      }
    case PaceContextsConstants.SET_LOADING:
      return {
        ...state,
        isLoading: action.payload,
      }
    case PaceContextsConstants.SET_SELECTED_PACE_CONTEXT_TYPE:
      return {
        ...state,
        selectedContextType: action.payload,
      }
    case PaceContextsConstants.SET_DEFAULT_PACE_LOADING:
      return {
        ...state,
        isLoadingDefault: action.payload,
      }
    case PaceContextsConstants.SET_DEFAULT_PACE_CONTEXT: {
      const payload: PaceContextsAsyncActionPayload = action.payload
      return {
        ...state,
        defaultPaceContext: payload.result as PaceContext,
        isLoadingDefault: false,
      }
    }
    case PaceContextsConstants.SET_SELECTED_PACE_CONTEXT:
      return {
        ...state,
        selectedContext: action.payload,
      }
    case PaceContextsConstants.SET_DEFAULT_PACE_CONTEXT_AS_SELECTED:
      return {
        ...state,
        selectedContext: state.defaultPaceContext,
      }
    case PaceContextsConstants.SET_SEARCH_TERM:
      return {
        ...state,
        searchTerm: action.payload,
      }
    case PaceContextsConstants.SET_SORT_BY:
      return {
        ...state,
        sortBy: action.payload,
      }
    case PaceContextsConstants.SET_ORDER_TYPE:
      return {
        ...state,
        order: action.payload,
      }
    case PaceContextsConstants.ADD_PUBLISHING_PACE:
      return {
        ...state,
        contextsPublishing: [...state.contextsPublishing, action.payload],
      }
    case PaceContextsConstants.UPDATE_PUBLISHING_PACE: {
      const contextsPublishing = state.contextsPublishing.map(contextPublishing => {
        const newPublishingContext = action.payload.find(
          updatedContextPublishing =>
            contextPublishing.progress_context_id === updatedContextPublishing.progress_context_id
        )
        return newPublishingContext || contextPublishing
      })
      return {
        ...state,
        contextsPublishing,
      }
    }
    case PaceContextsConstants.REMOVE_PUBLISHING_PACE:
      return {
        ...state,
        contextsPublishing: state.contextsPublishing.filter(
          ({progress_context_id}) => action.payload.progress_context_id !== progress_context_id
        ),
      }
    case PaceContextsConstants.REPLACE_PACE_CONTEXTS: {
      const newPaceContexts = state.entries.map(paceContext => {
        const newPaceContext = action.payload.find(
          updatedPaceContext => paceContext.item_id === updatedPaceContext.item_id
        )
        return newPaceContext || paceContext
      })
      return {
        ...state,
        entries: newPaceContexts,
      }
    }
    default:
      return state
  }
}
