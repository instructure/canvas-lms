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
import { handleActions } from 'redux-actions'
import { actionTypes } from '../actions'

const closedForCommentsDiscussionReducer = handleActions({
    [actionTypes.GET_DISCUSSIONS_SUCCESS]: (state, action) => {
      let closedDiscussions = []
      if(action.payload.data) {
        closedDiscussions = action.payload.data.filter((disc) => disc.locked)
      }
      return closedDiscussions
    },
    [actionTypes.CLOSE_FOR_COMMENTS_START]: (state, action) => {
      const newState = state.slice()
      newState.push(action.payload.discussion)
      return newState
    },
    [actionTypes.CLOSE_FOR_COMMENTS_FAIL]: (state, action) => state.filter((disc) => disc.id !== action.payload.discussion.id),
    [actionTypes.TOGGLE_PIN_START]: (state, action) => state.filter((disc) => disc.id !== action.payload.discussion.id),
    [actionTypes.TOGGLE_PIN_FAIL]: (state, action) => {
      let newState = state.slice()
      if(action.payload.discussion.locked) {
        newState.push(action.payload.discussion)
      } else {
        newState = state.filter((disc) => disc.id !== action.payload.discussion.id)
      }
      return newState
    },
}, [])
export default closedForCommentsDiscussionReducer
