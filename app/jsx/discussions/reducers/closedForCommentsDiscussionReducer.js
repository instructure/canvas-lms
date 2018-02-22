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
import subscriptionReducerMap from './subscriptionReducerMap'

function copyAndUpdateDiscussionState(oldState, updatedDiscussion) {
  const newState = oldState.filter((disc) => disc.id !== updatedDiscussion.id)
  if (!updatedDiscussion.pinned && updatedDiscussion.locked) {
    newState.push(updatedDiscussion)
  }
  return newState
}

const reducerMap = {
  [actionTypes.GET_DISCUSSIONS_SUCCESS]: (state, action) => {
    let closedDiscussions = []
    if(action.payload.data) {
      closedDiscussions = action.payload.data.filter((disc) => !disc.pinned && disc.locked)
    }
    return closedDiscussions
  },
  [actionTypes.UPDATE_DISCUSSION_START]: (state, action) => (
    copyAndUpdateDiscussionState(state, action.payload.discussion)
  ),
  [actionTypes.UPDATE_DISCUSSION_FAIL]: (state, action) => (
    copyAndUpdateDiscussionState(state, action.payload.discussion)
  ),
}

Object.assign(reducerMap, subscriptionReducerMap)
const closedForCommentsDiscussionReducer = handleActions(reducerMap, [])
export default closedForCommentsDiscussionReducer
