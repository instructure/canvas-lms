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
import cleanDiscussionFocusReducerMap from './cleanDiscussionFocusReducerMap'

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
    newState.unshift(updatedDiscussion)
  } else if (updatedDiscussion.pinned && discussionIndex !== -1) {
    newState[discussionIndex] = updatedDiscussion
  }
  return newState
}

const reducerMap = {
  [actionTypes.ARRANGE_PINNED_DISCUSSIONS]: (state, action) => {
    if (!action.payload.order) {
      return state
    }
    const oldDiscussionList = state.slice()
    const newPinnedDiscussions = action.payload.order.map(id => {
      const currentDiscussion = oldDiscussionList.find(
        discussion => discussion.id === id
      )
      return currentDiscussion
    })
    return newPinnedDiscussions
  },
  [actionTypes.GET_DISCUSSIONS_SUCCESS]: (state, action) => {
    let pinnedDiscussions = []
    if (action.payload.data) {
      pinnedDiscussions = action.payload.data.filter(disc => disc.pinned)
    }
    return orderBy(pinnedDiscussions, ['position'], ['asc'])
  },
  [actionTypes.UPDATE_DISCUSSION_START]: (state, action) =>
    copyAndUpdateDiscussionState(state, action.payload.discussion),
  [actionTypes.UPDATE_DISCUSSION_FAIL]: (state, action) =>
    copyAndUpdateDiscussionState(state, action.payload.discussion)
}

Object.assign(reducerMap, subscriptionReducerMap)
Object.assign(reducerMap, duplicationReducerMap)
Object.assign(reducerMap, cleanDiscussionFocusReducerMap)

const pinnedDiscussionReducer = handleActions(reducerMap, [])
export default pinnedDiscussionReducer
