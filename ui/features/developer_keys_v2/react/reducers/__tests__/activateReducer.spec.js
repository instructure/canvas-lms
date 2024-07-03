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

import actions from '../../actions/developerKeysActions'
import reducer from '../activateReducer'

describe('activateReducer', () => {
  const defaults = reducer(undefined, {})

  test('there are defaults', () => {
    expect(defaults.activateDeveloperKeyPending).toBe(false)
    expect(defaults.activateDeveloperKeySuccessful).toBe(false)
    expect(defaults.activateDeveloperKeyError).toBeNull()
  })

  test('responds to activateDeveloperKeyStart', () => {
    const state = {
      activateDeveloperKeyPending: false,
      activateDeveloperKeySuccessful: true,
      activateDeveloperKeyError: {},
    }

    const action = actions.activateDeveloperKeyStart()
    const newState = reducer(state, action)

    expect(newState.activateDeveloperKeyPending).toBe(true)
    expect(newState.activateDeveloperKeySuccessful).toBe(false)
    expect(newState.activateDeveloperKeyError).toBeNull()
  })

  test('responds to activateDeveloperKeySuccessful', () => {
    const state = {
      activateDeveloperKeyPending: true,
      activateDeveloperKeySuccessful: false,
    }
    const payload = {}
    const action = actions.activateDeveloperKeySuccessful(payload)
    const newState = reducer(state, action)

    expect(newState.activateDeveloperKeyPending).toBe(false)
    expect(newState.activateDeveloperKeySuccessful).toBe(true)
  })

  test('responds to activateDeveloperKeyFailed', () => {
    const state = {
      activateDeveloperKeyPending: true,
      activateDeveloperKeyError: null,
    }
    const error = {}

    const action = actions.activateDeveloperKeyFailed(error)
    const newState = reducer(state, action)

    expect(newState.activateDeveloperKeyPending).toBe(false)
    expect(newState.activateDeveloperKeyError).toEqual(error)
  })
})
