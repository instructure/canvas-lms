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
import {
  COURSE,
  ACCOUNT,
  ALL_ROLES_LABEL,
  ALL_ROLES_VALUE,
  ENABLED_FOR_NONE,
  ENABLED_FOR_PARTIAL,
  ENABLED_FOR_ALL,
} from '@canvas/permissions/react/propTypes'
import {PERMISSIONS, ROLES} from './examples'
import reducer from '../reducer'
import stubEnv from '@canvas/stub-env'

const reduce = (action, state = {}) => reducer(state, action)

// Many actions should only ever result in the displayed field changing,
// so this is a convenient way of testing for this.
//
// It isn't great to have expects in these utility functions (it can make
// interpreting the failure message harder) but it avoids repeating this
// over and over.

describe('permissions::reducer', () => {
  stubEnv({
    ACCOUNT_PERMISSIONS: [
      {
        group_name: 'Account Permissions',
        group_permissions: [{permission_name: 'manage_courses_add'}],
        context_type: 'Account',
      },
    ],
    ACCOUNT_ROLES: [
      {
        role: 'AccountAdmin',
        label: 'Account Admin',
        base_role_type: 'AccountMembership',
      },
      {
        role: 'CustomAccountAdmin',
        label: 'Custom Account Admin',
        base_role_type: 'AccountMembership',
      },
    ],
    COURSE_ROLES: [
      {
        role: 'TeacherEnrollment',
        label: 'Teacher',
        base_role_type: 'TeacherEnrollment',
      },
      {
        role: 'Custom Teacher Role',
        label: 'Custom Teacher Role',
        base_role_type: 'TeacherEnrollment',
      },
    ],
  })

  function verifyPermissionsDidntChange(oldPermissions, newPermissions) {
    expect(newPermissions).toHaveLength(oldPermissions.length)
    for (let i = 0; i < newPermissions.length; ++i) {
      expect(newPermissions.permission_name).toEqual(oldPermissions.permission_name)
      expect(newPermissions.label).toEqual(newPermissions.label)
      expect(newPermissions.contextType).toEqual(oldPermissions.contextType)
    }
  }

  function verifyRolesDidntChange(newRoles, oldRoles) {
    expect(newRoles).toHaveLength(oldRoles.length)
    for (let i = 0; i < newRoles.length; ++i) {
      expect(newRoles[i].id).toEqual(oldRoles[i].id)
      expect(newRoles[i].label).toEqual(oldRoles[i].label)
      expect(newRoles[i].base_role_type).toEqual(oldRoles[i].base_role_type)
      expect(newRoles[i].contextType).toEqual(oldRoles[i].contextType)
    }
  }

  // Verifies that only the indicies in trueIndices in checkDisplayed are set to true
  function checkDisplayed(arr, trueIndices) {
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
      contextType: COURSE,
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
      contextType: ACCOUNT,
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
          displayed: true,
        },
      ],
      contextType: COURSE,
    }
    const newState = reduce(actions.updateRoleFilters(payload), originalState)
    verifyPermissionsDidntChange(originalState.permissions, newState.permissions)
    verifyRolesDidntChange(originalState.roles, newState.roles)
    checkDisplayed(newState.roles, [1])
  })

  it('UPDATE_SELECTED_ROLES changes the filters in the filter bar', () => {
    const originalState = {
      selectedRoles: [{id: '104', label: 'kitty', children: 'kitty', value: '104'}],
    }
    const payload = {id: '108', label: 'meow', children: 'meow', value: '108'}
    const newState = reduce(actions.updateSelectedRoles(payload), originalState)

    const expectedState = {id: '108', label: 'meow', children: 'meow', value: '108'}
    expect(newState.selectedRoles).toEqual(expectedState)
  })

  it('UPDATE_SELECTED_ROLES changes filters if all roles are selected', () => {
    const originalState = {
      selectedRoles: [{label: ALL_ROLES_LABEL, value: ALL_ROLES_VALUE}],
    }
    const payload = {id: '108', label: 'meow', children: 'meow', value: '108'}
    const newState = reduce(actions.updateSelectedRoles(payload), originalState)

    const expectedState = {id: '108', label: 'meow', children: 'meow', value: '108'}
    expect(newState.selectedRoles).toEqual(expectedState)
  })

  it('FILTER_NEW_ROLE adds the new role to the filter bar and keeps the old', () => {
    const originalState = {
      selectedRoles: [{id: '104', label: 'kitty', children: 'kitty', value: '104'}],
    }
    const payload = {id: '108', label: 'meow', children: 'meow', value: '108'}
    const newState = reduce(actions.filterNewRole(payload), originalState)

    const expectedState = [
      {id: '104', label: 'kitty', children: 'kitty', value: '104'},
      {id: '108', label: 'meow', children: 'meow', value: '108'},
    ]
    expect(newState.selectedRoles).toEqual(expectedState)
  })

  it('FILTER_NEW_ROLE does not change filters if all roles are selected', () => {
    const originalState = {
      selectedRoles: [{label: ALL_ROLES_LABEL, value: ALL_ROLES_VALUE}],
    }
    const payload = {id: '108', label: 'meow', children: 'meow', value: '108'}
    const newState = reduce(actions.filterNewRole(payload), originalState)

    const expectedState = [{label: ALL_ROLES_LABEL, value: ALL_ROLES_VALUE}]
    expect(newState.selectedRoles).toEqual(expectedState)
  })

  it('FILTER_DELETED_ROLE removes the given role from the filter bar and keeps the old', () => {
    const originalState = {
      selectedRoles: [
        {id: '104', label: 'kitty', children: 'kitty', value: '104'},
        {id: '108', label: 'meow', children: 'meow', value: '108'},
      ],
    }
    const payload = {
      role: {id: '108', label: 'meow', children: 'meow', value: '108'},
      selectedRoles: [{id: '104', label: 'kitty', children: 'kitty', value: '104'}],
    }
    const newState = reduce(actions.filterDeletedRole(payload), originalState)

    const expectedState = [{id: '104', label: 'kitty', children: 'kitty', value: '104'}]
    expect(newState.selectedRoles).toEqual(expectedState)
  })

  it('FILTER_DELETED_ROLE does not change the filters if all roles are selected', () => {
    const originalState = {
      selectedRoles: [{label: ALL_ROLES_LABEL, value: ALL_ROLES_VALUE}],
    }
    const payload = {
      role: {id: '108', label: 'meow', children: 'meow', value: '108'},
      selectedRoles: [{label: ALL_ROLES_LABEL, value: ALL_ROLES_VALUE}],
    }
    const newState = reduce(actions.filterDeletedRole(payload), originalState)

    const expectedState = [{label: ALL_ROLES_LABEL, value: ALL_ROLES_VALUE}]
    expect(newState.selectedRoles).toEqual(expectedState)
  })

  it('FILTER_DELETED_ROLE resets to all roles displayed if the last displated role is deleted', () => {
    const originalState = {
      selectedRoles: [{id: '108', label: 'meow', children: 'meow', value: '108'}],
    }
    const payload = {
      role: {id: '108', label: 'meow', children: 'meow', value: '108'},
      selectedRoles: [{id: '108', label: 'meow', children: 'meow', value: '108'}],
    }
    const newState = reduce(actions.filterDeletedRole(payload), originalState)

    const expectedState = []
    expect(newState.selectedRoles).toEqual(expectedState)
  })

  it('DISPLAY_ROLE_TRAY sets the activeRoleTray in the store', () => {
    const originalState = {activeRoleTray: null}
    const payload = {role: {name: 'newRoleSim', id: '3'}}
    const newState = reduce(actions.displayRoleTray(payload), originalState)
    expect(newState.activeRoleTray).toEqual({roleId: '3'})
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
        loading: false,
      },
    }
    const newState = reduce(actions.displayAddTray(), originalState)
    expect(newState.activeAddTray).toEqual({
      show: true,
      loading: false,
    })
  })

  it('HIDE_ALL_TRAYS sets the activeAddTray to false in the store', () => {
    const originalState = {
      activeAddTray: {
        show: true,
        loading: false,
      },
    }
    const newState = reduce(actions.hideAllTrays(), originalState)
    expect(newState.activeAddTray).toEqual({
      show: false,
      loading: false,
    })
  })

  it('ADD_TRAY_SAVING_START sets the activeAddTray in the store', () => {
    const originalState = {
      activeAddTray: {
        show: false,
        loading: true,
      },
    }
    const newState = reduce(actions.addTraySavingStart(), originalState)
    expect(newState.activeAddTray).toEqual({
      show: false,
      loading: true,
    })
  })

  it('ADD_TRAY_SAVING_SUCCESS sets the activeAddTray to false in the store', () => {
    const originalState = {
      activeAddTray: {
        show: true,
        loading: true,
      },
    }
    const newState = reduce(actions.addTraySavingSuccess(), originalState)
    expect(newState.activeAddTray).toEqual({
      show: true,
      loading: false,
    })
  })

  it('ADD_TRAY_SAVING_FAIL sets the activeAddTray to false in the store', () => {
    const originalState = {
      activeAddTray: {
        show: true,
        loading: true,
      },
    }
    const newState = reduce(actions.addTraySavingFail(), originalState)
    expect(newState.activeAddTray).toEqual({
      show: true,
      loading: false,
    })
  })

  it('UPDATE_PERMISSIONS sets enabled in the store', () => {
    const originalState = {
      roles: [{id: '1', permissions: {become_user: {enabled: true, locked: true, explicit: true}}}],
    }
    const payload = {
      role: {
        id: '1',
        permissions: {
          become_user: {
            enabled: false,
            locked: true,
            explicit: true,
          },
        },
      },
    }
    const newState = reduce(actions.updatePermissions(payload), originalState)
    const expectedState = [
      {
        id: '1',
        permissions: {become_user: {enabled: ENABLED_FOR_NONE, locked: true, explicit: true}},
      },
    ]
    expect(newState.roles).toEqual(expectedState)
  })

  it('UPDATE_PERMISSIONS sets locked in the store', () => {
    const originalState = {
      roles: [{id: '1', permissions: {become_user: {enabled: true, locked: true, explicit: true}}}],
    }
    const payload = {
      role: {
        id: '1',
        permissions: {
          become_user: {
            enabled: true,
            locked: false,
            explicit: true,
          },
        },
      },
    }
    const newState = reduce(actions.updatePermissions(payload), originalState)
    const expectedState = [
      {
        id: '1',
        permissions: {become_user: {enabled: ENABLED_FOR_ALL, locked: false, explicit: true}},
      },
    ]
    expect(newState.roles).toEqual(expectedState)
  })

  it('UPDATE_PERMISSIONS sets explicit in the store', () => {
    const originalState = {
      roles: [{id: '1', permissions: {become_user: {enabled: true, locked: true, explicit: true}}}],
    }
    const payload = {
      role: {
        id: '1',
        permissions: {
          become_user: {
            enabled: true,
            locked: true,
            explicit: false,
          },
        },
      },
    }
    const newState = reduce(actions.updatePermissions(payload), originalState)
    const expectedState = [
      {
        id: '1',
        permissions: {become_user: {enabled: ENABLED_FOR_ALL, locked: true, explicit: false}},
      },
    ]
    expect(newState.roles).toEqual(expectedState)
  })

  it('UPDATE_PERMISSIONS groups granular permissions in roles', () => {
    const originalState = {roles: [{id: '1', permissions: {}, contextType: ACCOUNT}]}

    const payload = {
      role: {
        id: '1',
        role: 'AccountAdmin',
        label: 'Account Admin',
        base_role_type: 'AccountMembership',
        permissions: {
          granular_1: {
            enabled: false,
            explicit: true,
            group: 'granular_permission_group',
            locked: false,
          },
          granular_2: {
            enabled: true,
            explicit: true,
            group: 'granular_permission_group',
            locked: false,
          },
        },
        contextType: ACCOUNT,
      },
    }

    const expectedState = [
      {
        id: '1',
        role: 'AccountAdmin',
        label: 'Account Admin',
        base_role_type: 'AccountMembership',
        permissions: {
          granular_1: {
            enabled: ENABLED_FOR_NONE,
            explicit: true,
            group: 'granular_permission_group',
            locked: false,
          },
          granular_2: {
            enabled: ENABLED_FOR_ALL,
            explicit: true,
            group: 'granular_permission_group',
            locked: false,
          },
          granular_permission_group: {
            built_from_granular_permissions: true,
            enabled: ENABLED_FOR_PARTIAL,
            explicit: true,
            locked: false,
            readonly: false,
          },
        },
        contextType: ACCOUNT,
      },
    ]

    const newState = reduce(actions.updatePermissions(payload), originalState)
    expect(newState.roles).toEqual(expectedState)
  })

  it('UPDATE_ROLE updates the label correct', () => {
    const originalState = {
      roles: [
        {
          base_role_type: 'StudentEnrollment',
          id: '9',
          label: 'steven',
          role: 'steven',
          workflow_state: 'active',
        },
      ],
    }
    const payload = {
      base_role_type: 'StudentEnrollment',
      id: '9',
      label: 'steven awesome',
      role: 'steven awesome',
      workflow_state: 'active',
    }
    const newState = reduce(actions.updateRole(payload), originalState)
    const expectedState = [
      {
        base_role_type: 'StudentEnrollment',
        id: '9',
        label: 'steven awesome',
        role: 'steven awesome',
        workflow_state: 'active',
      },
    ]
    expect(newState.roles).toEqual(expectedState)
  })

  it('ADD_NEW_ROLE updates the label correct', () => {
    const originalState = {
      roles: [
        {
          base_role_type: 'StudentEnrollment',
          id: '9',
          label: 'steven',
          role: 'StudentEnrollment',
          workflow_state: 'active',
          displayed: true,
          permissions: {},
          contextType: COURSE,
        },
        {
          base_role_type: 'AccountMembership',
          id: '10',
          label: 'aaron',
          role: 'AccountMembership',
          workflow_state: 'active',
          displayed: false,
          permissions: {},
          contextType: ACCOUNT,
        },
      ],
    }
    const payload = {
      base_role_type: 'StudentEnrollment',
      id: '11',
      label: 'venk grumpy',
      role: 'venk grumpy',
      workflow_state: 'active',
      displayed: false,
      permissions: {},
      contextType: COURSE,
    }
    const newState = reduce(actions.addNewRole(payload), originalState)
    const expectedState = [
      {
        base_role_type: 'StudentEnrollment',
        id: '9',
        label: 'steven',
        role: 'StudentEnrollment',
        workflow_state: 'active',
        displayed: true,
        permissions: {},
        contextType: COURSE,
      },
      {
        base_role_type: 'StudentEnrollment',
        id: '11',
        label: 'venk grumpy',
        role: 'venk grumpy',
        workflow_state: 'active',
        displayed: true,
        permissions: {},
        contextType: COURSE,
      },
      {
        base_role_type: 'AccountMembership',
        id: '10',
        label: 'aaron',
        role: 'AccountMembership',
        workflow_state: 'active',
        displayed: false,
        permissions: {},
        contextType: ACCOUNT,
      },
    ]
    expect(newState.roles).toEqual(expectedState)
  })

  it('ADD_NEW_ROLE groups granular role permissions', () => {
    const originalState = {
      roles: [{id: '1', permissions: {}, contextType: COURSE, displayed: true}],
    }

    const payload = {
      id: '2',
      role: 'TeacherEnrollment',
      label: 'Teacher',
      base_role_type: 'TeacherEnrollment',
      permissions: {
        granular_1: {
          enabled: true,
          explicit: true,
          group: 'granular_permission_group',
          locked: false,
        },
        granular_2: {
          enabled: false,
          explicit: true,
          group: 'granular_permission_group',
          locked: false,
        },
      },
      contextType: COURSE,
    }

    const expectedState = [
      {
        id: '2',
        role: 'TeacherEnrollment',
        label: 'Teacher',
        base_role_type: 'TeacherEnrollment',
        contextType: COURSE,
        displayed: true,
        permissions: {
          granular_1: {
            enabled: ENABLED_FOR_ALL,
            explicit: true,
            group: 'granular_permission_group',
            locked: false,
          },
          granular_2: {
            enabled: ENABLED_FOR_NONE,
            explicit: true,
            group: 'granular_permission_group',
            locked: false,
          },
          granular_permission_group: {
            built_from_granular_permissions: true,
            enabled: ENABLED_FOR_PARTIAL,
            explicit: true,
            locked: false,
            readonly: false,
          },
        },
      },
      {
        id: '1',
        permissions: {},
        contextType: COURSE,
        displayed: true,
      },
    ]

    const newState = reduce(actions.addNewRole(payload), originalState)
    expect(newState.roles).toEqual(expectedState)
  })

  it('ADD_NEW_ROLE correctly adds account level role', () => {
    const originalState = {
      roles: [
        {
          base_role_type: 'StudentEnrollment',
          id: '9',
          label: 'steven',
          role: 'StudentEnrollment',
          workflow_state: 'active',
          displayed: false,
          permissions: {},
          contextType: COURSE,
        },
        {
          base_role_type: 'AccountMembership',
          id: '10',
          label: 'aaron',
          role: 'AccountMembership',
          workflow_state: 'active',
          displayed: true,
          permissions: {},
          contextType: ACCOUNT,
        },
      ],
    }
    const payload = {
      base_role_type: 'AccountMembership',
      id: '11',
      label: 'venk grumpy',
      role: 'venk grumpy',
      workflow_state: 'active',
      displayed: false,
      permissions: {},
      contextType: ACCOUNT,
    }
    const newState = reduce(actions.addNewRole(payload), originalState)
    const expectedState = [
      {
        base_role_type: 'StudentEnrollment',
        id: '9',
        label: 'steven',
        role: 'StudentEnrollment',
        workflow_state: 'active',
        displayed: false,
        permissions: {},
        contextType: COURSE,
      },
      {
        base_role_type: 'AccountMembership',
        id: '10',
        label: 'aaron',
        role: 'AccountMembership',
        workflow_state: 'active',
        displayed: true,
        permissions: {},
        contextType: ACCOUNT,
      },
      {
        base_role_type: 'AccountMembership',
        id: '11',
        label: 'venk grumpy',
        role: 'venk grumpy',
        workflow_state: 'active',
        displayed: true,
        permissions: {},
        contextType: ACCOUNT,
      },
    ]
    expect(newState.roles).toEqual(expectedState)
  })

  it('DISPLAY_PERMISSION_TRAY sets the activePermissionTray in the store', () => {
    const originalState = {activePermissionTray: null}
    const payload = {permission: {label: 'newRoleSim', permission_name: 'role2'}}
    const newState = reduce(actions.displayPermissionTray(payload), originalState)
    expect(newState.activePermissionTray).toEqual({permissionName: 'role2'})
  })

  it('HIDE_ALL_TRAYS sets the activePermissionTray in the store', () => {
    const originalState = {activePermissionTray: {permission: 'banana'}}
    const newState = reduce(actions.hideAllTrays(), originalState)
    expect(newState.activeRoleTray).toBeNull()
  })

  it('DELETE_ROLE_SUCCESS deletes the proper role', () => {
    const originalState = {roles: ROLES}
    const roleToDelete = ROLES[1]
    const newRoles = reduce(actions.deleteRoleSuccess(roleToDelete), originalState).roles
    expect(newRoles).toHaveLength(3)
    expect(newRoles[0].id).toEqual(ROLES[0].id)
    expect(newRoles[1].id).toEqual(ROLES[2].id)
    expect(newRoles[2].id).toEqual(ROLES[3].id)
  })
})
