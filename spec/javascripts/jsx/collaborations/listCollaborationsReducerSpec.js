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

import reducer from 'ui/features/lti_collaborations/react/reducers/listCollaborationsReducer'

import actions from 'ui/features/lti_collaborations/react/actions'

QUnit.module('collaborationsReducer')

const defaults = reducer(undefined, {})

test('there are defaults', () => {
  equal(Array.isArray(defaults.list), true)
  equal(defaults.list.length, 0)
  equal(defaults.listCollaborationsPending, false)
  equal(defaults.listCollaborationsSuccessful, false)
  equal(defaults.listCollaborationsError, null)
})

test('responds to listCollaborationsStart', () => {
  const state = {
    listCollaborationsPending: false,
    listCollaborationsSuccessful: true,
    listCollaborationsError: {},
  }

  const action = actions.listCollaborationsStart()
  const newState = reducer(state, action)
  equal(newState.listCollaborationsPending, true)
  equal(newState.listCollaborationsSuccessful, false)
  equal(newState.listCollaborationsError, null)
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
  equal(newState.listCollaborationsPending, false)
  equal(newState.listCollaborationsSuccessful, true)
  equal(newState.list.length, payload.collaborations.length)
})

test('responds to listCollaborationsFailed', () => {
  const state = {
    listCollaborationsPending: true,
    listCollaborationsError: null,
  }
  const error = {}

  const action = actions.listCollaborationsFailed(error)
  const newState = reducer(state, action)
  equal(newState.listCollaborationsPending, false)
  equal(newState.listCollaborationsError, error)
})
