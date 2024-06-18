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

import reducer from '../listCollaborationsReducer'
import actions from '../../actions'

describe('collaborationsReducer', () => {
  const defaults = reducer(undefined, {})

  test('there are defaults', () => {
    expect(Array.isArray(defaults.list)).toBe(true)
    expect(defaults.list.length).toBe(0)
    expect(defaults.listCollaborationsPending).toBe(false)
    expect(defaults.listCollaborationsSuccessful).toBe(false)
    expect(defaults.listCollaborationsError).toBeNull()
  })

  test('responds to listCollaborationsStart', () => {
    const state = {
      listCollaborationsPending: false,
      listCollaborationsSuccessful: true,
      listCollaborationsError: {},
    }

    const action = actions.listCollaborationsStart()
    const newState = reducer(state, action)
    expect(newState.listCollaborationsPending).toBe(true)
    expect(newState.listCollaborationsSuccessful).toBe(false)
    expect(newState.listCollaborationsError).toBeNull()
  })

  test('responds to listCollaborationsSuccessful', () => {
    const state = {
      listCollaborationsPending: true,
      listCollaborationsSuccessful: false,
      list: [],
    }
    const payload = {collaborations: []}
    const action = actions.listCollaborationsSuccessful(payload)
    const newState = reducer(state, action)
    expect(newState.listCollaborationsPending).toBe(false)
    expect(newState.listCollaborationsSuccessful).toBe(true)
    expect(newState.list.length).toBe(payload.collaborations.length)
  })

  test('responds to listCollaborationsFailed', () => {
    const state = {
      listCollaborationsPending: true,
      listCollaborationsError: null,
    }
    const error = {}

    const action = actions.listCollaborationsFailed(error)
    const newState = reducer(state, action)
    expect(newState.listCollaborationsPending).toBe(false)
    expect(newState.listCollaborationsError).toEqual(error)
  })
})
