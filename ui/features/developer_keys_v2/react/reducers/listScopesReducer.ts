/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import ACTION_NAMES from '../actions/developerKeysActions'
import {makeReducer} from './makeReducer'

export interface AvailableScope {
  controller: string
  action: string
  verb: string
  path: string
  scope: string
  resource: string
  resource_name: string
}

export interface ListScopesState {
  availableScopes: Record<string, AvailableScope>
  listDeveloperKeyScopesPending: boolean
  listDeveloperKeyScopesSuccessful: boolean
  listDeveloperKeyScopesError: unknown
  selectedScopes: string[]
}

const initialState: ListScopesState = {
  availableScopes: {},
  listDeveloperKeyScopesPending: false,
  listDeveloperKeyScopesSuccessful: false,
  listDeveloperKeyScopesError: undefined,
  selectedScopes: [],
}

export default makeReducer(initialState, {
  [ACTION_NAMES.LIST_DEVELOPER_KEY_SCOPES_START]: state => ({
    ...state,
    listDeveloperKeyScopesPending: true,
    listDeveloperKeyScopesSuccessful: false,
    listDeveloperKeyScopesError: undefined,
  }),
  [ACTION_NAMES.LIST_DEVELOPER_KEY_SCOPES_SUCCESSFUL]: (state, action) => ({
    ...state,
    availableScopes: action.payload || state.availableScopes,
    listDeveloperKeyScopesPending: false,
    listDeveloperKeyScopesSuccessful: true,
    listDeveloperKeyScopesError: undefined,
  }),
  [ACTION_NAMES.LIST_DEVELOPER_KEY_SCOPES_FAILED]: state => ({
    ...state,
    listDeveloperKeyScopesSuccessful: false,
    listDeveloperKeyScopesPending: false,
    listDeveloperKeyScopesError: true,
  }),
  [ACTION_NAMES.LIST_DEVELOPER_KEY_SCOPES_SET]: (state, action) => {
    return {
      ...state,
      selectedScopes: action.payload,
    }
  },
})
