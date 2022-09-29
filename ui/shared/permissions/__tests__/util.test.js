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

import {
  getSortedRoles,
  roleSortedInsert,
  roleIsCourseBaseRole,
  roleIsBaseRole,
  groupGranularPermissionsInRole,
} from '../util'
import {ENABLED_FOR_NONE, ENABLED_FOR_PARTIAL, ENABLED_FOR_ALL} from '../react/propTypes'
import stubEnv from '@canvas/stub-env'

function makeGroupPermissions() {
  return {
    permissions: {
      p1: {enabled: true, locked: false, readonly: true, explicit: false},
      p2: {enabled: ENABLED_FOR_NONE, locked: false, readonly: true, explicit: false},
      p3: {enabled: false, locked: false, readonly: true, explicit: false},
      g1a: {enabled: true, locked: true, readonly: true, explicit: true, group: 'g1'},
      g1b: {enabled: true, locked: false, readonly: false, explicit: false, group: 'g1'},
      g2a: {enabled: true, locked: true, readonly: true, explicit: true, group: 'g2'},
      g2b: {enabled: false, locked: true, readonly: true, explicit: true, group: 'g2'},
      g3a: {enabled: false, locked: false, readonly: false, explicit: false, group: 'g3'},
      g3b: {enabled: false, locked: false, readonly: false, explicit: false, group: 'g3'},
      manage_courses_add: {
        enabled: false,
        locked: true,
        readonly: true,
        explicit: false,
        group: 'manage_courses',
      },
      manage_courses_conclude: {
        enabled: true,
        locked: false,
        readonly: false,
        explicit: false,
        group: 'manage_courses',
      },
      manage_courses_delete: {
        enabled: true,
        locked: false,
        readonly: false,
        explicit: false,
        group: 'manage_courses',
      },
      manage_courses_publish: {
        enabled: true,
        locked: false,
        readonly: false,
        explicit: false,
        group: 'manage_courses',
      },
    },
  }
}

describe('permissions::utils', () => {
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

  describe('getSortedRoles', () => {
    it('sorts roles properly based on base_role_type', () => {
      const UNORDERED_ROLES = [
        {
          id: '13',
          role: 'NON_BASE_TYPE',
          base_role_type: 'BASE_TYPE_THREE',
        },
        {
          id: '1',
          role: 'BASE_TYPE_ONE',
          base_role_type: 'BASE_TYPE_ONE',
        },
        {
          id: '10',
          role: 'NON_BASE_TYPE',
          base_role_type: 'BASE_TYPE_FOUR',
        },
        {
          id: '2',
          role: 'BASE_TYPE_TWO',
          base_role_type: 'BASE_TYPE_TWO',
        },
        {
          id: '3',
          role: 'BASE_TYPE_THREE',
          base_role_type: 'BASE_TYPE_THREE',
        },
        {
          id: '4',
          role: 'BASE_TYPE_FOUR',
          base_role_type: 'BASE_TYPE_FOUR',
        },
      ]

      const ORDERED_ROLES = [
        {
          id: '1',
          role: 'BASE_TYPE_ONE',
          base_role_type: 'BASE_TYPE_ONE',
        },
        {
          id: '2',
          role: 'BASE_TYPE_TWO',
          base_role_type: 'BASE_TYPE_TWO',
        },
        {
          id: '3',
          role: 'BASE_TYPE_THREE',
          base_role_type: 'BASE_TYPE_THREE',
        },
        {
          id: '13',
          role: 'NON_BASE_TYPE',
          base_role_type: 'BASE_TYPE_THREE',
        },
        {
          id: '4',
          role: 'BASE_TYPE_FOUR',
          base_role_type: 'BASE_TYPE_FOUR',
        },
        {
          id: '10',
          role: 'NON_BASE_TYPE',
          base_role_type: 'BASE_TYPE_FOUR',
        },
      ]

      const orderedRoles = getSortedRoles(UNORDERED_ROLES)
      expect(orderedRoles).toMatchObject(ORDERED_ROLES)
    })

    it('sorts roles properly for NON_BASE_TYPE at beginning', () => {
      const UNORDERED_ROLES = [
        {
          id: '20',
          role: 'NON_BASE_TYPE',
          base_role_type: 'BASE_TYPE_ONE',
        },
        {
          id: '13',
          role: 'NON_BASE_TYPE',
          base_role_type: 'BASE_TYPE_THREE',
        },
        {
          id: '1',
          role: 'BASE_TYPE_ONE',
          base_role_type: 'BASE_TYPE_ONE',
        },
        {
          id: '2',
          role: 'BASE_TYPE_TWO',
          base_role_type: 'BASE_TYPE_TWO',
        },
        {
          id: '3',
          role: 'BASE_TYPE_THREE',
          base_role_type: 'BASE_TYPE_THREE',
        },
        {
          id: '11',
          role: 'NON_BASE_TYPE',
          base_role_type: 'BASE_TYPE_ONE',
        },
      ]

      const ORDERED_ROLES = [
        {
          id: '1',
          role: 'BASE_TYPE_ONE',
          base_role_type: 'BASE_TYPE_ONE',
        },
        {
          id: '11',
          role: 'NON_BASE_TYPE',
          base_role_type: 'BASE_TYPE_ONE',
        },
        {
          id: '20',
          role: 'NON_BASE_TYPE',
          base_role_type: 'BASE_TYPE_ONE',
        },
        {
          id: '2',
          role: 'BASE_TYPE_TWO',
          base_role_type: 'BASE_TYPE_TWO',
        },
        {
          id: '3',
          role: 'BASE_TYPE_THREE',
          base_role_type: 'BASE_TYPE_THREE',
        },
        {
          id: '13',
          role: 'NON_BASE_TYPE',
          base_role_type: 'BASE_TYPE_THREE',
        },
      ]

      const orderedRoles = getSortedRoles(UNORDERED_ROLES)
      expect(orderedRoles).toMatchObject(ORDERED_ROLES)
    })

    it('sorts roles properly for NON_BASE_TYPE in middle and seperated', () => {
      const UNORDERED_ROLES = [
        {
          id: '1',
          role: 'BASE_TYPE_ONE',
          base_role_type: 'BASE_TYPE_ONE',
        },
        {
          id: '11',
          role: 'NON_BASE_TYPE',
          base_role_type: 'BASE_TYPE_ONE',
        },
        {
          id: '2',
          role: 'BASE_TYPE_TWO',
          base_role_type: 'BASE_TYPE_TWO',
        },
        {
          id: '20',
          role: 'NON_BASE_TYPE',
          base_role_type: 'BASE_TYPE_ONE',
        },
        {
          id: '3',
          role: 'BASE_TYPE_THREE',
          base_role_type: 'BASE_TYPE_THREE',
        },
      ]

      const ORDERED_ROLES = [
        {
          id: '1',
          role: 'BASE_TYPE_ONE',
          base_role_type: 'BASE_TYPE_ONE',
        },
        {
          id: '11',
          role: 'NON_BASE_TYPE',
          base_role_type: 'BASE_TYPE_ONE',
        },
        {
          id: '20',
          role: 'NON_BASE_TYPE',
          base_role_type: 'BASE_TYPE_ONE',
        },
        {
          id: '2',
          role: 'BASE_TYPE_TWO',
          base_role_type: 'BASE_TYPE_TWO',
        },
        {
          id: '3',
          role: 'BASE_TYPE_THREE',
          base_role_type: 'BASE_TYPE_THREE',
        },
      ]

      const orderedRoles = getSortedRoles(UNORDERED_ROLES)
      expect(orderedRoles).toMatchObject(ORDERED_ROLES)
    })
  })

  describe('roleSortedInsert', () => {
    const ALL_ROLES = [
      {
        id: '1',
        role: 'BASE_TYPE_ONE',
        base_role_type: 'BASE_TYPE_ONE',
      },
      {
        id: '11',
        role: 'NON_BASE_TYPE',
        base_role_type: 'BASE_TYPE_ONE',
      },
      {
        id: '2',
        role: 'BASE_TYPE_TWO',
        base_role_type: 'BASE_TYPE_TWO',
      },
      {
        id: '3',
        role: 'BASE_TYPE_THREE',
        base_role_type: 'BASE_TYPE_THREE',
      },
    ]

    it('sorts roles properly inserts Role into first item', () => {
      const ROLE_TO_INSERT = {
        id: '20',
        role: 'NON_BASE_TYPE',
        base_role_type: 'BASE_TYPE_ONE',
      }

      const ORDERED_ROLES = ALL_ROLES.slice()
      ORDERED_ROLES.splice(2, 0, ROLE_TO_INSERT)

      const orderedRoles = roleSortedInsert(ALL_ROLES, ROLE_TO_INSERT)
      expect(orderedRoles).toMatchObject(ORDERED_ROLES)
    })

    it('sorts roles properly inserts Role into last item', () => {
      const ROLE_TO_INSERT = {
        id: '20',
        role: 'NON_BASE_TYPE',
        base_role_type: 'BASE_TYPE_THREE',
      }

      const ORDERED_ROLES = ALL_ROLES.slice()
      ORDERED_ROLES.splice(ALL_ROLES.length, 0, ROLE_TO_INSERT)

      const orderedRoles = roleSortedInsert(ALL_ROLES, ROLE_TO_INSERT)
      expect(orderedRoles).toMatchObject(ORDERED_ROLES)
    })

    it('sorts roles properly inserts Role into middle item', () => {
      const ROLE_TO_INSERT = {
        id: '20',
        role: 'NON_BASE_TYPE',
        base_role_type: 'BASE_TYPE_TWO',
      }

      const ORDERED_ROLES = ALL_ROLES.slice()
      ORDERED_ROLES.splice(3, 0, ROLE_TO_INSERT)

      const orderedRoles = roleSortedInsert(ALL_ROLES, ROLE_TO_INSERT)
      expect(orderedRoles).toMatchObject(ORDERED_ROLES)
    })

    it('puts accountAdmin in the first position', () => {
      const ACCOUNT_ADMIN = {
        id: '1',
        role: 'AccountAdmin',
        base_role_type: 'AccountMembership',
      }

      const orderedRoles = getSortedRoles(ALL_ROLES, ACCOUNT_ADMIN)
      expect(orderedRoles[0]).toMatchObject(ACCOUNT_ADMIN)
    })

    it('removes account admin and replaces it in first position', () => {
      const ACCOUNT_ADMIN = {
        id: '1',
        role: 'AccountAdmin',
        base_role_type: 'AccountMembership',
      }

      const UNORDERED_ROLES = [
        {
          id: '13',
          role: 'NON_BASE_TYPE',
          base_role_type: 'BASE_TYPE_THREE',
        },
        {
          id: '5',
          role: 'BASE_TYPE_ONE',
          base_role_type: 'BASE_TYPE_ONE',
        },
        {
          id: '10',
          role: 'NON_BASE_TYPE',
          base_role_type: 'BASE_TYPE_FOUR',
        },
        {
          id: '2',
          role: 'BASE_TYPE_TWO',
          base_role_type: 'BASE_TYPE_TWO',
        },
        {
          id: '3',
          role: 'BASE_TYPE_THREE',
          base_role_type: 'BASE_TYPE_THREE',
        },
        {
          id: '4',
          role: 'BASE_TYPE_FOUR',
          base_role_type: 'BASE_TYPE_FOUR',
        },
        {
          id: '1',
          role: 'AccountAdmin',
          base_role_type: 'AccountMembership',
        },
      ]

      const orderedRoles = getSortedRoles(UNORDERED_ROLES, ACCOUNT_ADMIN)
      expect(orderedRoles[0]).toMatchObject(ACCOUNT_ADMIN)
      expect(orderedRoles).toHaveLength(UNORDERED_ROLES.length)
    })
  })

  describe('groupGranularPermissionsInRole', () => {
    let accountRole
    let courseRole
    let customAccountRole
    let customCourseRole
    let groupPermissions

    beforeEach(() => {
      groupPermissions = makeGroupPermissions()
      accountRole = {
        base_role_type: 'AccountMembership',
        contextType: 'Account',
        ...groupPermissions,
      }
      courseRole = {base_role_type: 'TeacherEnrollment', contextType: 'Course', ...groupPermissions}
      customCourseRole = {base_role_type: 'TeacherEnrollment', ...groupPermissions}
      customAccountRole = {base_role_type: 'AccountMembership', ...groupPermissions}
    })

    it('transforms boolean enabled into enum value', () => {
      groupGranularPermissionsInRole(courseRole)
      const {permissions} = groupPermissions
      expect(permissions.p1.enabled).toBe(ENABLED_FOR_ALL)
      expect(permissions.p2.enabled).toBe(ENABLED_FOR_NONE)
      expect(permissions.p3.enabled).toBe(ENABLED_FOR_NONE)
    })

    it('creates new group permissions', () => {
      groupGranularPermissionsInRole(courseRole)
      const {permissions} = groupPermissions
      expect(permissions.g1).toBeDefined()
      expect(permissions.g2).toBeDefined()
      expect(permissions.g3).toBeDefined()
      expect(permissions.g1.built_from_granular_permissions).toBe(true)
    })

    it('sets the right enabled enum for the group value', () => {
      groupGranularPermissionsInRole(courseRole)
      const {g1, g2, g3} = groupPermissions.permissions
      expect(g1.enabled).toBe(ENABLED_FOR_ALL)
      expect(g2.enabled).toBe(ENABLED_FOR_PARTIAL)
      expect(g3.enabled).toBe(ENABLED_FOR_NONE)
    })

    it('does the right logic for the other group values', () => {
      groupGranularPermissionsInRole(courseRole)
      const {g1, g2, g3} = groupPermissions.permissions
      expect(g1.locked).toBe(false) // locked is ANDed
      expect(g1.readonly).toBe(true) // readonly is ORed
      expect(g1.explicit).toBe(true) // explicit is ORed
      expect(g2.locked).toBe(true)
      expect(g3.locked).toBe(false)
      expect(g3.readonly).toBe(false)
      expect(g3.explicit).toBe(false)
    })

    describe('course context', () => {
      it('sets the right enabled enum given grouped course/account granular permissions', () => {
        groupGranularPermissionsInRole(courseRole)
        expect(courseRole.permissions.manage_courses.enabled).toBe(ENABLED_FOR_ALL)
      })

      it('sets the right enabled enum given a custom role', () => {
        groupGranularPermissionsInRole(customCourseRole)
        expect(customCourseRole.permissions.manage_courses.enabled).toBe(ENABLED_FOR_ALL)
      })

      it('sets the correct readonly bool given grouped course/account granular permissions', () => {
        groupGranularPermissionsInRole(courseRole)
        expect(courseRole.permissions.manage_courses.readonly).toBe(false)
      })
    })

    describe('account context', () => {
      it('sets the right enabled enum given grouped course/account granular permissions', () => {
        groupGranularPermissionsInRole(accountRole)
        expect(accountRole.permissions.manage_courses.enabled).toBe(ENABLED_FOR_PARTIAL)
      })

      it('sets the right enabled enum given a custom role', () => {
        groupGranularPermissionsInRole(customAccountRole)
        expect(customAccountRole.permissions.manage_courses.enabled).toBe(ENABLED_FOR_PARTIAL)
      })

      it('sets the correct readonly bool given grouped course/account granular permissions', () => {
        groupGranularPermissionsInRole(accountRole)
        expect(accountRole.permissions.manage_courses.readonly).toBe(true)
      })
    })
  })

  it('does not return account base roles as course base roles', () => {
    const accountBaserole = {
      id: '1',
      role: 'AccountAdmin',
      base_role_type: 'AccountMembership',
    }

    expect(roleIsCourseBaseRole(accountBaserole)).toBeFalsy()
    expect(roleIsBaseRole(accountBaserole)).toBeTruthy()
  })
})
