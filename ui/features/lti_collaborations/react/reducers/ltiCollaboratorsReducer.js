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

const initialState = {
  listLTICollaboratorsPending: false,
  listLTICollaboratorsSuccessful: false,
  listLTICollaboratorsError: null,
  ltiCollaboratorsData: [],
}
const ltiCollaboratorsHandlers = {
  LIST_LTI_COLLABORATIONS_START: (state, _action) => {
    state.listLTICollaboratorsPending = true
    state.listLTICollaboratorsSuccessful = false
    state.listLTICollaboratorsError = null
    return state
  },

  LIST_LTI_COLLABORATIONS_SUCCESSFUL: (state, action) => {
    state.listLTICollaboratorsPending = false
    state.listLTICollaboratorsSuccessful = true
    state.ltiCollaboratorsData = action.payload
    return state
  },
  LIST_LTI_COLLABORATIONS_FAILED: (state, action) => {
    state.listLTICollaboratorsPending = false
    state.listLTICollaboratorsError = action.payload
    return state
  },
}

const ltiCollaborators = (state = initialState, action) => {
  if (ltiCollaboratorsHandlers[action.type]) {
    const newState = {...state}
    return ltiCollaboratorsHandlers[action.type](newState, action)
  } else {
    return state
  }
}
export default ltiCollaborators
