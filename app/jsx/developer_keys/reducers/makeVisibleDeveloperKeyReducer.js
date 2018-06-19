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
  makeVisibleDeveloperKeyPending: false,
  makeVisibleDeveloperKeySuccessful: false,
  makeVisibleDeveloperKeyError: null,
}

const developerKeysHandlers = {
  [ACTION_NAMES.MAKE_VISIBLE_DEVELOPER_KEY_START]: (state, _action) => ({
    ...state,
    makeVisibleDeveloperKeyPending: true,
    makeVisibleDeveloperKeySuccessful: false,
    makeVisibleDeveloperKeyError: null
  }),
  [ACTION_NAMES.MAKE_VISIBLE_DEVELOPER_KEY_SUCCESSFUL]: (state, _action) => ({
    ...state,
    makeVisibleDeveloperKeyPending: false,
    makeVisibleDeveloperKeySuccessful: true,
  }),
  [ACTION_NAMES.MAKE_VISIBLE_DEVELOPER_KEY_FAILED]: (state, action) => ({
    ...state,
    makeVisibleDeveloperKeyPending: false,
    makeVisibleDeveloperKeyError: action.payload
  }),
};

export default (state = initialState, action) => {
  if (developerKeysHandlers[action.type]) {
    return developerKeysHandlers[action.type](state, action)
  } else {
    return state
  }
}
