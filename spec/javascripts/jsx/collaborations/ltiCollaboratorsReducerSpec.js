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

import reducer from 'ui/features/lti_collaborations/react/reducers/ltiCollaboratorsReducer'

import actions from 'ui/features/lti_collaborations/react/actions'

QUnit.module('ltiCollaboratorsReducer')

const defaults = reducer(undefined, {})

test('there are defaults', () => {
  equal(Array.isArray(defaults.ltiCollaboratorsData), true)
  equal(defaults.ltiCollaboratorsData.length, 0)
  equal(defaults.listLTICollaboratorsPending, false)
  equal(defaults.listLTICollaboratorsSuccessful, false)
  equal(defaults.listLTICollaboratorsError, null)
})

test('responds to listCollaborationsStart', () => {
  const state = {
    listLTICollaboratorsPending: false,
    listLTICollaboratorsSuccessful: true,
    listLTICollaboratorsError: {},
  }

  const action = actions.listLTICollaborationsStart()
  const newState = reducer(state, action)
  equal(newState.listLTICollaboratorsPending, true)
  equal(newState.listLTICollaboratorsSuccessful, false)
  equal(newState.listLTICollaboratorsError, null)
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
  equal(newState.listLTICollaboratorsPending, false)
  equal(newState.listLTICollaboratorsSuccessful, true)
  equal(newState.ltiCollaboratorsData, ltiCollaboratorsData)
})

test('responds to listLTICollaborationsFailed', () => {
  const state = {
    listLTICollaboratorsPending: true,
    listLTICollaboratorsError: null,
  }
  const error = {}

  const action = actions.listLTICollaborationsFailed(error)
  const newState = reducer(state, action)
  equal(newState.listLTICollaboratorsPending, false)
  equal(newState.listLTICollaboratorsError, error)
})
