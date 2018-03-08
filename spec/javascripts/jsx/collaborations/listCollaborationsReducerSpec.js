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

define(
  [
    'jsx/collaborations/reducers/listCollaborationsReducer',
    'jsx/collaborations/actions/collaborationsActions'
  ],
  (reducer, actions) => {
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
      let state = {
        listCollaborationsPending: false,
        listCollaborationsSuccessful: true,
        listCollaborationsError: {}
      }

      let action = actions.listCollaborationsStart()
      let newState = reducer(state, action)
      equal(newState.listCollaborationsPending, true)
      equal(newState.listCollaborationsSuccessful, false)
      equal(newState.listCollaborationsError, null)
    })

    test('responds to listCollaborationsSuccessful', () => {
      let state = {
        listCollaborationsPending: true,
        listCollaborationsSuccessful: false,
        list: []
      }
      let payload = {collaborations: []}
      let action = actions.listCollaborationsSuccessful(payload)
      let newState = reducer(state, action)
      equal(newState.listCollaborationsPending, false)
      equal(newState.listCollaborationsSuccessful, true)
      equal(newState.list.length, payload.collaborations.length)
    })

    test('responds to listCollaborationsFailed', () => {
      let state = {
        listCollaborationsPending: true,
        listCollaborationsError: null
      }
      let error = {}

      let action = actions.listCollaborationsFailed(error)
      let newState = reducer(state, action)
      equal(newState.listCollaborationsPending, false)
      equal(newState.listCollaborationsError, error)
    })
  }
)
