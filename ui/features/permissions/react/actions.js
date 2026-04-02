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
import {useScope as createI18nScope} from '@canvas/i18n'
import {createActions} from 'redux-actions'
import $ from 'jquery'
import {ALL_ROLES_VALUE} from '@canvas/permissions/react/propTypes'

import * as apiClient from './apiClient'

import {showFlashError, showFlashSuccess} from '@instructure/platform-alerts'

const I18n = createI18nScope('permissions')

const types = [
  'ADD_NEW_ROLE',
  'ADD_TRAY_SAVING_FAIL',
  'ADD_TRAY_SAVING_START',
  'ADD_TRAY_SAVING_SUCCESS',
  'API_COMPLETE',
  'API_PENDING',
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
  'DELETE_ROLE_SUCCESS',
]

const actions = createActions(...types)

actions.searchPermissions =
  ({permissionSearchString, contextType}) =>
  (dispatch, getState) => {
    dispatch(actions.updatePermissionsSearch({permissionSearchString, contextType}))
    const markedPermissions = getState().permissions
    const numDisplayedPermissions = markedPermissions.filter(p => p.displayed).length
    const message = I18n.t(
      {
        one: 'One permission found',
        other: '%{count} permissions found',
      },
      {count: numDisplayedPermissions},
    )
    $.screenReaderFlashMessageExclusive(message)
  }

actions.createNewRole = (label, baseRole, context) => async (dispatch, getState) => {
  dispatch(actions.addTraySavingStart())
  const selectedRoles = getState().selectedRoles
  try {
    const res = await apiClient.postNewRole(getState(), label, baseRole)
    const createdRole = res.json
    dispatch(actions.addNewRole(createdRole))
    dispatch(actions.addTraySavingSuccess())
    dispatch(actions.hideAllTrays())
    dispatch(actions.displayRoleTray({role: createdRole}))
    const newSelectedRoles = [...selectedRoles, createdRole]
    dispatch(actions.updateRoleFilters({selectedRoles: newSelectedRoles, contextType: context}))
    dispatch(actions.filterNewRole(createdRole))
  } catch (error) {
    dispatch(actions.addTraySavingFail())
    showFlashError(I18n.t('Failed to create new role'))(error)
  }
}

actions.updateRoleName = (id, label, baseType) => async (dispatch, getState) => {
  try {
    const res = await apiClient.updateRole(getState().contextId, id, {
      label,
      base_role_type: baseType,
    })
    dispatch(actions.updateRole(res.json))
  } catch (error) {
    showFlashError(I18n.t('Failed to update role name'))(error)
  }
}

actions.setAndOpenRoleTray = role => dispatch => {
  dispatch(actions.hideAllTrays())
  dispatch(actions.displayRoleTray({role}))
}

actions.setAndOpenAddTray = () => dispatch => {
  dispatch(actions.hideAllTrays())
  dispatch(actions.displayAddTray())
}

actions.setAndOpenPermissionTray = permission => dispatch => {
  dispatch(actions.hideAllTrays())
  dispatch(actions.displayPermissionTray({permission}))
}

actions.filterRoles =
  ({selectedRoles, contextType}) =>
  dispatch => {
    dispatch(actions.updateSelectedRoles(selectedRoles))

    if (selectedRoles.length === 0 || selectedRoles[0].value !== ALL_ROLES_VALUE) {
      dispatch(actions.updateRoleFilters({selectedRoles, contextType}))
    }
  }

actions.filterRemovedRole = contextType => (dispatch, getState) => {
  dispatch(actions.updateRoleFilters({selectedRoles: getState().selectedRoles, contextType}))
}

actions.tabChanged = newContextType => dispatch => {
  dispatch(actions.permissionsTabChanged(newContextType))
}

actions.modifyPermissions = arg => async (dispatch, getState) => {
  const state = getState()
  const {id, enabled, locked, explicit, applies_to_self, applies_to_descendants} = arg
  const role = state.roles.find(r => r.id === id)
  const permissionPayload = {
    enabled,
    locked,
    explicit,
    ...(state.isSiteAdmin && {
      applies_to_self,
      applies_to_descendants,
    }),
  }
  dispatch(actions.apiPending({id: arg.id, name: arg.name}))
  try {
    const res = await apiClient.updateRole(state.contextId, arg.id, {
      permissions: {[arg.name]: permissionPayload},
    })
    const newRes = {...res.json, contextType: role.contextType, displayed: role.displayed}
    dispatch(actions.updatePermissions({role: newRes}))
    dispatch(actions.fixButtonFocus({permissionName: arg.name, roleId: arg.id, inTray: arg.inTray}))
  } catch {
    setTimeout(() => showFlashError(I18n.t('Failed to update permission'))(), 500)
  } finally {
    dispatch(actions.apiComplete({id: arg.id, name: arg.name}))
  }
}

actions.deleteRole = (role, successCallback, failCallback) => async (dispatch, getState) => {
  const selectedRoles = getState().selectedRoles
  try {
    await apiClient.deleteRole(getState().contextId, role)
    successCallback()
    dispatch(actions.deleteRoleSuccess(role))
    dispatch(actions.filterDeletedRole({role, selectedRoles}))
    showFlashSuccess(I18n.t('Delete role %{label} succeeded', {label: role.label}))()
  } catch {
    failCallback()
    setTimeout(
      () => showFlashError(I18n.t('Failed to delete role %{label}', {label: role.label}))(),
      500,
    )
  }
}

actions.updateBaseRole = (role, baseRole, onSuccess, onFail) => async (dispatch, getState) => {
  const state = getState()
  try {
    // currently updateBaseRole does not return a Promise because it immediately
    // throws an error due to the endpoint not existing, but it might some day so
    // we'll retain this form. It's a no-op for now though.
    const res = await apiClient.updateBaseRole(state, role, baseRole)
    const newRes = {...res.json, contextType: role.contextType, displayed: role.displayed}
    dispatch(actions.updatePermissions({role: newRes}))
    onSuccess()
  } catch {
    onFail()
  }
}

actions.fixButtonFocus = ({permissionName, roleId, inTray}) => {
  const targetArea = inTray ? 'tray' : 'table'
  return actions.fixFocus({permissionName, roleId, targetArea})
}

const actionTypes = types.reduce((acc, type) => {
  acc[type] = type
  return acc
}, {})

export {actionTypes, actions as default}
