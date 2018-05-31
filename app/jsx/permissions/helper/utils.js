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
      const permWithLabel = Object.assign({}, permission, {label, permissionName})
      acc.push(permWithLabel)
    }
    return acc
  }, [])
}

export function roleIsBaseRole(role) {
  // TODO wonder if there is a better way to see if this is the case, or if there
  //      are any situations where this isn't actually the case
  return role.role === role.base_role_type
}
