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
  developerKeyModalOpen: false,
  developerKeyCreateOrEditSuccessful: false,
  developerKeyCreateOrEditFailed: false,
  developerKeyCreateOrEditPending: false,
  developerKey: undefined
}

const developerKeysHandlers = {
  [ACTION_NAMES.DEVELOPER_KEYS_MODAL_OPEN]: (state) => ({
    ...state,
    developerKeyModalOpen: true
  }),
  [ACTION_NAMES.DEVELOPER_KEYS_MODAL_CLOSE]: (state) => ({
    ...state,
    developerKeyModalOpen: false
  }),
  [ACTION_NAMES.CREATE_OR_EDIT_DEVELOPER_KEY_START]: (state) => ({
    ...state,
    developerKeyCreateOrEditSuccessful: false,
    developerKeyCreateOrEditFailed: false,
    developerKeyCreateOrEditPending: true
  }),
  [ACTION_NAMES.CREATE_OR_EDIT_DEVELOPER_KEY_SUCCESSFUL]: (state) => ({
    ...state,
    developerKeyCreateOrEditSuccessful: true,
    developerKeyCreateOrEditFailed: false,
    developerKeyCreateOrEditPending: false
  }),
  [ACTION_NAMES.CREATE_OR_EDIT_DEVELOPER_KEY_FAILED]: (state) => ({
    ...state,
    developerKeyCreateOrEditSuccessful: false,
    developerKeyCreateOrEditFailed: true,
    developerKeyCreateOrEditPending: false
  }),
  [ACTION_NAMES.SET_EDITING_DEVELOPER_KEY]: (state, action) => ({
    ...state,
    developerKey: action.payload
  })
};

export default (state = initialState, action) => {
  if (developerKeysHandlers[action.type]) {
    return developerKeysHandlers[action.type](state, action)
  } else {
    return state
  }
}
