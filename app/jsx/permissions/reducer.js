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

import {combineReducers} from 'redux'
import {handleActions} from 'redux-actions'
import {actionTypes} from './actions'

import activeRoleTrayReducer from './reducers/activeRoleTrayReducer'
import activeAddTrayReducer from './reducers/activeAddTrayReducer'

const permissions = handleActions(
  {
    // Note we may want to extract this out if it turns out to be
    // identical to what we do for role filtering
    [actionTypes.UPDATE_PERMISSIONS_SEARCH]: (state, action) => {
      const {permissionSearchString, contextType} = action.payload
      const regex = new RegExp(permissionSearchString, 'i')
      return state.map(permission => {
        if (permission.contextType === contextType && regex.test(permission.label)) {
          return {...permission, displayed: true}
        } else {
          return {...permission, displayed: false}
        }
      })
    }
  },
  []
)

export default combineReducers({
  contextId: (state, _action) => state || '',
  permissions,
  roles: (state, _action) => state || [],
  activeRoleTray: activeRoleTrayReducer,
  activeAddTray: activeAddTrayReducer
})
