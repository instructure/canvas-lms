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

export interface DeleteDeveloperKeyState {
  deleteDeveloperKeyPending: boolean
  deleteDeveloperKeySuccessful: boolean
  deleteDeveloperKeyError: unknown
}

const initialState: DeleteDeveloperKeyState = {
  deleteDeveloperKeyPending: false,
  deleteDeveloperKeySuccessful: false,
  deleteDeveloperKeyError: null,
}

export default makeReducer(initialState, {
  [ACTION_NAMES.DELETE_DEVELOPER_KEY_START]: (state, _action) => ({
    ...state,
    deleteDeveloperKeyPending: true,
    deleteDeveloperKeySuccessful: false,
    deleteDeveloperKeyError: null,
  }),
  [ACTION_NAMES.DELETE_DEVELOPER_KEY_SUCCESSFUL]: (state, _action) => ({
    ...state,
    deleteDeveloperKeyPending: false,
    deleteDeveloperKeySuccessful: true,
  }),
  [ACTION_NAMES.DELETE_DEVELOPER_KEY_FAILED]: (state, action) => ({
    ...state,
    deleteDeveloperKeyPending: false,
    deleteDeveloperKeyError: action.payload,
  }),
})
