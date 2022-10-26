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

import actions from 'ui/features/developer_keys_v2/react/actions/developerKeysActions'
import reducer from 'ui/features/developer_keys_v2/react/reducers/deactivateReducer'

QUnit.module('deactivateReducer')

const defaults = reducer(undefined, {})

test('there are defaults', () => {
  equal(defaults.deactivateDeveloperKeyPending, false)
  equal(defaults.deactivateDeveloperKeySuccessful, false)
  equal(defaults.deactivateDeveloperKeyError, null)
})

test('responds to deactivateDeveloperKeyStart', () => {
  const state = {
    deactivateDeveloperKeyPending: false,
    deactivateDeveloperKeySuccessful: true,
    deactivateDeveloperKeyError: {},
  }

  const action = actions.deactivateDeveloperKeyStart()
  const newState = reducer(state, action)
  equal(newState.deactivateDeveloperKeyPending, true)
  equal(newState.deactivateDeveloperKeySuccessful, false)
  equal(newState.deactivateDeveloperKeyError, null)
})

test('responds to deactivateDeveloperKeySuccessful', () => {
  const state = {
    deactivateDeveloperKeyPending: true,
    deactivateDeveloperKeySuccessful: false,
  }
  const payload = {}
  const action = actions.deactivateDeveloperKeySuccessful(payload)
  const newState = reducer(state, action)
  equal(newState.deactivateDeveloperKeyPending, false)
  equal(newState.deactivateDeveloperKeySuccessful, true)
})

test('responds to deactivateDeveloperKeyFailed', () => {
  const state = {
    deactivateDeveloperKeyPending: true,
    deactivateDeveloperKeyError: null,
  }
  const error = {}

  const action = actions.deactivateDeveloperKeyFailed(error)
  const newState = reducer(state, action)
  equal(newState.deactivateDeveloperKeyPending, false)
  equal(newState.deactivateDeveloperKeyError, error)
})
