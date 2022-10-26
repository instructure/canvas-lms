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

import createPermissionsIndex from './react/index'
import {
  COURSE,
  ACCOUNT,
  ALL_ROLES_VALUE,
  ALL_ROLES_LABEL,
} from '@canvas/permissions/react/propTypes'
import {getSortedRoles, groupGranularPermissionsInRole} from '@canvas/permissions/util'
import ready from '@instructure/ready'

ready(() => {
  const root = document.querySelector('#content')

  // The ENV variables containing the permissions are an array of:
  // { group_name: "foo" group_permissions: [array of permissions] }
  // so we want to flatten this out to just the permissions.
  const flattenPermissions = perms => perms.flatMap(item => item.group_permissions)

  function groupGranularPermissions(permissions) {
    const [permissionsList, groups] = permissions.reduce(
      (acc, p) => {
        const [permissionsList, groups] = acc

        if (p.granular_permission_group) {
          if (!groups[p.granular_permission_group]) {
            groups[p.granular_permission_group] = []
          }
          groups[p.granular_permission_group].push(p)
        } else {
          permissionsList.push(p)
        }

        return acc
      },
      [[], {}]
    )

    Object.entries(groups).forEach(([group_name, group_permissions]) => {
      permissionsList.push({
        label: group_permissions[0].granular_permission_group_label,
        permission_name: group_name,
        granular_permissions: group_permissions,
      })
    })

    return permissionsList.sort(function (a, b) {
      if (a.label > b.label) return 1
      if (a.label < b.label) return -1
      return 0
    })
  }

  function markAndCombineArrays(courseArray, accountArray) {
    const markedCourses = courseArray.map(a => ({...a, contextType: COURSE, displayed: true}))
    const markedAccounts = accountArray.map(a => ({...a, contextType: ACCOUNT, displayed: false}))
    return markedCourses.concat(markedAccounts)
  }

  function isAlert(element) {
    return element.permission_name === 'manage_interaction_alerts'
  }

  // Don't display the alert permission if the alert feature isn't enabled
  const permissions = flattenPermissions(ENV.COURSE_PERMISSIONS)
  if (!ENV.ACCOUNT_ENABLE_ALERTS) {
    permissions.splice(permissions.findIndex(isAlert), 1)
  }

  // Find the account admin role, give it permission-related properties
  const accountAdmin = ENV.ACCOUNT_ROLES.find(element => element.role === 'AccountAdmin')
  accountAdmin.displayed = false
  accountAdmin.contextType = 'Account'

  const roles = markAndCombineArrays(ENV.COURSE_ROLES, ENV.ACCOUNT_ROLES)
  roles.forEach(role => groupGranularPermissionsInRole(role))

  const initialState = {
    contextId: ENV.ACCOUNT_ID, // This is at present always an account, I think?
    permissions: markAndCombineArrays(
      groupGranularPermissions(permissions),
      groupGranularPermissions(flattenPermissions(ENV.ACCOUNT_PERMISSIONS))
    ),
    roles: getSortedRoles(roles, accountAdmin),
    selectedRoles: [{value: ALL_ROLES_VALUE, label: ALL_ROLES_LABEL}],
  }

  const app = createPermissionsIndex(root, initialState)

  app.render()
})
