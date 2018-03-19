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

import ACTION_NAMES from '../actions/developerKeysActions'

const initialState = {
  setBindingWorkflowStatePending: false,
  setBindingWorkflowStateSuccessful: false,
  setBindingWorkflowStateError: null
}

const developerKeysHandlers = {
  [ACTION_NAMES.SET_BINDING_WORKFLOW_STATE_START]: state => ({
    ...state,
    setBindingWorkflowStatePending: true,
    setBindingWorkflowStateSuccessful: false,
    setBindingWorkflowStateError: null
  }),
  [ACTION_NAMES.SET_BINDING_WORKFLOW_STATE_SUCCESSFUL]: state => ({
    ...state,
    setBindingWorkflowStatePending: false,
    setBindingWorkflowStateSuccessful: true
  }),
  [ACTION_NAMES.SET_BINDING_WORKFLOW_STATE_FAILED]: state => ({
    ...state,
    setBindingWorkflowStatePending: false,
    setBindingWorkflowStateError: true
  })
}

export default (state = initialState, action) => {
  if (developerKeysHandlers[action.type]) {
    return developerKeysHandlers[action.type](state, action)
  } else {
    return state
  }
}
