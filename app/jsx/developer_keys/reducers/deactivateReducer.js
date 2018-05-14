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

const initialState = {
  deactivateDeveloperKeyPending: false,
  deactivateDeveloperKeySuccessful: false,
  deactivateDeveloperKeyError: null,
}

const developerKeysHandlers = {
  [ACTION_NAMES.DEACTIVATE_DEVELOPER_KEY_START]: (state, _action) => ({
    ...state,
    deactivateDeveloperKeyPending: true,
    deactivateDeveloperKeySuccessful: false,
    deactivateDeveloperKeyError: null
  }),
  [ACTION_NAMES.DEACTIVATE_DEVELOPER_KEY_SUCCESSFUL]: (state, _action) => ({
    ...state,
    deactivateDeveloperKeyPending: false,
    deactivateDeveloperKeySuccessful: true,
  }),
  [ACTION_NAMES.DEACTIVATE_DEVELOPER_KEY_FAILED]: (state, action) => ({
    ...state,
    deactivateDeveloperKeyPending: false,
    deactivateDeveloperKeyError: action.payload
  }),
};

export default (state = initialState, action) => {
  if (developerKeysHandlers[action.type]) {
    return developerKeysHandlers[action.type](state, action)
  } else {
    return state
  }
}
