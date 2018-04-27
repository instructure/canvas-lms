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

import { combineReducers } from 'redux'
import { handleActions } from 'redux-actions'
import { actionTypes } from './actions'

const isLoadingPermissions = handleActions({
  [actionTypes.GET_PERMISSIONS_START]: (_state, _action) => true,
  [actionTypes.GET_PERMISSIONS_SUCCESS]: (_state, _action) => false
}, false)

const hasLoadedPermissions = handleActions({
  [actionTypes.GET_PERMISSIONS_SUCCESS]: (_state, _action) => true,
}, false)

const permissions = handleActions({
  // TODO for some reason the data passed in isn't already being stored in
  // the "payload" field -- figure out what is going on
  [actionTypes.GET_PERMISSIONS_SUCCESS]: (state, action) => Object.keys(action.payload)
}, [])


export default combineReducers({
  isLoadingPermissions,
  hasLoadedPermissions,
  permissions,
  contextId: (state, _action) => (state || "")
})
