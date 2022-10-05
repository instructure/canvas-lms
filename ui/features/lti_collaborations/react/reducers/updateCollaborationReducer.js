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
  updateCollaborationPending: false,
  updateCollaborationSuccessful: false,
  updateCollaborationError: null,
}

const updateHandlers = {
  [ACTION_NAMES.UPDATE_COLLABORATION_START]: (state, _action) => {
    return {
      ...state,
      updateCollaborationPending: true,
      updateCollaborationSuccessful: false,
      updateCollaborationError: null,
    }
  },
  [ACTION_NAMES.UPDATE_COLLABORATION_SUCCESSFUL]: (state, _action) => {
    return {
      ...state,
      updateCollaborationPending: false,
      updateCollaborationSuccessful: true,
    }
  },
  [ACTION_NAMES.UPDATE_COLLABORATION_FAILED]: (state, action) => {
    return {
      ...state,
      updateCollaborationPending: false,
      updateCollaborationError: action.payload,
    }
  },
}

const updateReducer = (state = initialState, action) => {
  if (updateHandlers[action.type]) {
    return updateHandlers[action.type](state, action)
  } else {
    return state
  }
}

export default updateReducer
