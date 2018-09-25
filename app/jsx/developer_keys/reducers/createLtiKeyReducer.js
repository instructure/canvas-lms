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
  isLtiKey: false,
  customizing: false,
  toolConfiguration: {},
  validScopes: [],
  validPlacements: []
}

const ltiKeysHandlers = {
  [ACTION_NAMES.LTI_KEYS_SET_LTI_KEY]: (state, action) => ({
    ...state,
    isLtiKey: action.payload
  }),
  [ACTION_NAMES.LTI_KEYS_SET_CUSTOMIZING]: (state, action) => ({
    ...state,
    customizing: action.payload
  })
}

export default (state = initialState, action) => {
  if (ltiKeysHandlers[action.type]) {
    return ltiKeysHandlers[action.type](state, action)
  } else {
    return state
  }
}
