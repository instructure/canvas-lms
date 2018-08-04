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
import I18n from 'i18n!permissions'
import {createActions} from 'redux-actions'
import $ from 'jquery'
import {ALL_ROLES_VALUE} from './propTypes'

import * as apiClient from './apiClient'

import {showFlashError, showFlashSuccess} from '../shared/FlashAlert'

const types = [
  'ADD_NEW_ROLE',
  'ADD_TRAY_SAVING_FAIL',
  'ADD_TRAY_SAVING_START',
  'ADD_TRAY_SAVING_SUCCESS',
  'CLEAN_FOCUS',
  'DISPLAY_ADD_TRAY',
  'DISPLAY_PERMISSION_TRAY',
  'DISPLAY_ROLE_TRAY',
  'FILTER_DELETED_ROLE',
  'FILTER_NEW_ROLE',
  'FIX_FOCUS',
  'UPDATE_ROLE',
  'GET_PERMISSIONS_START',
  'GET_PERMISSIONS_SUCCESS',
  'HIDE_ALL_TRAYS',
  'PERMISSIONS_TAB_CHANGED',
  'UPDATE_PERMISSIONS',
  'UPDATE_PERMISSIONS_SEARCH',
  'UPDATE_ROLE_FILTERS',
  'UPDATE_SELECTED_ROLES',
  'DELETE_ROLE_SUCCESS'
]

const actions = createActions(...types)

actions.searchPermissions = function searchPermissions({permissionSearchString, contextType}) {
  return (dispatch, getState) => {
    dispatch(actions.updatePermissionsSearch({permissionSearchString, contextType}))
    const markedPermissions = getState().permissions
    const numDisplayedPermissions = markedPermissions.filter(p => p.displayed).length
    const message = I18n.t(
      {
        one: 'One permission found',
        other: '%{count} permissions found'
      },
      {count: numDisplayedPermissions}
    )
    $.screenReaderFlashMessageExclusive(message)
  }
}

actions.createNewRole = function(label, baseRole, context) {
  return (dispatch, getState) => {
    dispatch(actions.addTraySavingStart())
    const roleContext = context
    const selectedRoles = getState().selectedRoles
    apiClient
      .postNewRole(getState(), label, baseRole)
      .then(res => {
        const createdRole = res.data
        dispatch(actions.addNewRole(createdRole))
        dispatch(actions.addTraySavingSuccess())
        dispatch(actions.hideAllTrays())
        dispatch(actions.displayRoleTray({role: createdRole}))
        const newSelectedRoles = [...selectedRoles, createdRole]
        dispatch(
          actions.updateRoleFilters({selectedRoles: newSelectedRoles, contextType: roleContext})
        )
        dispatch(actions.filterNewRole(createdRole))
      })
      .catch(error => {
        dispatch(actions.addTraySavingFail())
        showFlashError(I18n.t('Failed to create new role'))(error)
      })
  }
}

actions.updateRoleName = function(id, label, baseType) {
  return (dispatch, getState) => {
    apiClient
      .updateRole(getState(), {id, label, base_role_type: baseType})
      .then(res => {
        dispatch(actions.updateRole(res.data))
      })
      .catch(error => {
        showFlashError(I18n.t('Failed to update role name'))(error)
      })
  }
}

actions.updateRoleNameAndBaseType = function(id, label, baseType) {
  return (dispatch, getState) => {
    apiClient
      .updateRole(getState(), {id, label, base_role_type: baseType})
      .then(res => {
        dispatch(actions.updateRole(res.data))
      })
      .catch(_ => {
        $.screenReaderFlashMessage(I18n.t('Failed to update role name'))
      })
  }
}

actions.setAndOpenRoleTray = function(role) {
  return dispatch => {
    dispatch(actions.hideAllTrays())
    dispatch(actions.displayRoleTray({role}))
  }
}

actions.setAndOpenAddTray = function() {
  return dispatch => {
    dispatch(actions.hideAllTrays())
    dispatch(actions.displayAddTray())
  }
}

actions.setAndOpenPermissionTray = function(permission) {
  return dispatch => {
    dispatch(actions.hideAllTrays())
    dispatch(actions.displayPermissionTray({permission}))
  }
}

actions.filterRoles = function filterRoles({selectedRoles, contextType}) {
  return (dispatch, _getState) => {
    dispatch(actions.updateSelectedRoles(selectedRoles))

    if (selectedRoles.length === 0 || selectedRoles[0].value !== ALL_ROLES_VALUE) {
      dispatch(actions.updateRoleFilters({selectedRoles, contextType}))
    }
  }
}

actions.filterRemovedRole = function filterRemovedRole(contextType) {
  return (dispatch, getState) => {
    dispatch(actions.updateRoleFilters({selectedRoles: getState().selectedRoles, contextType}))
  }
}

actions.tabChanged = function tabChanged(newContextType) {
  return (dispatch, _getState) => {
    dispatch(actions.permissionsTabChanged(newContextType))
  }
}

function changePermission(role, permissionName, enabled, locked, explicit) {
  return {
    ...role,
    permissions: {
      ...role.permissions,
      [permissionName]: {
        ...role.permissions[permissionName],
        enabled,
        locked,
        explicit
      }
    }
  }
}

actions.modifyPermissions = function modifyPermissions({
  name,
  id,
  enabled,
  locked,
  explicit,
  inTray
}) {
  return (dispatch, getState) => {
    const role = getState().roles.find(r => r.id === id)
    const updatedRole = changePermission(role, name, enabled, locked, explicit)
    apiClient
      .updateRole(getState(), updatedRole)
      .then(res => {
        const newRes = {...res.data, contextType: role.contextType, displayed: role.displayed}
        dispatch(actions.updatePermissions({role: newRes}))
        dispatch(actions.fixButtonFocus({permissionName: name, roleId: id, inTray}))
      })
      .catch(_error => {
        setTimeout(() => showFlashError(I18n.t('Failed to update permission'))(), 500)
      })
  }
}

actions.deleteRole = function(role, successCallback, failCallback) {
  return (dispatch, getState) => {
    const selectedRoles = getState().selectedRoles
    apiClient
      .deleteRole(getState().contextId, role)
      .then(_ => {
        successCallback()
        dispatch(actions.deleteRoleSuccess(role))
        dispatch(actions.filterDeletedRole({role, selectedRoles}))
        showFlashSuccess(I18n.t('Delete role %{label} succeeded', {label: role.label}))()
      })
      .catch(_error => {
        failCallback()
        setTimeout(
          () => showFlashError(I18n.t('Failed to delete role %{label}', {label: role.label}))(),
          500
        )
      })
  }
}

actions.updateBaseRole = function updateBaseRole(role, baseRole, onSuccess, onFail) {
  return (dispatch, getState) => {
    const state = getState()
    apiClient
      .updateBaseRole(state, role, baseRole)
      .then(res => {
        const newRes = {...res.data, contextType: role.contextType, displayed: role.displayed}
        dispatch(actions.updatePermissions({role: newRes}))
        onSuccess()
      })
      .catch(() => {
        onFail()
      })
  }
}

actions.fixButtonFocus = function fixButtonFocus({permissionName, roleId, inTray}) {
  const targetArea = inTray ? 'tray' : 'table'
  return actions.fixFocus({permissionName, roleId, targetArea})
}

const actionTypes = types.reduce((acc, type) => {
  acc[type] = type
  return acc
}, {})

export {actionTypes, actions as default}
