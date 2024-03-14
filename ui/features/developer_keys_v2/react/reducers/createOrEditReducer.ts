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

import type {DeveloperKey} from '../../model/api/DeveloperKey'
import ACTION_NAMES from '../actions/developerKeysActions'
import {makeReducer} from './makeReducer'

export interface DeveloperKeyCreateOrEditState {
  developerKeyModalOpen: boolean
  developerKeyCreateOrEditSuccessful: boolean
  developerKeyCreateOrEditFailed: boolean
  developerKeyCreateOrEditPending: boolean
  developerKey?: DeveloperKey
  editing: boolean
  isLtiKey?: boolean
}

const initialState: DeveloperKeyCreateOrEditState = {
  developerKeyModalOpen: false,
  developerKeyCreateOrEditSuccessful: false,
  developerKeyCreateOrEditFailed: false,
  developerKeyCreateOrEditPending: false,
  developerKey: undefined,
  editing: false,
}

export default makeReducer(initialState, {
  [ACTION_NAMES.DEVELOPER_KEYS_MODAL_OPEN]: state => ({
    ...state,
    developerKeyModalOpen: true,
  }),
  [ACTION_NAMES.DEVELOPER_KEYS_MODAL_CLOSE]: state => ({
    ...state,
    developerKeyModalOpen: false,
  }),
  [ACTION_NAMES.CREATE_OR_EDIT_DEVELOPER_KEY_START]: state => ({
    ...state,
    developerKeyCreateOrEditSuccessful: false,
    developerKeyCreateOrEditFailed: false,
    developerKeyCreateOrEditPending: true,
  }),
  [ACTION_NAMES.CREATE_OR_EDIT_DEVELOPER_KEY_SUCCESSFUL]: state => ({
    ...state,
    developerKeyCreateOrEditSuccessful: true,
    developerKeyCreateOrEditFailed: false,
    developerKeyCreateOrEditPending: false,
  }),
  [ACTION_NAMES.CREATE_OR_EDIT_DEVELOPER_KEY_FAILED]: state => ({
    ...state,
    developerKeyCreateOrEditSuccessful: false,
    developerKeyCreateOrEditFailed: true,
    developerKeyCreateOrEditPending: false,
  }),
  [ACTION_NAMES.SET_EDITING_DEVELOPER_KEY]: (state, action) => ({
    ...state,
    developerKey: action.payload,
    editing: !!action.payload,
  }),
  [ACTION_NAMES.RESET_LTI_STATE]: state => ({
    ...state,
    isLtiKey: false,
  }),
  [ACTION_NAMES.LTI_KEYS_SET_LTI_KEY]: (state, action) => ({
    ...state,
    isLtiKey: action.payload,
  }),
})
