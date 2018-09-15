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
import orderBy from 'lodash/orderBy'

import {handleActions} from 'redux-actions'
import {actionTypes} from '../actions'
import duplicationReducerMap from './duplicationReducerMap'
import deleteReducerMap from './deleteReducerMap'

// We need to not change the ordering of the diccussions here, ie we can't
// use the same .sort that we use in the GET_DISCUSSIONS_SUCCESS. This is
// because the position/ordering of subsequent stuff in here (via tha move
// menu) is handled by id, and not by position (even though the position
// eventually gets saved in the backend).
function copyAndUpdateDiscussionState(oldState, updatedDiscussion) {
  const newState = oldState.slice()
  const discussionIndex = newState.indexOf(updatedDiscussion.id)

  if (!updatedDiscussion.pinned && discussionIndex !== -1) {
    newState.splice(discussionIndex, 1)
  } else if (updatedDiscussion.pinned && discussionIndex === -1) {
    newState.push(updatedDiscussion.id)
  } else if (updatedDiscussion.pinned && discussionIndex !== -1) {
    newState[discussionIndex] = updatedDiscussion.id
  }
  return newState
}

function orderPinnedDiscussions(state, order) {
  return order ? order.map(id => state.find(discussionId => discussionId === id)) : state
}

const reducerMap = {
  [actionTypes.ARRANGE_PINNED_DISCUSSIONS]: (state, action) => action.payload.order.slice(),
  [actionTypes.GET_DISCUSSIONS_SUCCESS]: (state, action) => {
    const allDiscussions = action.payload.data
    const pinnedDiscussions = allDiscussions.reduce((acc, discussion) => {
      if (discussion.pinned) {
        acc.push(discussion)
      }
      return acc
    }, [])
    const sorted = orderBy(pinnedDiscussions, ['position'], ['asc'])
    return sorted.map(d => d.id)
  },
  [actionTypes.UPDATE_DISCUSSION_SUCCESS]: (state, action) =>
    copyAndUpdateDiscussionState(state, action.payload.discussion),
  [actionTypes.DRAG_AND_DROP_START]: (state, action) => {
    const updatedState = copyAndUpdateDiscussionState(state, action.payload.discussion)
    return orderPinnedDiscussions(updatedState, action.payload.order)
  },
  [actionTypes.DRAG_AND_DROP_FAIL]: (state, action) => {
    const updatedState = copyAndUpdateDiscussionState(state, action.payload.discussion)
    return orderPinnedDiscussions(updatedState, action.payload.order)
  }
}

Object.assign(reducerMap, duplicationReducerMap, deleteReducerMap)

const pinnedDiscussionReducer = handleActions(reducerMap, [])
export default pinnedDiscussionReducer
