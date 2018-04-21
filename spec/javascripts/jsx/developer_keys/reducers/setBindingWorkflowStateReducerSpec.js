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

import actions from 'jsx/developer_keys/actions/developerKeysActions'
import reducer from 'jsx/developer_keys/reducers/setBindingWorkflowStateReducer'

QUnit.module('setBindingWorkflowStateReducer')

const defaults = reducer(undefined, {})

test('there are defaults', () => {
  equal(defaults.setBindingWorkflowStatePending, false)
  equal(defaults.setBindingWorkflowStateSuccessful, false)
  equal(defaults.setBindingWorkflowStateError, null)
})

test('responds to setBindingWorkflowStateStart', () => {
  const state = {
    setBindingWorkflowStatePending: false,
    setBindingWorkflowStateSuccessful: true,
    setBindingWorkflowStateError: {}
  }

  const action = actions.setBindingWorkflowStateStart()
  const newState = reducer(state, action)
  equal(newState.setBindingWorkflowStatePending, true)
  equal(newState.setBindingWorkflowStateSuccessful, false)
  equal(newState.setBindingWorkflowStateError, null)
})

test('responds to setBindingWorkflowStateSuccessful', () => {
  const state = {
    setBindingWorkflowStatePending: true,
    setBindingWorkflowStateSuccessful: false
  }

  const action = actions.setBindingWorkflowStateSuccessful()
  const newState = reducer(state, action)
  equal(newState.setBindingWorkflowStatePending, false)
  equal(newState.setBindingWorkflowStateSuccessful, true)
})

test('responds to setBindingWorkflowStateFailed', () => {
  const state = {
    setBindingWorkflowStatePending: true,
    setBindingWorkflowStateSuccessful: false
  }

  const action = actions.setBindingWorkflowStateFailed()
  const newState = reducer(state, action)
  equal(newState.setBindingWorkflowStatePending, false)
  equal(newState.setBindingWorkflowStateError, true)
})
