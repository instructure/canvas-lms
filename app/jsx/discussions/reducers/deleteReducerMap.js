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
import { setSortableId } from '../utils'

const deleteReducerMap = {
  [actionTypes.DELETE_DISCUSSION_SUCCESS]: (state, action) => {
    const oldIndex = state.findIndex((disc) => (
      disc.id === action.payload.discussion.id
    ))
    const newState= state.slice()
    if (oldIndex < 0) {
      return newState
    }
    if(oldIndex === 0) {
      newState.splice(oldIndex, 1)
      if(newState.length) {
        newState[0] = { ...newState[0], focusOn: "toggleButton" }
      }
      return setSortableId(newState)
    } else {
      const newFocusIndex = oldIndex - 1;
      if(newState[newFocusIndex]) {
        newState[newFocusIndex] = {
          ...newState[newFocusIndex],
          focusOn: newState[newFocusIndex].permissions.delete ? 'manageMenu' : 'title'
        }
        newState.splice(oldIndex, 1)
        return setSortableId(newState)
      } else { // There is no discussions left
        return []
      }
    }
  }
}

export default deleteReducerMap
