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
    'jsx/collaborations/reducers/updateCollaborationReducer',
    'jsx/collaborations/actions/collaborationsActions'
  ],
  (reducer, actions) => {
    QUnit.module('updateCollaborationReducer')

    let defaultState = reducer(undefined, {})

    test('has defaults', () => {
      equal(defaultState.updateCollaborationPending, false)
      equal(defaultState.updateCollaborationSuccessful, false)
      equal(defaultState.updateCollaborationError, null)
    })

    test('responds to updateCollaborationStart', () => {
      let initialState = {
        updateCollaborationPending: false,
        updateCollaborationSuccessful: false,
        updateCollaborationError: {}
      }

      let action = actions.updateCollaborationStart()
      let newState = reducer(initialState, action)

      equal(newState.updateCollaborationPending, true)
      equal(newState.updateCollaborationSuccessful, false)
      equal(newState.updateCollaborationError, null)
    })

    test('responds to updateCollaborationSuccessful', () => {
      let initialState = {
        updateCollaborationPending: true,
        updateCollaborationSuccessful: false
      }

      let action = actions.updateCollaborationSuccessful({})
      let newState = reducer(initialState, action)

      equal(newState.updateCollaborationPending, false)
      equal(newState.updateCollaborationSuccessful, true)
    })

    test('responds to updateCollaborationFailed', () => {
      let initialState = {
        updateCollaborationPending: true,
        updateCollaborationError: null
      }

      let error = {}

      let action = actions.updateCollaborationFailed(error)
      let newState = reducer(initialState, action)

      equal(newState.updateCollaborationPending, false)
      equal(newState.updateCollaborationError, error)
    })
  }
)
