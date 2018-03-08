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
import searchReducerMap from './searchReducerMap'
import deleteReducerMap from './deleteReducerMap'

function copyAndUpdateDiscussionState(oldState, updatedDiscussion) {
  const newState = oldState.slice()
  const discussionIndex = newState.map(d => d.id).indexOf(updatedDiscussion.id)

  if ((updatedDiscussion.pinned || updatedDiscussion.locked) && discussionIndex !== -1) {
    newState.splice(discussionIndex, 1)
  } else if (!updatedDiscussion.pinned && !updatedDiscussion.locked && discussionIndex === -1) {
    newState.unshift(updatedDiscussion)
  } else if (!updatedDiscussion.pinned && !updatedDiscussion.locked && discussionIndex !== -1) {
    newState[discussionIndex] = updatedDiscussion
  }
  return newState
}

const reducerMap = {
  [actionTypes.GET_DISCUSSIONS_SUCCESS]: (state, action) => {
    const discussions = action.payload.data || []
    const unpinnedDiscussions = discussions.reduce((accumlator, discussion) => {
      if (!discussion.pinned && !discussion.locked) {
        accumlator.push({ ...discussion, filtered: false })
      }
      return accumlator
    }, [])
    return orderBy(unpinnedDiscussions, ((d) => new Date(d.last_reply_at)), ['desc'])
  },
  [actionTypes.UPDATE_DISCUSSION_START]: (state, action) => (
    copyAndUpdateDiscussionState(state, action.payload.discussion)
  ),
  [actionTypes.UPDATE_DISCUSSION_FAIL]: (state, action) => (
    copyAndUpdateDiscussionState(state, action.payload.discussion)
  ),
}

Object.assign(reducerMap, subscriptionReducerMap, duplicationReducerMap,
              cleanDiscussionFocusReducerMap, searchReducerMap, deleteReducerMap)

const unpinnedDiscussionReducer = handleActions(reducerMap, [])
export default unpinnedDiscussionReducer
