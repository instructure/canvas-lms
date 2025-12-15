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
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import {waitFor} from '@testing-library/react'
import fakeENV from '@canvas/test-utils/fakeENV'

import actions from '../actions'

import {COURSE, ACCOUNT} from '@canvas/permissions/react/propTypes'
import {PERMISSIONS, ROLES} from './examples'

// This is needed for $.screenReaderFlashMessageExclusive to work.
import '@canvas/rails-flash-notifications'

// Mock FlashAlert to prevent UI transitions/timers from running after test teardown
vi.mock('@canvas/alerts/react/FlashAlert')

beforeEach(() => {
  fakeENV.setup()
})

afterEach(() => {
  fakeENV.teardown()
})

it.skip('searchPermissions dispatches updatePermissionsSearch', done => {
  const state = {contextId: 1, permissions: PERMISSIONS, roles: []}
  const dispatchMock = vi.fn()
  actions.searchPermissions({permissionSearchString: 'add', contextType: COURSE})(
    dispatchMock,
    () => state,
  )

  const expectedDispatch = {
    type: 'UPDATE_PERMISSIONS_SEARCH',
    payload: {
      permissionSearchString: 'add',
      contextType: COURSE,
    },
  }

  expect(dispatchMock).toHaveBeenCalledTimes(1)
  expect(dispatchMock).toHaveBeenCalledWith(expectedDispatch)
  done()
})

it.skip('searchPermissions announces when search is complete', () => {
  const state = {contextId: 1, permissions: PERMISSIONS, roles: []}
  const dispatchMock = vi.fn()
  const flashMock = vi.spyOn($, 'screenReaderFlashMessageExclusive')
  actions.searchPermissions({permissionSearchString: 'add', contextType: COURSE})(
    dispatchMock,
    () => state,
  )

  expect(flashMock).toHaveBeenCalledTimes(1)
  expect(flashMock).toHaveBeenCalledWith('2 permissions found')
})

it('setAndOpenRoleTray dispatches hideAllTrays and dispalyRoleTray', () => {
  const dispatchMock = vi.fn()
  actions.setAndOpenRoleTray('banana')(dispatchMock, () => {})

  const expectedHideDispatch = {
    type: 'HIDE_ALL_TRAYS',
  }
  const expectedDisplayRoleDispatch = {
    type: 'DISPLAY_ROLE_TRAY',
    payload: {
      role: 'banana',
    },
  }

  expect(dispatchMock).toHaveBeenCalledTimes(2)
  expect(dispatchMock).toHaveBeenCalledWith(expectedHideDispatch)
  expect(dispatchMock).toHaveBeenCalledWith(expectedDisplayRoleDispatch)
})

it('setAndOpenAddTray dispatches hideAllTrays and displayAddTray', () => {
  const dispatchMock = vi.fn()
  actions.setAndOpenAddTray()(dispatchMock, () => {})
  const expectedHideDispatch = {
    type: 'HIDE_ALL_TRAYS',
  }
  const expectedDisplayAddDispatch = {
    type: 'DISPLAY_ADD_TRAY',
  }

  expect(dispatchMock).toHaveBeenCalledTimes(2)
  expect(dispatchMock).toHaveBeenCalledWith(expectedHideDispatch)
  expect(dispatchMock).toHaveBeenCalledWith(expectedDisplayAddDispatch)
})

it('setAndOpenPermissionTray dispatches hideAllTrays and dispalyPermissionTray', () => {
  const dispatchMock = vi.fn()
  actions.setAndOpenPermissionTray('banana')(dispatchMock, () => {})
  const expectedHideDispatch = {
    type: 'HIDE_ALL_TRAYS',
  }
  const expectedDisplayRoleDispatch = {
    type: 'DISPLAY_PERMISSION_TRAY',
    payload: {
      permission: 'banana',
    },
  }

  expect(dispatchMock).toHaveBeenCalledTimes(2)
  expect(dispatchMock).toHaveBeenCalledWith(expectedHideDispatch)
  expect(dispatchMock).toHaveBeenCalledWith(expectedDisplayRoleDispatch)
})

it('filterRoles dispatches updateRoleFilters', () => {
  const state = {
    contextId: 1,
    permissions: PERMISSIONS,
    roles: ROLES,
    selectedRoles: [{id: '104', label: 'kitty', children: 'kitty', value: '104'}],
  }
  const dispatchMock = vi.fn()
  actions.filterRoles({selectedRoles: [ROLES[0]], contextType: COURSE})(dispatchMock, () => state)
  const expectedFirstDispatch = {
    type: 'UPDATE_SELECTED_ROLES',
    payload: [ROLES[0]],
  }
  const expectedSecondDispatch = {
    type: 'UPDATE_ROLE_FILTERS',
    payload: {
      selectedRoles: [ROLES[0]],
      contextType: COURSE,
    },
  }

  expect(dispatchMock).toHaveBeenCalledTimes(2)
  expect(dispatchMock).toHaveBeenCalledWith(expectedFirstDispatch)
  expect(dispatchMock).toHaveBeenCalledWith(expectedSecondDispatch)
})

it('filterRemovedRole dispatches updateRoleFilters and filterDeletedRole', () => {
  const state = {
    selectedRoles: [
      {id: '104', label: 'kitty', children: 'kitty', value: '104'},
      {id: '108', label: 'meow', children: 'meow', value: '108'},
    ],
  }
  const dispatchMock = vi.fn()
  actions.filterRemovedRole('Course')(dispatchMock, () => state)
  const expectedUpdateRoleDispatch = {
    type: 'UPDATE_ROLE_FILTERS',
    payload: {
      selectedRoles: [
        {id: '104', label: 'kitty', children: 'kitty', value: '104'},
        {id: '108', label: 'meow', children: 'meow', value: '108'},
      ],
      contextType: 'Course',
    },
  }

  expect(dispatchMock).toHaveBeenCalledTimes(1)
  expect(dispatchMock).toHaveBeenCalledWith(expectedUpdateRoleDispatch)
})

it('tabChanged dispatches permissionsTabChanged', () => {
  const state = {contextId: 1, permissions: PERMISSIONS, roles: ROLES}
  const dispatchMock = vi.fn()
  actions.tabChanged(ACCOUNT)(dispatchMock, () => state)
  expect(dispatchMock).toHaveBeenCalledTimes(1)
  const expectedDispatch = {
    type: 'PERMISSIONS_TAB_CHANGED',
    payload: ACCOUNT,
  }
  expect(dispatchMock).toHaveBeenCalledTimes(1)
  expect(dispatchMock).toHaveBeenCalledWith(expectedDispatch)
})

describe('api actions', () => {
  const server = setupServer()

  beforeAll(() => server.listen({onUnhandledRequest: 'error'}))
  beforeEach(() => {
    fakeENV.setup()
    window.ENV.flashAlertTimeout = 5
    vi.useRealTimers()
  })
  afterEach(() => {
    server.resetHandlers()
    vi.clearAllMocks()
    vi.clearAllTimers()
    vi.useFakeTimers()
    fakeENV.teardown()
  })
  afterAll(() => server.close())

  it('updateRoleName dispatches updateRole', async () => {
    let requestReceived = false
    server.use(
      http.put('/api/v1/accounts/1/roles/:id', () => {
        requestReceived = true
        return HttpResponse.json({
          id: '9',
          role: 'steven',
          label: 'steven',
          base_role_type: 'StudentEnrollment',
          workflow_state: 'active',
        })
      }),
    )

    const mockDispatch = vi.fn()
    const state = {contextId: 1, permissions: PERMISSIONS, roles: []}
    const getState = () => state
    actions.updateRoleName('1', 'steven', 'StudentRoll')(mockDispatch, getState)

    await waitFor(() => {
      expect(requestReceived).toBe(true)
    })

    await waitFor(() => {
      expect(mockDispatch).toHaveBeenCalled()
    })

    expect(mockDispatch).toHaveBeenCalledWith({
      type: 'UPDATE_ROLE',
      payload: {
        id: '9',
        role: 'steven',
        label: 'steven',
        base_role_type: 'StudentEnrollment',
        workflow_state: 'active',
      },
    })
  })

  it('createNewRole dispatches addNewRole', async () => {
    let requestReceived = false
    server.use(
      http.post('/api/v1/accounts/1/roles', () => {
        requestReceived = true
        return HttpResponse.json({
          id: '9',
          role: 'steven',
          label: 'steven',
          base_role_type: 'StudentEnrollment',
          workflow_state: 'active',
        })
      }),
    )

    const mockDispatch = vi.fn()
    const state = {contextId: 1, permissions: PERMISSIONS, roles: [], selectedRoles: []}
    const getState = () => state
    actions.createNewRole('steven', 'StudentRoll')(mockDispatch, getState)

    await waitFor(() => {
      expect(requestReceived).toBe(true)
    })

    await waitFor(() => {
      expect(mockDispatch).toHaveBeenCalledTimes(7)
    })

    // Check all dispatched actions
    const expectedStartDispatch = {
      type: 'ADD_TRAY_SAVING_START',
    }
    const expectedAddNewRoleDispatch = {
      type: 'ADD_NEW_ROLE',
      payload: {
        id: '9',
        role: 'steven',
        label: 'steven',
        base_role_type: 'StudentEnrollment',
        workflow_state: 'active',
      },
    }
    const expectedDisplayRoleTrayDispatch = {
      type: 'DISPLAY_ROLE_TRAY',
      payload: {
        role: {
          base_role_type: 'StudentEnrollment',
          id: '9',
          label: 'steven',
          role: 'steven',
          workflow_state: 'active',
        },
      },
    }
    const expectedDisplayAddSuccessDispatch = {
      type: 'ADD_TRAY_SAVING_SUCCESS',
    }
    const expectedHideDispatch = {
      type: 'HIDE_ALL_TRAYS',
    }

    expect(mockDispatch).toHaveBeenCalledWith(expectedStartDispatch)
    expect(mockDispatch).toHaveBeenCalledWith(expectedAddNewRoleDispatch)
    expect(mockDispatch).toHaveBeenCalledWith(expectedDisplayRoleTrayDispatch)
    expect(mockDispatch).toHaveBeenCalledWith(expectedDisplayAddSuccessDispatch)
    expect(mockDispatch).toHaveBeenCalledWith(expectedHideDispatch)
  })

  it('createNewRole dispatches addTraySavingFail', async () => {
    server.use(
      http.post('/api/v1/accounts/1/roles', () => {
        return HttpResponse.json(
          {
            errors: {
              base: ['Invalid role'],
            },
          },
          {status: 400},
        )
      }),
    )

    const mockDispatch = vi.fn()
    const state = {contextId: 1, permissions: PERMISSIONS, roles: [], selectedRoles: []}
    const getState = () => state
    actions.createNewRole('steven', 'StudentRoll')(mockDispatch, getState)

    await waitFor(() => {
      expect(mockDispatch).toHaveBeenCalledWith({
        type: 'ADD_TRAY_SAVING_FAIL',
      })
    })
  })

  it('modifyPermissions dispatches updatePermissions', async () => {
    server.use(
      http.put('/api/v1/accounts/1/roles/:id', () => {
        return HttpResponse.json({
          id: '3',
          permissions: {delete_course: {enabled: false, locked: true, explicit: true}},
        })
      }),
    )

    const state = {
      contextId: 1,
      permissions: {},
      roles: [
        {id: '3', permissions: {delete_course: {enabled: true, locked: true, explicit: true}}},
      ],
    }
    const dispatchMock = vi.fn()

    const expectedUpdatePermsDispatch = {
      type: 'UPDATE_PERMISSIONS',
      payload: {
        role: {
          contextType: undefined,
          displayed: undefined,
          id: '3',
          permissions: {
            delete_course: {
              enabled: false,
              locked: true,
              explicit: true,
            },
          },
        },
      },
    }
    const expectedFixFocusDispatch = {
      type: 'FIX_FOCUS',
      payload: {
        permissionName: 'delete_course',
        roleId: '3',
        targetArea: 'table',
      },
    }

    const expectedApiBusyDispatch = {
      type: 'API_PENDING',
      payload: {id: '3', name: 'delete_course'},
    }

    const expectedApiUnbusyDispatch = {
      type: 'API_COMPLETE',
      payload: {id: '3', name: 'delete_course'},
    }

    actions.modifyPermissions({
      name: 'delete_course',
      id: '3',
      enabled: false,
      locked: true,
      explicit: true,
      inTray: false,
    })(dispatchMock, () => state)

    await waitFor(() => {
      expect(dispatchMock).toHaveBeenCalledTimes(4)
    })

    // Check all dispatched actions without assuming order
    expect(dispatchMock).toHaveBeenCalledWith(expectedApiBusyDispatch)
    expect(dispatchMock).toHaveBeenCalledWith(expectedUpdatePermsDispatch)
    expect(dispatchMock).toHaveBeenCalledWith(expectedFixFocusDispatch)
    expect(dispatchMock).toHaveBeenCalledWith(expectedApiUnbusyDispatch)
  })

  it('deleteRole action dispatches delete and calls success callback if good', async () => {
    server.use(
      http.delete('/api/v1/accounts/1/roles/:id', () => {
        return HttpResponse.json({data: 'who cares'})
      }),
    )

    const state = {contextId: 1, permissions: PERMISSIONS, roles: ROLES}
    const successCallbackMock = vi.fn()
    const failCallbackMock = vi.fn()
    const mockDispatch = vi.fn()
    actions.deleteRole(ROLES[1], successCallbackMock, failCallbackMock)(mockDispatch, () => state)

    await waitFor(() => {
      expect(successCallbackMock).toHaveBeenCalledTimes(1)
      expect(failCallbackMock).toHaveBeenCalledTimes(0)
      const expectedDeleteRoleDispatch = {
        type: 'DELETE_ROLE_SUCCESS',
        payload: ROLES[1],
      }
      expect(mockDispatch).toHaveBeenCalledTimes(2)
      expect(mockDispatch).toHaveBeenCalledWith(expectedDeleteRoleDispatch)
    })
  })

  it('deleteRole action doesnt dispatch and does fail callback on fail', async () => {
    server.use(
      http.delete('/api/v1/accounts/1/roles/:id', () => {
        return HttpResponse.json({data: 'who cares'}, {status: 400})
      }),
    )

    const state = {contextId: 1, permissions: PERMISSIONS, roles: ROLES}
    const successCallbackMock = vi.fn()
    const failCallbackMock = vi.fn()
    const mockDispatch = vi.fn()
    actions.deleteRole(ROLES[1], successCallbackMock, failCallbackMock)(mockDispatch, () => state)

    await waitFor(() => {
      expect(successCallbackMock).toHaveBeenCalledTimes(0)
      expect(failCallbackMock).toHaveBeenCalledTimes(1)
      // Don't dispatch anything if api call fails
      expect(mockDispatch).toHaveBeenCalledTimes(0)
    })
  })
})
