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
import reducer from 'ui/features/developer_keys_v2/react/reducers/makeInvisibleReducer'

QUnit.module('makeInvisibleReducer')

const defaults = reducer(undefined, {})

test('there are defaults', () => {
  equal(defaults.makeInvisibleDeveloperKeyPending, false)
  equal(defaults.makeInvisibleDeveloperKeySuccessful, false)
  equal(defaults.makeInvisibleDeveloperKeyError, null)
})

test('responds to makeInvisibleDeveloperKeyStart', () => {
  const state = {
    makeInvisibleDeveloperKeyPending: false,
    makeInvisibleDeveloperKeySuccessful: true,
    makeInvisibleDeveloperKeyError: {},
  }

  const action = actions.makeInvisibleDeveloperKeyStart()
  const newState = reducer(state, action)
  equal(newState.makeInvisibleDeveloperKeyPending, true)
  equal(newState.makeInvisibleDeveloperKeySuccessful, false)
  equal(newState.makeInvisibleDeveloperKeyError, null)
})

test('responds to makeInvisibleDeveloperKeySuccessful', () => {
  const state = {
    makeInvisibleDeveloperKeyPending: true,
    makeInvisibleDeveloperKeySuccessful: false,
  }
  const payload = {}
  const action = actions.makeInvisibleDeveloperKeySuccessful(payload)
  const newState = reducer(state, action)
  equal(newState.makeInvisibleDeveloperKeyPending, false)
  equal(newState.makeInvisibleDeveloperKeySuccessful, true)
})

test('responds to makeInvisibleDeveloperKeyFailed', () => {
  const state = {
    makeInvisibleDeveloperKeyPending: true,
    makeInvisibleDeveloperKeyError: null,
  }
  const error = {}

  const action = actions.makeInvisibleDeveloperKeyFailed(error)
  const newState = reducer(state, action)
  equal(newState.makeInvisibleDeveloperKeyPending, false)
  equal(newState.makeInvisibleDeveloperKeyError, error)
})
