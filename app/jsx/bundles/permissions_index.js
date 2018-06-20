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
import {COURSE, ACCOUNT, ALL_ROLES_VALUE, ALL_ROLES_LABEL} from '../permissions/propTypes'
import {getSortedRoles} from '../permissions/helper/utils'

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

function markAndCombineArrays(courseArray, accountArray) {
  const markedCourseArray = courseArray.map((a) => ({...a, contextType: COURSE, displayed: true }))
  const markedAccountArray = accountArray.map((a) => ({...a, contextType: ACCOUNT, displayed: false }))
  return markedCourseArray.concat(markedAccountArray)
}

const initialState = {
  contextId: ENV.ACCOUNT_ID, // This is at present always an account, I think?
  permissions: markAndCombineArrays(flattenPermissions(ENV.COURSE_PERMISSIONS),
  flattenPermissions(ENV.ACCOUNT_PERMISSIONS)),
  roles: getSortedRoles(markAndCombineArrays(ENV.COURSE_ROLES, ENV.ACCOUNT_ROLES)),
  selectedRoles: [{value: ALL_ROLES_VALUE, label: ALL_ROLES_LABEL}]
}

const app = createPermissionsIndex(root, initialState)

app.render()
