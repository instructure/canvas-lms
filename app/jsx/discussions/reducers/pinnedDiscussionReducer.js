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

import { handleActions } from 'redux-actions'
import { actionTypes } from '../actions'
import subscriptionReducerMap from './subscriptionReducerMap'
import duplicationReducerMap from './duplicationReducerMap'
import deleteReducerMap from './deleteReducerMap'
import cleanDiscussionFocusReducerMap from './cleanDiscussionFocusReducerMap'
import searchReducerMap from './searchReducerMap'
import { setSortableId } from '../utils'

// We need to not change the ordering of the diccussions here, ie we can't
// use the same .sort that we use in the GET_DISCUSSIONS_SUCCESS. This is
// because the position/ordering of subsequent stuff in here (via tha move
// menu) is handled by id, and not by position (even though the position
// eventually gets saved in the backend).
function copyAndUpdateDiscussionState(oldState, updatedDiscussion) {
  const newState = oldState.slice()
  const discussionIndex = newState.map(d => d.id).indexOf(updatedDiscussion.id)

  if (!updatedDiscussion.pinned && discussionIndex !== -1) {
    newState.splice(discussionIndex, 1)
  } else if (updatedDiscussion.pinned && discussionIndex === -1) {
    newState.push(updatedDiscussion)
  } else if (updatedDiscussion.pinned && discussionIndex !== -1) {
    newState[discussionIndex] = updatedDiscussion
  }
  return newState
}

function orderPinnedDiscussions(state, order) {
  const discussions = order ? order.map(id => state.find(discussion => discussion.id === id)) : state
  return setSortableId(discussions)
}

const reducerMap = {
  [actionTypes.ARRANGE_PINNED_DISCUSSIONS]: (state, action) =>
    orderPinnedDiscussions(state, action.payload.order),
  [actionTypes.GET_DISCUSSIONS_SUCCESS]: (state, action) => {
    const discussions = action.payload.data || []
    const pinnedDiscussions = discussions.reduce((accumlator, discussion) => {
      if (discussion.pinned) {
        accumlator.push({ ...discussion, filtered: false })
      }
      return accumlator
    }, [])
    return setSortableId(orderBy(pinnedDiscussions, ['position'], ['asc']))
  },
  [actionTypes.UPDATE_DISCUSSION_SUCCESS]: (state, action) => (
    copyAndUpdateDiscussionState(state, action.payload.discussion)
  ),
  [actionTypes.DRAG_AND_DROP_START]: (state, action) => {
    const updatedState = copyAndUpdateDiscussionState(state, action.payload.discussion)
    return orderPinnedDiscussions(updatedState, action.payload.order)
  },
  [actionTypes.DRAG_AND_DROP_FAIL]: (state, action) => {
    const updatedState = copyAndUpdateDiscussionState(state, action.payload.discussion)
    return orderPinnedDiscussions(updatedState, action.payload.order)
  }
}

Object.assign(reducerMap, subscriptionReducerMap, duplicationReducerMap, cleanDiscussionFocusReducerMap, searchReducerMap, deleteReducerMap)

const pinnedDiscussionReducer = handleActions(reducerMap, [])
export default pinnedDiscussionReducer
