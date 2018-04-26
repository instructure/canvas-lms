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

import actions from 'jsx/developer_keys/actions/developerKeysActions'
import reducer from 'jsx/developer_keys/reducers/listDeveloperKeyScopesReducer'

QUnit.module('listDeveloperKeyScopesReducer')

const defaults = reducer(undefined, {})

test('there are defaults', () => {
  deepEqual(defaults.availableScopes, {})
  equal(defaults.listDeveloperKeyScopesPending, false)
  equal(defaults.listDeveloperKeyScopesSuccessful, false)
  equal(defaults.listDeveloperKeyScopesError, undefined)
})

test('responds to listDeveloperKeyScopesStart', () => {
  const state = defaults
  const action = actions.listDeveloperKeyScopesStart()
  const newState = reducer(state, action)

  deepEqual(newState.availableScopes, {})
  equal(newState.listDeveloperKeyScopesPending, true)
  equal(newState.listDeveloperKeyScopesSuccessful, false)
  equal(newState.listDeveloperKeyScopesError, undefined)
})

test('responds to listDeveloperKeyScopesSuccessful', () => {
  const state = defaults
  const payload = ['GET|testscope']
  const action = actions.listDeveloperKeyScopesSuccessful(payload)
  const newState = reducer(state, action)

  deepEqual(newState.availableScopes, payload)
  equal(newState.listDeveloperKeyScopesPending, false)
  equal(newState.listDeveloperKeyScopesSuccessful, true)
  equal(newState.listDeveloperKeyScopesError, undefined)
})

test('responds to listDeveloperKeyScopesFailed', () => {
  const state = defaults
  const action = actions.listDeveloperKeyScopesFailed()
  const newState = reducer(state, action)

  deepEqual(newState.availableScopes, {})
  equal(newState.listDeveloperKeyScopesPending, false)
  equal(newState.listDeveloperKeyScopesSuccessful, false)
  equal(newState.listDeveloperKeyScopesError, true)
})