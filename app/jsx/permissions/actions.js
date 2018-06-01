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
import $ from 'jquery'
import I18n from 'i18n!permissions'
import {createActions} from 'redux-actions'

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
  'FIX_FOCUS',
  'UPDATE_ROLE',
  'GET_PERMISSIONS_START',
  'GET_PERMISSIONS_SUCCESS',
  'HIDE_ALL_TRAYS',
  'PERMISSIONS_TAB_CHANGED',
  'UPDATE_PERMISSIONS',
  'UPDATE_PERMISSIONS_SEARCH',
  'UPDATE_ROLE_FILTERS'
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

actions.createNewRole = function(label, baseRole) {
  return (dispatch, getState) => {
    dispatch(actions.addTraySavingStart())
    apiClient
      .postNewRole(getState(), label, baseRole)
      .then(res => {
        const createdRole = res.data
        dispatch(actions.addNewRole(createdRole))
        dispatch(actions.addTraySavingSuccess())
        dispatch(actions.hideAllTrays())
        dispatch(actions.displayRoleTray({role: createdRole}))
        showFlashSuccess(I18n.t('Successfully created new role'))()
      })
      .catch(_error => {
        dispatch(actions.addTraySavingFail())
        showFlashError(I18n.t('Failed to create new role'))()
      })
  }
}

actions.updateRoleNameAndBaseType = function(id, label, baseType) {
  return (dispatch, getState) => {
    apiClient
      .updateRole(getState(), {id, label, base_role_type: baseType})
      .then(res => {
        $.screenReaderFlashMessage(I18n.t('Successfully updated role name'))
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
    dispatch(actions.updateRoleFilters({selectedRoles, contextType}))
  }
}

actions.tabChanged = function tabChanged(newContextType) {
  return (dispatch, _getState) => {
    dispatch(actions.permissionsTabChanged(newContextType))
  }
}

actions.modifyPermissions = function modifyPermissions(
  permissionName,
  courseRoleId,
  enabled,
  locked
) {
  return dispatch => {
    dispatch(actions.updatePermissions({permissionName, courseRoleId, enabled, locked}))
    dispatch(actions.fixFocus({permissionName, courseRoleId}))
  }
}

const actionTypes = types.reduce((acc, type) => {
  acc[type] = type
  return acc
}, {})

export {actionTypes, actions as default}
