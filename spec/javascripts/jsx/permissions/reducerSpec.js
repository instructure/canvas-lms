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

import actions from 'jsx/permissions/actions'
import reducer from 'jsx/permissions/reducer'

QUnit.module('Discussions reducer')

const reduce = (action, state = {}) => reducer(state, action)

test('GET_PERMISSIONS_SUCCESS does its job', () => {
  const oldState = { isLoadngPermissions: true, hasLoadedPermissions: false, permissions: [] }
  const dispatchData = { "permission1": true, "permission2": true }
  const newState = reduce(actions.getPermissionsSuccess(dispatchData), oldState)
  equal(newState.isLoadingPermissions, false)
  equal(newState.hasLoadedPermissions, true)
  deepEqual(newState.permissions, [ "permission1", "permission2" ])
})
