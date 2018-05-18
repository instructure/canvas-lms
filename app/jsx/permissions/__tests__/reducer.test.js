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
import reducer from '../reducer'

const reduce = (action, state = {}) => reducer(state, action)

const permissions = [
  {
    permission_name: 'add_section',
    label: 'add section',
    contextType: COURSE,
    displayed: undefined
  },
  {
    permission_name: 'irrelevant1',
    label: 'add assignment',
    contectType: COURSE,
    displayed: undefined
  },
  {
    permission_name: 'ignore_this_add',
    label: 'delete everything',
    contextType: COURSE,
    displayed: undefined
  },
  {
    permission_name: 'ignore_because_account',
    label: 'add course',
    contextType: ACCOUNT,
    displayed: undefined
  }
]

it('UPDATE_PERMISSIONS_SEARCH filters properly', () => {
  const originalState = {contextId: 1, permissions, roles: []}
  const payload = {
    permissionSearchString: 'add',
    contextType: COURSE
  }
  const newState = reduce(actions.updatePermissionsSearch(payload), originalState)
  expect(newState.permissions).toHaveLength(originalState.permissions.length)
  for (let i = 0; i < originalState.permissions.length; i++) {
    // All fields other than displayed should stay unchanged
    expect(newState.permissions[i].permission_name).toEqual(
      originalState.permissions[i].permission_name
    )
    expect(newState.permissions[i].label).toEqual(originalState.permissions[i].label)
    expect(newState.permissions[i].contextType).toEqual(originalState.permissions[i].contextType)
    // Only the first permission should match the search
    if (i === 0) {
      expect(newState.permissions[i].displayed).toEqual(true)
    } else {
      expect(newState.permissions[i].displayed).toEqual(false)
    }
  }
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
  const originalState = {activeAddTray: false}
  const newState = reduce(actions.displayAddTray(), originalState)
  expect(newState.activeAddTray).toEqual(true)
})

it('HIDE_ALL_TRAYS sets the activeAddTray to false in the store', () => {
  const originalState = {activeAddTray: true}
  const newState = reduce(actions.hideAllTrays(), originalState)
  expect(newState.activeAddTray).toBeFalsy()
})

it('UPDATE_PERMISSIONS sets enabled in the store', () => {
  const originalState = {
    roles: [{id: '1', permissions: {become_user: {enabled: true, locked: true}}}]
  }
  const payload = {courseRoleId: '1', permissionName: 'become_user', enabled: false, locked: true}
  const newState = reduce(actions.updatePermissions(payload), originalState)
  const expectedState = {
    activeAddTray: null,
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
    activeAddTray: null,
    activeRoleTray: null,
    contextId: '',
    permissions: [],
    roles: [{id: '1', permissions: {become_user: {enabled: true, locked: false}}}]
  }
  expect(newState).toEqual(expectedState)
})
