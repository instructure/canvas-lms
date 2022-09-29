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

// Note that we use 'allDiscussions' instead of 'discussions', as discussions
// is used by the pagination stuff we are using (and really shouldn't be using
// I think, but that's a whole other issue)

const reducerMap = {
  [actionTypes.GET_DISCUSSIONS_SUCCESS]: (state, action) => {
    const allDiscussions = action.payload.data
    return allDiscussions.reduce((obj, discussion) => {
      obj[discussion.id] = {...discussion, filtered: false}
      return obj
    }, {})
  },
  [actionTypes.UPDATE_DISCUSSIONS_SEARCH]: (state, action) => {
    const {filter, searchTerm} = action.payload
    const regex = new RegExp(searchTerm, 'i')

    return Object.keys(state).reduce((obj, id) => {
      const discussion = state[id]
      const searchMatch = regex.test(
        `${discussion.title} ${discussion.author ? discussion.author.display_name : 'anonymous'}`
      )
      const filterMatch =
        filter === 'unread' ? discussion.read_state !== 'read' || discussion.unread_count > 0 : true
      const filtered = !searchMatch || !filterMatch
      obj[id] = {...discussion, filtered}
      return obj
    }, {})
  },
  [actionTypes.TOGGLE_SUBSCRIBE_SUCCESS]: (state, action) => {
    const {id, subscribed} = action.payload
    return Object.keys(state).reduce((obj, key) => {
      const discussion = state[key]
      if (discussion.id === id) {
        obj[discussion.id] = {...discussion, subscribed}
      } else {
        obj[discussion.id] = discussion
      }
      return obj
    }, {})
  },
  [actionTypes.UPDATE_DISCUSSION_SUCCESS]: (state, action) => {
    const updatedDiscussion = action.payload.discussion
    const newState = {...state}
    newState[updatedDiscussion.id] = updatedDiscussion
    return newState
  },
  [actionTypes.CLEAN_DISCUSSION_FOCUS]: state =>
    Object.keys(state).reduce((obj, id) => {
      const newDiscussion = Object.assign(state[id])
      delete newDiscussion.focusOn
      obj[id] = newDiscussion
      return obj
    }, {}),
  [actionTypes.DRAG_AND_DROP_START]: (state, action) => {
    const updatedDiscussion = action.payload.discussion
    const newState = {...state}
    newState[updatedDiscussion.id] = updatedDiscussion
    return newState
  },
  [actionTypes.DRAG_AND_DROP_FAIL]: (state, action) => {
    const updatedDiscussion = action.payload.discussion
    const newState = {...state}
    newState[updatedDiscussion.id] = updatedDiscussion
    return newState
  },
  [actionTypes.DELETE_DISCUSSION_SUCCESS]: (state, action) => {
    const {focusId, focusOn} = action.payload.nextFocusDiscussion
    const newState = {...state}
    delete newState[action.payload.discussion.id]
    if (focusId) {
      newState[focusId] = {...newState[focusId], focusOn}
    }
    return newState
  },
  [actionTypes.DUPLICATE_DISCUSSION_SUCCESS]: (state, action) => {
    const {newDiscussion} = action.payload
    const newState = {...state}

    // Add our new discussion to the store
    newState[newDiscussion.id] = newDiscussion

    // If this changes the pinned positions, update the positions in our
    // state to be consistent with the new values in the database.
    const newPositions = newDiscussion.new_positions
    if (newPositions) {
      Object.keys(newPositions).forEach(discussionId => {
        const newPosition = newPositions[discussionId]
        newState[discussionId] = {...newState[discussionId], position: newPosition}
      })
      delete newDiscussion.new_positions
    }

    return newState
  },
}

const allDiscussionsReducer = handleActions(reducerMap, {})
export default allDiscussionsReducer
