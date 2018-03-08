/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import {combineReducers} from 'redux'

const items = handleActions(
  {
    ITEMS_LOADED: (state, action) => state.concat(action.payload.items),
    ITEM_SAVED: (state, action) => {
      const newState = state.slice()

      const itemToUpdate = newState.find(
        item =>
          item.plannable_id === action.payload.plannable_id &&
          item.plannable_type === action.payload.plannable_type
      )
      itemToUpdate.planner_override = action.payload
      return newState
    }
  },
  []
)

const nextUrl = handleActions(
  {
    ITEMS_LOADED: (state, action) => action.payload.nextUrl
  },
  null
)

const loading = handleActions(
  {
    ITEMS_LOADING: () => true,
    ITEMS_LOADED: () => false,
    ITEMS_LOADING_FAILED: () => false
  },
  false
)

const loaded = handleActions(
  {
    ALL_ITEMS_LOADED: () => true
  },
  false
)

export default combineReducers({
  items,
  loading,
  nextUrl,
  loaded
})
