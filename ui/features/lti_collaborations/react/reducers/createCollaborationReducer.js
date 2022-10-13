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
  createCollaborationPending: false,
  createCollaborationSuccessful: false,
  createCollaborationError: null,
}

const createHandlers = {
  [ACTION_NAMES.CREATE_COLLABORATION_START]: (state, _action) => {
    return {
      ...state,
      createCollaborationPending: true,
      createCollaborationSuccessful: false,
      createCollaborationError: null,
    }
  },
  [ACTION_NAMES.CREATE_COLLABORATION_SUCCESSFUL]: (state, _action) => {
    return {
      ...state,
      createCollaborationPending: false,
      createCollaborationSuccessful: true,
    }
  },
  [ACTION_NAMES.CREATE_COLLABORATION_FAILED]: (state, action) => {
    return {
      ...state,
      createCollaborationPending: false,
      createCollaborationError: action.payload,
    }
  },
}

export default (state = initialState, action) => {
  if (createHandlers[action.type]) {
    return createHandlers[action.type](state, action)
  } else {
    return state
  }
}
