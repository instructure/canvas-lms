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

import doFetchApi from '@canvas/do-fetch-api-effect'
// For now, context is always an account, so just pass the id

export function postNewRole({contextId}, label, role) {
  return doFetchApi({
    path: `/api/v1/accounts/${contextId}/roles`,
    method: 'POST',
    body: {label, base_role_type: role.base_role_type},
  })
}

export function updateRole(contextID, roleID, putData) {
  return doFetchApi({
    path: `/api/v1/accounts/${contextID}/roles/${roleID}`,
    method: 'PUT',
    body: putData,
  })
}

export function deleteRole(contextId, role) {
  return doFetchApi({
    path: `/api/v1/accounts/${contextId}/roles/${role.id}`,
    method: 'DELETE',
  })
}

// TODO there does not currently exist an API for this, and because of
//      reasons we cannot just change the individual permissions to be
//      the same as the base role. This will need to be fixed on endpoint
//      before we can do anything with it here.

export function updateBaseRole({contextId: _contextId}, _role, _baseRole) {
  throw new Error('API does not currently support updating the base role')
}
