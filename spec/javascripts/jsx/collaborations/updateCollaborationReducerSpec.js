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

import reducer from 'jsx/collaborations/reducers/updateCollaborationReducer'

import actions from 'jsx/collaborations/actions/collaborationsActions'

QUnit.module('updateCollaborationReducer')

const defaultState = reducer(undefined, {})

test('has defaults', () => {
  equal(defaultState.updateCollaborationPending, false)
  equal(defaultState.updateCollaborationSuccessful, false)
  equal(defaultState.updateCollaborationError, null)
})

test('responds to updateCollaborationStart', () => {
  const initialState = {
    updateCollaborationPending: false,
    updateCollaborationSuccessful: false,
    updateCollaborationError: {}
  }

  const action = actions.updateCollaborationStart()
  const newState = reducer(initialState, action)

  equal(newState.updateCollaborationPending, true)
  equal(newState.updateCollaborationSuccessful, false)
  equal(newState.updateCollaborationError, null)
})

test('responds to updateCollaborationSuccessful', () => {
  const initialState = {
    updateCollaborationPending: true,
    updateCollaborationSuccessful: false
  }

  const action = actions.updateCollaborationSuccessful({})
  const newState = reducer(initialState, action)

  equal(newState.updateCollaborationPending, false)
  equal(newState.updateCollaborationSuccessful, true)
})

test('responds to updateCollaborationFailed', () => {
  const initialState = {
    updateCollaborationPending: true,
    updateCollaborationError: null
  }

  const error = {}

  const action = actions.updateCollaborationFailed(error)
  const newState = reducer(initialState, action)

  equal(newState.updateCollaborationPending, false)
  equal(newState.updateCollaborationError, error)
})
