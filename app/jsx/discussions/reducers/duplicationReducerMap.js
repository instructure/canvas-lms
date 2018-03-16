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
import { actionTypes } from '../actions'

function updatePositions(discussions, updatedPositions) {
  return discussions.map( (discussion) => {
    if (updatedPositions[discussion.id] === discussion.position) {
      return discussion
    } else {
      return Object.assign({...discussion, position: updatedPositions[discussion.id] })
    }
  })
}

const duplicationReducerMap = {
  [actionTypes.DUPLICATE_DISCUSSION_SUCCESS]: (state, action) => {
    const newDiscussion = Object.assign(action.payload.newDiscussion)
    const oldIndex = state.findIndex((discussion) => (
      discussion.id === action.payload.originalId
    ))
    if (oldIndex >= 0) {
      // We are in the container of the duplicated discussion, so process things
      newDiscussion.focusOn = 'title'
      const newStateBeginning = state.slice(0, oldIndex + 1)
      newStateBeginning.push(newDiscussion)
      const remainingOriginalDiscussions = state.slice(oldIndex + 1, state.length)
      // If we are in the pinned section, update the positions as needed to be
      // consistent with the new values in the database.  Note that only
      // discussions *after* what was duplicated might have changed positions.
      const newStateEnd = newDiscussion.pinned
        ? updatePositions(remainingOriginalDiscussions, newDiscussion.new_positions)
        : remainingOriginalDiscussions

      delete newDiscussion.new_positions
      return newStateBeginning.concat(newStateEnd)
    } else {
      // The original discussion wasn't in this container, so the state should
      // not be changed.
      return state
    }
  }
}

export default duplicationReducerMap
