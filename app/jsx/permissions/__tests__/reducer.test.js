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

import actions from '../actions'
import {COURSE, ACCOUNT} from '../propTypes'
import {PERMISSIONS, ROLES} from './examples'
import reducer from '../reducer'

const reduce = (action, state = {}) => reducer(state, action)

// Many actions should only ever result in the displayed field changing,
// so this is a convenient way of testing for this.
//
// It isn't great to have expects in these utility functions (it can make
// interpreting the failure message harder) but it avoids repeating this
// over and over.
const verifyPermissionsDidntChange = (oldPermissions, newPermissions) => {
  expect(newPermissions).toHaveLength(oldPermissions.length)
  for (let i = 0; i < newPermissions.length; ++i) {
    expect(newPermissions.permission_name).toEqual(oldPermissions.permission_name)
    expect(newPermissions.label).toEqual(newPermissions.label)
    expect(newPermissions.contextType).toEqual(oldPermissions.contextType)
  }
}

const verifyRolesDidntChange = (newRoles, oldRoles) => {
  expect(newRoles).toHaveLength(oldRoles.length)
  for (let i = 0; i < newRoles.length; ++i) {
    expect(newRoles[i].id).toEqual(oldRoles[i].id)
    expect(newRoles[i].label).toEqual(oldRoles[i].label)
    expect(newRoles[i].base_role_type).toEqual(oldRoles[i].base_role_type)
    expect(newRoles[i].contextType).toEqual(oldRoles[i].contextType)
  }
}

// Verifies that only the indicies in trueIndices in checkDisplayed are set to true
const checkDisplayed = (arr, trueIndices) => {
  const indexSet = new Set(trueIndices)
  for (let i = 0; i < arr.length; ++i) {
    if (indexSet.has(i)) {
      expect(arr[i].displayed).toEqual(true)
    } else {
      expect(arr[i].displayed).toEqual(false)
    }
  }
}

it('UPDATE_PERMISSIONS_SEARCH filters properly', () => {
  const originalState = {contextId: 1, permissions: PERMISSIONS, roles: ROLES}
  const payload = {
    permissionSearchString: 'add',
    contextType: COURSE
  }
  const newState = reduce(actions.updatePermissionsSearch(payload), originalState)
  verifyPermissionsDidntChange(originalState.permissions, newState.permissions)
  verifyRolesDidntChange(originalState.roles, newState.roles)
  checkDisplayed(newState.permissions, [0])
})

it('PERMISSIONS_TAB_CHANGED switches tabs', () => {
  const originalState = {contextId: 1, permissions: PERMISSIONS, roles: ROLES}
  const payload = ACCOUNT
  const newState = reduce(actions.permissionsTabChanged(payload), originalState)
  verifyPermissionsDidntChange(originalState.permissions, newState.permissions)
  verifyRolesDidntChange(originalState.roles, newState.roles)
  checkDisplayed(newState.permissions, [2, 3])
  checkDisplayed(newState.roles, [2, 3])
})

it('UPDATE_ROLE_FILTER allows everything in correct type on an empty filter', () => {
  const originalState = {contextId: 1, permissions: PERMISSIONS, roles: ROLES}
  const payload = {
    selectedRoles: [],
    contextType: ACCOUNT
  }
  const newState = reduce(actions.updateRoleFilters(payload), originalState)
  verifyPermissionsDidntChange(originalState.permissions, newState.permissions)
  verifyRolesDidntChange(originalState.roles, newState.roles)
  checkDisplayed(newState.roles, [2, 3])
})

it('UPDATE_ROLE_FILTER filters properly', () => {
  const originalState = {contextId: 1, permissions: PERMISSIONS, roles: ROLES}
  const payload = {
    selectedRoles: [
      {
        id: 2,
        label: 'Course Sub-Admin',
        base_role_type: 'Course Admin',
        contextType: COURSE,
        displayed: true
      }
    ],
    contextType: COURSE
  }
  const newState = reduce(actions.updateRoleFilters(payload), originalState)
  verifyPermissionsDidntChange(originalState.permissions, newState.permissions)
  verifyRolesDidntChange(originalState.roles, newState.roles)
  checkDisplayed(newState.roles, [1])
})

it('DISPLAY_ROLE_TRAY sets the activeRoleTray in the store', () => {
  const originalState = {activeRoleTray: null}
  const payload = {role: 'newRoleSim'}
  const newState = reduce(actions.displayRoleTray(payload), originalState)
  expect(newState.activeRoleTray).toEqual(payload)
})

it('HIDE_ALL_TRAYS sets the activeRoleTray in the store', () => {
  const originalState = {activeRoleTray: {role: 'banana'}}
  const newState = reduce(actions.hideAllTrays(), originalState)
  expect(newState.activeRoleTray).toBeNull()
})

it('DISPLAY_ADD_TRAY sets the activeAddTray in the store', () => {
  const originalState = {
    activeAddTray: {
      show: false,
      loading: false
    }
  }
  const newState = reduce(actions.displayAddTray(), originalState)
  expect(newState.activeAddTray).toEqual({
    show: true,
    loading: false
  })
})

it('HIDE_ALL_TRAYS sets the activeAddTray to false in the store', () => {
  const originalState = {
    activeAddTray: {
      show: true,
      loading: false
    }
  }
  const newState = reduce(actions.hideAllTrays(), originalState)
  expect(newState.activeAddTray).toEqual({
    show: false,
    loading: false
  })
})

it('ADD_TRAY_SAVING_START sets the activeAddTray in the store', () => {
  const originalState = {
    activeAddTray: {
      show: false,
      loading: true
    }
  }
  const newState = reduce(actions.addTraySavingStart(), originalState)
  expect(newState.activeAddTray).toEqual({
    show: false,
    loading: true
  })
})

it('ADD_TRAY_SAVING_SUCCESS sets the activeAddTray to false in the store', () => {
  const originalState = {
    activeAddTray: {
      show: true,
      loading: true
    }
  }
  const newState = reduce(actions.addTraySavingSuccess(), originalState)
  expect(newState.activeAddTray).toEqual({
    show: true,
    loading: false
  })
})

it('ADD_TRAY_SAVING_FAIL sets the activeAddTray to false in the store', () => {
  const originalState = {
    activeAddTray: {
      show: true,
      loading: true
    }
  }
  const newState = reduce(actions.addTraySavingFail(), originalState)
  expect(newState.activeAddTray).toEqual({
    show: true,
    loading: false
  })
})

it('UPDATE_PERMISSIONS sets enabled in the store', () => {
  const originalState = {
    roles: [{id: '1', permissions: {become_user: {enabled: true, locked: true}}}]
  }
  const payload = {courseRoleId: '1', permissionName: 'become_user', enabled: false, locked: true}
  const newState = reduce(actions.updatePermissions(payload), originalState)
  const expectedState = {
    activeAddTray: {
      show: false,
      loading: false
    },
    activeRoleTray: null,
    contextId: '',
    permissions: [],
    roles: [{id: '1', permissions: {become_user: {enabled: false, locked: true}}}]
  }
  expect(newState).toEqual(expectedState)
})

it('UPDATE_PERMISSIONS sets locked in the store', () => {
  const originalState = {
    roles: [{id: '1', permissions: {become_user: {enabled: true, locked: true}}}]
  }
  const payload = {courseRoleId: '1', permissionName: 'become_user', enabled: true, locked: false}
  const newState = reduce(actions.updatePermissions(payload), originalState)
  const expectedState = {
    activeAddTray: {
      show: false,
      loading: false
    },
    activeRoleTray: null,
    contextId: '',
    permissions: [],
    roles: [{id: '1', permissions: {become_user: {enabled: true, locked: false}}}]
  }
  expect(newState).toEqual(expectedState)
})
