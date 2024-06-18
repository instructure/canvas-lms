/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import reducer from '../updateCollaborationReducer'
import actions from '../../actions'

describe('updateCollaborationReducer', () => {
  const defaultState = reducer(undefined, {})

  test('has defaults', () => {
    expect(defaultState.updateCollaborationPending).toBe(false)
    expect(defaultState.updateCollaborationSuccessful).toBe(false)
    expect(defaultState.updateCollaborationError).toBeNull()
  })

  test('responds to updateCollaborationStart', () => {
    const initialState = {
      updateCollaborationPending: false,
      updateCollaborationSuccessful: false,
      updateCollaborationError: {},
    }

    const action = actions.updateCollaborationStart()
    const newState = reducer(initialState, action)

    expect(newState.updateCollaborationPending).toBe(true)
    expect(newState.updateCollaborationSuccessful).toBe(false)
    expect(newState.updateCollaborationError).toBeNull()
  })

  test('responds to updateCollaborationSuccessful', () => {
    const initialState = {
      updateCollaborationPending: true,
      updateCollaborationSuccessful: false,
    }

    const action = actions.updateCollaborationSuccessful({})
    const newState = reducer(initialState, action)

    expect(newState.updateCollaborationPending).toBe(false)
    expect(newState.updateCollaborationSuccessful).toBe(true)
  })

  test('responds to updateCollaborationFailed', () => {
    const initialState = {
      updateCollaborationPending: true,
      updateCollaborationError: null,
    }

    const error = {}

    const action = actions.updateCollaborationFailed(error)
    const newState = reducer(initialState, action)

    expect(newState.updateCollaborationPending).toBe(false)
    expect(newState.updateCollaborationError).toBe(error)
  })
})
