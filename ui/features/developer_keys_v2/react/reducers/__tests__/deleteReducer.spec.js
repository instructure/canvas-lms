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
import reducer from '../deleteReducer'

describe('deleteDeveloperKeyReducer', () => {
  let defaults

  beforeEach(() => {
    defaults = reducer(undefined, {})
  })

  test('there are defaults', () => {
    expect(defaults.deleteDeveloperKeyPending).toBe(false)
    expect(defaults.deleteDeveloperKeySuccessful).toBe(false)
    expect(defaults.deleteDeveloperKeyError).toBe(null)
  })

  test('responds to deleteDeveloperKeyStart', () => {
    const state = {
      deleteDeveloperKeyPending: false,
      deleteDeveloperKeySuccessful: true,
      deleteDeveloperKeyError: {},
    }

    const action = actions.deleteDeveloperKeyStart()
    const newState = reducer(state, action)
    expect(newState.deleteDeveloperKeyPending).toBe(true)
    expect(newState.deleteDeveloperKeySuccessful).toBe(false)
    expect(newState.deleteDeveloperKeyError).toBe(null)
  })

  test('responds to deleteDeveloperKeySuccessful', () => {
    const state = {
      deleteDeveloperKeyPending: true,
      deleteDeveloperKeySuccessful: false,
    }
    const payload = {}
    const action = actions.deleteDeveloperKeySuccessful(payload)
    const newState = reducer(state, action)
    expect(newState.deleteDeveloperKeyPending).toBe(false)
    expect(newState.deleteDeveloperKeySuccessful).toBe(true)
  })

  test('responds to deleteDeveloperKeyFailed', () => {
    const state = {
      deleteDeveloperKeyPending: true,
      deleteDeveloperKeyError: null,
    }
    const error = {}

    const action = actions.deleteDeveloperKeyFailed(error)
    const newState = reducer(state, action)
    expect(newState.deleteDeveloperKeyPending).toBe(false)
    expect(newState.deleteDeveloperKeyError).toBe(error)
  })
})
