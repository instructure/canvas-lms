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

import {handleActions} from 'redux-actions'
import {actionTypes} from '../actions'

function setCopyTo(state, action) {
  const newState = {...state}
  if (typeof action.payload.open === 'boolean') {
    newState.open = action.payload.open
  }
  if (typeof action.payload.selection === 'object') {
    newState.selection = action.payload.selection
  }
  return newState
}

function setCopyToOpen(state, action) {
  return {...state, open: action.payload}
}

const reducer = handleActions(
  {
    [actionTypes.SET_COPY_TO_OPEN]: setCopyToOpen,
    [actionTypes.SET_COPY_TO]: setCopyTo,
  },
  {open: false, selection: {}}
)

export default reducer
