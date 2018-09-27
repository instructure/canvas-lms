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

import reducer from 'jsx/collaborations/reducers/createCollaborationReducer'
import actions from 'jsx/collaborations/actions/collaborationsActions'

QUnit.module('createCollaborationReducer')

const defaults = reducer(undefined, {})

test('there are defaults', () => {
  equal(defaults.createCollaborationPending, false)
  equal(defaults.createCollaborationSuccessful, false)
  equal(defaults.createCollaborationError, null)
})

test('responds to createCollaborationStart', () => {
  const state = {
    createCollaborationPending: false,
    createCollaborationSuccessful: true,
    createCollaborationError: {}
  }

  const action = actions.createCollaborationStart()
  const newState = reducer(state, action)
  equal(newState.createCollaborationPending, true)
  equal(newState.createCollaborationSuccessful, false)
  equal(newState.createCollaborationError, null)
})

test('responds to createCollaborationSuccessful', () => {
  const state = {
    createCollaborationPending: true,
    createCollaborationSuccessful: false,
    collaborations: []
  }
  const collaborations = [{}]

  const action = actions.createCollaborationSuccessful(collaborations)
  const newState = reducer(state, action)
  equal(newState.createCollaborationPending, false)
  equal(newState.createCollaborationSuccessful, true)
})

test('responds to createCollaborationFailed', () => {
  const state = {
    createCollaborationPending: true,
    createCollaborationError: null
  }
  const error = {}

  const action = actions.createCollaborationFailed(error)
  const newState = reducer(state, action)
  equal(newState.createCollaborationPending, false)
  equal(newState.createCollaborationError, error)
})
