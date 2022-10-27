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

import {PaceContextsState} from '../types'
import {Constants as PaceContextsConstants} from '../actions/pace_contexts'

export const paceContextsInitialState: PaceContextsState = {
  selectedContextType: 'section',
  entries: [],
  pageCount: 1,
  page: 1,
  entriesPerRequest: 10,
  isLoading: true,
  defaultPaceContext: null,
  isLoadingDefault: false,
}

export const paceContextsReducer = (
  state = paceContextsInitialState,
  action
): PaceContextsState => {
  switch (action.type) {
    case PaceContextsConstants.SET_PACE_CONTEXTS: {
      const pageCount = Math.ceil(action.payload.result.total_entries / state.entriesPerRequest)
      return {
        ...state,
        entries: action.payload.result.pace_contexts,
        page: action.payload.page,
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
    case PaceContextsConstants.SET_DEFAULT_PACE_CONTEXT:
      return {
        ...state,
        defaultPaceContext: action.payload.result,
        isLoadingDefault: false,
      }
    default:
      return state
  }
}
