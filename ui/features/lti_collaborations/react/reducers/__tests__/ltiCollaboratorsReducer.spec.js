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

import reducer from '../ltiCollaboratorsReducer'
import actions from '../../actions'

describe('ltiCollaboratorsReducer', () => {
  const defaults = reducer(undefined, {})

  test('there are defaults', () => {
    expect(Array.isArray(defaults.ltiCollaboratorsData)).toBe(true)
    expect(defaults.ltiCollaboratorsData.length).toBe(0)
    expect(defaults.listLTICollaboratorsPending).toBe(false)
    expect(defaults.listLTICollaboratorsSuccessful).toBe(false)
    expect(defaults.listLTICollaboratorsError).toBeNull()
  })

  test('responds to listCollaborationsStart', () => {
    const state = {
      listLTICollaboratorsPending: false,
      listLTICollaboratorsSuccessful: true,
      listLTICollaboratorsError: {},
    }

    const action = actions.listLTICollaborationsStart()
    const newState = reducer(state, action)
    expect(newState.listLTICollaboratorsPending).toBe(true)
    expect(newState.listLTICollaboratorsSuccessful).toBe(false)
    expect(newState.listLTICollaboratorsError).toBeNull()
  })

  test('responds to listLTICollaborationsSuccessful', () => {
    const state = {
      listLTICollaboratorsPending: true,
      listLTICollaboratorsSuccessful: false,
      ltiCollaboratorsData: [],
    }
    const ltiCollaboratorsData = []

    const action = actions.listLTICollaborationsSuccessful(ltiCollaboratorsData)
    const newState = reducer(state, action)
    expect(newState.listLTICollaboratorsPending).toBe(false)
    expect(newState.listLTICollaboratorsSuccessful).toBe(true)
    expect(newState.ltiCollaboratorsData).toEqual(ltiCollaboratorsData)
  })

  test('responds to listLTICollaborationsFailed', () => {
    const state = {
      listLTICollaboratorsPending: true,
      listLTICollaboratorsError: null,
    }
    const error = {}

    const action = actions.listLTICollaborationsFailed(error)
    const newState = reducer(state, action)
    expect(newState.listLTICollaboratorsPending).toBe(false)
    expect(newState.listLTICollaboratorsError).toEqual(error)
  })
})
