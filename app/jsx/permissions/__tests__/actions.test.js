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
import moxios from 'moxios'

import actions from '../actions'

import {COURSE, ACCOUNT} from '../propTypes'
import {PERMISSIONS, ROLES} from './examples'
import {moxiosWait} from '../test-utils'

// This is needed for $.screenReaderFlashMessageExclusive to work.
// TODO: This is terrible, make it unterrible
import 'compiled/jquery.rails_flash_notifications' // eslint-disable-line

it('searchPermissions dispatches updatePermissionsSearch', () => {
  const state = {contextId: 1, permissions: PERMISSIONS, roles: []}
  const dispatchMock = jest.fn()
  actions.searchPermissions({permissionSearchString: 'add', contextType: COURSE})(
    dispatchMock,
    () => state
  )

  const expectedDispatch = {
    type: 'UPDATE_PERMISSIONS_SEARCH',
    payload: {
      permissionSearchString: 'add',
      contextType: COURSE
    }
  }

  expect(dispatchMock).toHaveBeenCalledTimes(1)
  expect(dispatchMock).toHaveBeenCalledWith(expectedDispatch)
})

it('searchPermissions announces when search is complete', () => {
  const state = {contextId: 1, permissions: PERMISSIONS, roles: []}
  const dispatchMock = jest.fn()
  const flashMock = jest.spyOn($, 'screenReaderFlashMessageExclusive')
  actions.searchPermissions({permissionSearchString: 'add', contextType: COURSE})(
    dispatchMock,
    () => state
  )

  expect(flashMock).toHaveBeenCalledTimes(1)
  expect(flashMock).toHaveBeenCalledWith('2 permissions found')
})

it('setAndOpenRoleTray dispatches hideAllTrays and dispalyRoleTray', () => {
  const dispatchMock = jest.fn()
  actions.setAndOpenRoleTray('banana')(dispatchMock, () => {})

  const expectedHideDispatch = {
    type: 'HIDE_ALL_TRAYS'
  }
  const expectedDisplayRoleDispatch = {
    type: 'DISPLAY_ROLE_TRAY',
    payload: {
      role: 'banana'
    }
  }

  expect(dispatchMock).toHaveBeenCalledTimes(2)
  expect(dispatchMock).toHaveBeenCalledWith(expectedHideDispatch)
  expect(dispatchMock).toHaveBeenCalledWith(expectedDisplayRoleDispatch)
})

it('setAndOpenAddTray dispatches hideAllTrays and displayAddTray', () => {
  const dispatchMock = jest.fn()
  actions.setAndOpenAddTray()(dispatchMock, () => {})
  const expectedHideDispatch = {
    type: 'HIDE_ALL_TRAYS'
  }
  const expectedDisplayAddDispatch = {
    type: 'DISPLAY_ADD_TRAY'
  }

  expect(dispatchMock).toHaveBeenCalledTimes(2)
  expect(dispatchMock).toHaveBeenCalledWith(expectedHideDispatch)
  expect(dispatchMock).toHaveBeenCalledWith(expectedDisplayAddDispatch)
})

it('setAndOpenPermissionTray dispatches hideAllTrays and dispalyPermissionTray', () => {
  const dispatchMock = jest.fn()
  actions.setAndOpenPermissionTray('banana')(dispatchMock, () => {})
  const expectedHideDispatch = {
    type: 'HIDE_ALL_TRAYS'
  }
  const expectedDisplayRoleDispatch = {
    type: 'DISPLAY_PERMISSION_TRAY',
    payload: {
      permission: 'banana'
    }
  }

  expect(dispatchMock).toHaveBeenCalledTimes(2)
  expect(dispatchMock).toHaveBeenCalledWith(expectedHideDispatch)
  expect(dispatchMock).toHaveBeenCalledWith(expectedDisplayRoleDispatch)
})

it('createNewRole dispatches addNewRole', () => {
  moxios.install()
  window.ENV = {}
  window.ENV.flashAlertTimeout = 5
  const mockDispatch = jest.fn()
  const state = {contextId: 1, permissions: PERMISSIONS, roles: []}
  const getState = () => state
  actions.createNewRole('steven', 'StudentRoll')(mockDispatch, getState)
  return moxiosWait(() => {
    const request = moxios.requests.mostRecent()
    request
      .respondWith({
        status: 200,
        response: {
          id: '9',
          role: 'steven',
          label: 'steven',
          base_role_type: 'StudentEnrollment',
          workflow_state: 'active'
        }
      })
      .then(() => {
        expect(mockDispatch).toHaveBeenCalledWith({
          type: 'ADD_NEW_ROLE',
          payload: {
            id: '9',
            role: 'steven',
            label: 'steven',
            base_role_type: 'StudentEnrollment',
            workflow_state: 'active'
          }
        })
        expect(mockDispatch).toHaveBeenCalledWith({
          type: 'DISPLAY_ROLE_TRAY',
          payload: {
            role: {
              base_role_type: 'StudentEnrollment',
              id: '9',
              label: 'steven',
              role: 'steven',
              workflow_state: 'active'
            }
          }
        })
        const expectedStartDispatch = {
          type: 'ADD_TRAY_SAVING_START'
        }
        const expectedDisplayAddSuccessDispatch = {
          type: 'ADD_TRAY_SAVING_SUCCESS'
        }

        const expectedHideDispatch = {
          type: 'HIDE_ALL_TRAYS'
        }

        expect(mockDispatch).toHaveBeenCalledTimes(5)
        expect(mockDispatch).toHaveBeenCalledWith(expectedStartDispatch)
        expect(mockDispatch).toHaveBeenCalledWith(expectedDisplayAddSuccessDispatch)
        expect(mockDispatch).toHaveBeenCalledWith(expectedHideDispatch)
      })
    moxios.uninstall()
  })
})

it('updateRoleNameAndBaseType dispatches updateRole', () => {
  moxios.install()
  window.ENV = {}
  window.ENV.flashAlertTimeout = 5
  const mockDispatch = jest.fn()
  const state = {contextId: 1, permissions: PERMISSIONS, roles: []}
  const getState = () => state
  actions.updateRoleNameAndBaseType('1', 'steven', 'StudentRoll')(mockDispatch, getState)
  return moxiosWait(() => {
    const request = moxios.requests.mostRecent()
    request
      .respondWith({
        status: 200,
        response: {
          id: '9',
          role: 'steven',
          label: 'steven',
          base_role_type: 'StudentEnrollment',
          workflow_state: 'active'
        }
      })
      .then(() => {
        expect(mockDispatch).toHaveBeenCalledWith({
          type: 'UPDATE_ROLE',
          payload: {
            id: '9',
            role: 'steven',
            label: 'steven',
            base_role_type: 'StudentEnrollment',
            workflow_state: 'active'
          }
        })
      })
    moxios.uninstall()
  })
})

it('createNewRole dispatches addTraySavingFail', () => {
  moxios.install()
  const mockDispatch = jest.fn()
  const state = {contextId: 1, permissions: PERMISSIONS, roles: []}
  const getState = () => state
  actions.createNewRole('steven', 'StudentRoll')(mockDispatch, getState)
  return moxiosWait(() => {
    const request = moxios.requests.mostRecent()
    request
      .respondWith({
        status: 400,
        response: {
          id: '9',
          role: 'steven',
          label: 'steven',
          base_role_type: 'StudentEnrollment',
          workflow_state: 'active'
        }
      })
      .then(() => {
        expect(mockDispatch).toHaveBeenCalledWith({
          type: 'ADD_TRAY_SAVING_FAIL'
        })
      })
    moxios.uninstall()
  })
})

it('modifyPermissions dispatches updatePermissions', () => {
  const state = ''
  const dispatchMock = jest.fn()
  actions.modifyPermissions('add', '1', true, true)(dispatchMock, () => state)

  const expectedUpdatePermsDispatch = {
    type: 'UPDATE_PERMISSIONS',
    payload: {
      permissionName: 'add',
      courseRoleId: '1',
      enabled: true,
      locked: true
    }
  }
  const expectedFixFocusDispatch = {
    type: 'FIX_FOCUS',
    payload: {
      permissionName: 'add',
      courseRoleId: '1'
    }
  }

  expect(dispatchMock).toHaveBeenCalledTimes(2)
  expect(dispatchMock).toHaveBeenCalledWith(expectedUpdatePermsDispatch)
  expect(dispatchMock).toHaveBeenCalledWith(expectedFixFocusDispatch)
})

it('filterRoles dispatches updateRoleFilters', () => {
  const state = {contextId: 1, permissions: PERMISSIONS, roles: ROLES}
  const dispatchMock = jest.fn()
  actions.filterRoles({selectedRoles: [ROLES[0]], contextType: COURSE})(dispatchMock, () => state)
  const expectedDispatch = {
    type: 'UPDATE_ROLE_FILTERS',
    payload: {
      selectedRoles: [ROLES[0]],
      contextType: COURSE
    }
  }

  expect(dispatchMock).toHaveBeenCalledTimes(1)
  expect(dispatchMock).toHaveBeenCalledWith(expectedDispatch)
})

it('tabChanged dispatches permissionsTabChanged', () => {
  const state = {contextId: 1, permissions: PERMISSIONS, roles: ROLES}
  const dispatchMock = jest.fn()
  actions.tabChanged(ACCOUNT)(dispatchMock, () => state)
  expect(dispatchMock).toHaveBeenCalledTimes(1)
  const expectedDispatch = {
    type: 'PERMISSIONS_TAB_CHANGED',
    payload: ACCOUNT
  }
  expect(dispatchMock).toHaveBeenCalledTimes(1)
  expect(dispatchMock).toHaveBeenCalledWith(expectedDispatch)
})
