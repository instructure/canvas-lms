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
  listCollaborationsPending: false,
  listCollaborationsSuccessful: false,
  listCollaborationsError: null,
  list: [],
}

const collaborationsHandlers = {
  [ACTION_NAMES.LIST_COLLABORATIONS_START]: (state, action) => {
    return {
      ...state,
      list: action.payload ? [] : state.list,
      listCollaborationsPending: true,
      listCollaborationsSuccessful: false,
      listCollaborationsError: null,
    }
  },
  [ACTION_NAMES.LIST_COLLABORATIONS_SUCCESSFUL]: (state, action) => {
    const list = state.list.slice()
    list.push(...action.payload.collaborations)
    return {
      ...state,
      listCollaborationsPending: false,
      listCollaborationsSuccessful: true,
      list,
      nextPage: action.payload.next,
    }
  },
  [ACTION_NAMES.LIST_COLLABORATIONS_FAILED]: (state, action) => {
    return {
      ...state,
      listCollaborationsPending: false,
      listCollaborationsError: action.payload,
    }
  },
  [ACTION_NAMES.CREATE_COLLABORATION_SUCCESSFUL]: (state, _action) => {
    return {
      ...state,
      list: [],
      nextPage: null,
    }
  },
  [ACTION_NAMES.DELETE_COLLABORATION_SUCCESSFUL]: (state, _action) => {
    return {
      ...state,
      list: [],
      nextPage: null,
    }
  },
}

export default (state = initialState, action) => {
  if (collaborationsHandlers[action.type]) {
    return collaborationsHandlers[action.type](state, action)
  } else {
    return state
  }
}
