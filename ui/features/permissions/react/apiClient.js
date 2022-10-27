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

import axios from '@canvas/axios'
// For now, context is always an account, so just pass the id

// Here is an example API call.
//
// export function getPermissions (contextId) {
//   return axios.get(`/api/v1/accounts/${contextId}/permissions`)
// }

export function postNewRole({contextId}, label, role) {
  return axios.post(`/api/v1/accounts/${contextId}/roles`, {
    label,
    base_role_type: role.base_role_type,
  })
}

export function updateRole(contextID, roleID, putData) {
  return axios.put(`/api/v1/accounts/${contextID}/roles/${roleID}`, putData)
}

export function deleteRole(contextId, role) {
  return axios.delete(`/api/v1/accounts/${contextId}/roles/${role.id}`)
}

// TODO there does not currently exist an API for this, and because of
//      reasons we cannot just change the individual permissions to be
//      the same as the base role. This will need to be fixed on endpoint
//      before we can do anything with it here.

export function updateBaseRole({contextId: _contextId}, _role, _baseRole) {
  throw new Error('API does not currently support updating the base role')
}
