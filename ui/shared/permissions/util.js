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

import {ENABLED_FOR_NONE, ENABLED_FOR_PARTIAL, ENABLED_FOR_ALL} from './react/propTypes'

export function getPermissionsWithLabels(allPermissions, rolePermissions) {
  // Convert this to a map to avoid O(n^2) lookups when grabbing the permission labels.
  const permLabelMap = allPermissions.reduce((acc, perm) => {
    acc[perm.permission_name] = perm.label
    return acc
  }, {})

  return Object.keys(rolePermissions).reduce((acc, permissionName) => {
    const permission = rolePermissions[permissionName]
    const label = permLabelMap[permissionName]
    if (label) {
      const permWithLabel = {
        ...permission,
        label,
        permissionName,
        displayed: false,
        permission_name: 'whatever',
      }
      acc.push(permWithLabel)
    }
    return acc
  }, [])
}

/*
 * @returns
 * true: if roleOne is placed before roleTwo
 * false: if roleOne is placed after roleTwo
 */
function roleComparisonFunction(roleOne, roleTwo) {
  return (
    roleOne.base_role_type !== roleTwo.base_role_type ||
    (roleOne.base_role_type === roleTwo.base_role_type &&
      parseInt(roleOne.id, 10) <= parseInt(roleTwo.id, 10))
  )
}

export function roleIsBaseRole(role) {
  return roleIsCourseBaseRole(role) || role.role === 'AccountAdmin'
}

export function roleIsCourseBaseRole(role) {
  return role.role === role.base_role_type
}

/*
 * Takes a list of roles and a role to role to insert into the list
 *
 * @returns
 * List of sorted roles
 */
export function roleSortedInsert(roles, roleToInsert) {
  const orderedRoles = roles.slice()
  const index = orderedRoles.findIndex(baseRole => baseRole.role === roleToInsert.base_role_type)

  // Get the role of the matched index
  let nextIndex = index + 1
  let nextRole = orderedRoles[nextIndex]

  // Runs as long as there is another role in the array
  // and the role matches the role we are checking
  while (nextRole) {
    if (roleComparisonFunction(roleToInsert, nextRole)) {
      // if role to be placed needs to be before the currentRole we push
      // everything over
      orderedRoles.splice(nextIndex, 0, roleToInsert)
      return orderedRoles
    } else {
      nextIndex++
      nextRole = orderedRoles[nextIndex]
    }
  }
  orderedRoles.splice(nextIndex, 0, roleToInsert)
  return orderedRoles
}

/*
 * Sorts an array of roles based on role type
 */
export function getSortedRoles(roles, accountAdmin) {
  const nonBaseRoles = roles.filter(role => !roleIsBaseRole(role))
  let orderedRoles = roles.filter(roleIsBaseRole) // Grabs all the base roles for the start
  nonBaseRoles.forEach(roleToBePlaced => {
    orderedRoles = roleSortedInsert(orderedRoles, roleToBePlaced)
  })
  // Make sure Account Admin is always the first-displayed role
  if (typeof accountAdmin !== 'undefined') {
    orderedRoles.splice(orderedRoles.indexOf(accountAdmin), 1)
    orderedRoles.unshift(accountAdmin)
  }
  return orderedRoles
}

function groupPermissionEnabled(boolArray) {
  if (boolArray.every(bool => bool)) return ENABLED_FOR_ALL
  if (boolArray.some(bool => bool)) return ENABLED_FOR_PARTIAL
  return ENABLED_FOR_NONE
}

/*
 * Takes a role and creates a new permission for any groups of granular permissions
 * in that role, based on the permission group name.
 *
 * Mutates its argument (role)
 */
export function groupGranularPermissionsInRole(role) {
  if (!role?.permissions) return // some JS tests don't bother to fill this in

  const groups = {}
  const accountPermissionsByName = ENV.ACCOUNT_PERMISSIONS
    ? ENV.ACCOUNT_PERMISSIONS.find(
        el => el.context_type && el.context_type === 'Account'
      ).group_permissions.map(perm => perm.permission_name)
    : null
  const courseRoleTypes = ENV.COURSE_ROLES
    ? ENV.COURSE_ROLES.map(courseRole => courseRole.base_role_type)
    : null
  const accountRoleTypes = ENV.ACCOUNT_ROLES
    ? ENV.ACCOUNT_ROLES.map(accountRole => accountRole.base_role_type)
    : null

  Object.entries(role.permissions).forEach(([permissionName, permission]) => {
    // Fix up boolean enabled values to the enabled state
    permission.enabled = permission.enabled === true ? ENABLED_FOR_ALL : ENABLED_FOR_NONE
    const group_name = permission.group
    if (group_name) {
      if (!groups[group_name]) {
        groups[group_name] = {
          enabled: [],
          explicit: [],
          locked: [],
          readonly: [],
          granular_permissions: [],
        }
      }
      // We need to get all of the permissions in a group, to determine
      // what the button status will be for the encompassing permission
      if (
        (courseRoleTypes.includes(role.base_role_type) &&
          accountPermissionsByName &&
          !accountPermissionsByName.includes(permissionName)) ||
        accountRoleTypes.includes(role.base_role_type)
      ) {
        groups[group_name].enabled.push(permission.enabled)
        groups[group_name].explicit.push(permission.explicit)
        groups[group_name].locked.push(permission.locked)
        groups[group_name].readonly.push(permission.readonly)
        groups[group_name].granular_permissions.push(permission)
      }
    }
  })

  Object.entries(groups).forEach(([group_name, group]) => {
    role.permissions[group_name] = {
      built_from_granular_permissions: true,
      enabled: groupPermissionEnabled(group.enabled),
      explicit: group.explicit.some(bool => bool),
      locked: group.locked.every(bool => bool),
      readonly: group.readonly.some(bool => bool),
    }
  })
}
