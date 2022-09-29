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

import IndexMenuActions from '../actions/IndexMenuActions'

const {SET_MODAL_OPEN, LAUNCH_TOOL, SET_TOOLS, SET_WEIGHTED} = IndexMenuActions

const initialState = {
  externalTools: [],
  modalIsOpen: false,
  selectedTool: null,
  weighted: false,
}

const handlers = {
  [SET_MODAL_OPEN]: (state, action) => {
    const newState = {...state, modalIsOpen: action.payload}
    return newState
  },

  [LAUNCH_TOOL]: (state, action) => {
    const newState = {...state, selectedTool: action.payload, modalIsOpen: true}
    return newState
  },

  [SET_TOOLS]: (state, action) => {
    const newState = {...state, externalTools: action.payload}

    return newState
  },

  [SET_WEIGHTED]: (state, action) => {
    const newState = {...state, weighted: action.payload}

    return newState
  },
}

function reducer(state, action) {
  const prevState = state || initialState
  const handler = handlers[action.type]

  if (handler) return handler(prevState, action)

  return prevState
}

export default reducer
