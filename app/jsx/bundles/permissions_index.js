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

import createPermissionsIndex from 'jsx/permissions'

const root = document.querySelector('#content')

// We only want a 1-level flatten
function flatten(arr) {
  let result = []
  arr.forEach(a => {
    result = result.concat(a)
  })
  return result
}

// The ENV variables containing the permissions are an array of:
// { group_name: "foo" group_permissions: [array of permissions] }
// so we want to flatten this out to just the permissions.
function flattenPermissions(permissionsFromEnv) {
  return flatten(permissionsFromEnv.map(item => item.group_permissions))
}

const app = createPermissionsIndex(root, {
  contextId: ENV.ACCOUNT_ID, // This is at present always an account, I think?
  accountPermissions: flattenPermissions(ENV.ACCOUNT_PERMISSIONS),
  coursePermissions: flattenPermissions(ENV.COURSE_PERMISSIONS),
  accountRoles: ENV.ACCOUNT_ROLES,
  courseRoles: ENV.COURSE_ROLES
})

app.render()
