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

import ACTION_NAMES from '../actions'

const initialState = {
  deleteCollaborationPending: false,
  deleteCollaborationSuccessful: false,
  deleteCollaborationError: null,
}

const deleteHandlers = {
  [ACTION_NAMES.DELETE_COLLABORATION_START]: (state, _action) => {
    return {
      ...state,
      deleteCollaborationPending: true,
      deleteCollaborationSuccessful: false,
      deleteCollaborationError: null,
    }
  },
  [ACTION_NAMES.DELETE_COLLABORATION_SUCCESSFUL]: (state, _action) => {
    return {
      ...state,
      deleteCollaborationPending: false,
      deleteCollaborationSuccessful: true,
    }
  },
  [ACTION_NAMES.DELETE_COLLABORATION_FAILED]: (state, action) => {
    return {
      ...state,
      deleteCollaborationPending: false,
      deleteCollaborationError: action.payload,
    }
  },
}

export default (state = initialState, action) => {
  if (deleteHandlers[action.type]) {
    return deleteHandlers[action.type](state, action)
  } else {
    return state
  }
}
