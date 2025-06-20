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
import reducer, {DeactivateDeveloperKeyState} from '../deactivateReducer'

describe('deactivateReducer', () => {
  const defaults = reducer(undefined, {type: '' as any})

  test('there are defaults', () => {
    expect(defaults.deactivateDeveloperKeyPending).toBe(false)
    expect(defaults.deactivateDeveloperKeySuccessful).toBe(false)
    expect(defaults.deactivateDeveloperKeyError).toBeNull()
  })

  test('responds to deactivateDeveloperKeyStart', () => {
    const state: DeactivateDeveloperKeyState = {
      deactivateDeveloperKeyPending: false,
      deactivateDeveloperKeySuccessful: true,
      deactivateDeveloperKeyError: {},
    }

    const action = actions.deactivateDeveloperKeyStart({})
    const newState = reducer(state, action)

    expect(newState.deactivateDeveloperKeyPending).toBe(true)
    expect(newState.deactivateDeveloperKeySuccessful).toBe(false)
    expect(newState.deactivateDeveloperKeyError).toBeNull()
  })

  test('responds to deactivateDeveloperKeySuccessful', () => {
    const state: DeactivateDeveloperKeyState = {
      deactivateDeveloperKeyPending: true,
      deactivateDeveloperKeySuccessful: false,
      deactivateDeveloperKeyError: null,
    }
    const payload = {}
    const action = actions.deactivateDeveloperKeySuccessful(payload)
    const newState = reducer(state, action)

    expect(newState.deactivateDeveloperKeyPending).toBe(false)
    expect(newState.deactivateDeveloperKeySuccessful).toBe(true)
  })

  test('responds to deactivateDeveloperKeyFailed', () => {
    const state: DeactivateDeveloperKeyState = {
      deactivateDeveloperKeyPending: true,
      deactivateDeveloperKeyError: null,
      deactivateDeveloperKeySuccessful: false,
    }
    const error = {}

    const action = actions.deactivateDeveloperKeyFailed(error)
    const newState = reducer(state, action)

    expect(newState.deactivateDeveloperKeyPending).toBe(false)
    expect(newState.deactivateDeveloperKeyError).toEqual(error)
  })
})
