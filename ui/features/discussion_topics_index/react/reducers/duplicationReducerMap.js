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
import {actionTypes} from '../actions'

const duplicationReducerMap = {
  [actionTypes.DUPLICATE_DISCUSSION_SUCCESS]: (state, action) => {
    const {originalId, newDiscussion} = action.payload
    const oldIndex = state.indexOf(originalId)
    if (oldIndex === -1) {
      return state
    }

    const newStateBeginning = state.slice(0, oldIndex + 1)
    newStateBeginning.push(newDiscussion.id)
    const newStateEnd = state.slice(oldIndex + 1, state.length)
    return newStateBeginning.concat(newStateEnd)
  },
}

export default duplicationReducerMap
