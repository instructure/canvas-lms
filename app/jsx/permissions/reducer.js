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
import activePermissionTrayReducer from './reducers/activePermissionTrayReducer'
import setFocusReducer from './reducers/setFocusReducer'

import {roleSortedInsert} from './helper/utils'

const permissions = handleActions(
  {
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
    },
    [actionTypes.PERMISSIONS_TAB_CHANGED]: (state, action) => {
      const newContextType = action.payload
      return state.map(permission => {
        const displayed = permission.contextType === newContextType
        return {...permission, displayed}
      })
    }
  },
  []
)

const roles = handleActions(
  {
    [actionTypes.UPDATE_ROLE_FILTERS]: (state, action) => {
      const {selectedRoles, contextType} = action.payload
      const selectedRolesObject = selectedRoles.reduce((obj, role) => {
        obj[role.id] = true // eslint-disable-line
        return obj
      }, {})
      return state.map(role => {
        // Make sure displayed is actually a boolean
        const displayed =
          role.contextType === contextType &&
          (selectedRoles.length === 0 || !!selectedRolesObject[role.id])
        return {...role, displayed}
      })
    },
    [actionTypes.PERMISSIONS_TAB_CHANGED]: (state, action) => {
      const newContextType = action.payload
      return state.map(role => {
        const displayed = role.contextType === newContextType
        return {...role, displayed}
      })
    },
    [actionTypes.UPDATE_PERMISSIONS]: (state, action) => {
      const {role} = action.payload
      return state.map(r => (r.id === role.id ? role : r))
    },
    [actionTypes.ADD_NEW_ROLE]: (state, action) => {
      const displayedRole = state.find(role => !!role.displayed)
      const currentContext = displayedRole.contextType
      const displayed = true
      const roleToAdd = {...action.payload, displayed, contextType: currentContext}
      return roleSortedInsert(state, roleToAdd)
    },
    [actionTypes.UPDATE_ROLE]: (state, action) =>
      state.map(r => (r.id === action.payload.id ? {...r, ...action.payload} : r)),
    [actionTypes.DELETE_ROLE_SUCCESS]: (state, action) =>
      state.filter(role => action.payload.id !== role.id)
  },
  []
)

export default combineReducers({
  activeRoleTray: activeRoleTrayReducer,
  activeAddTray: activeAddTrayReducer,
  activePermissionTray: activePermissionTrayReducer,
  contextId: (state, _action) => state || '',
  nextFocus: setFocusReducer,
  permissions,
  roles
})
