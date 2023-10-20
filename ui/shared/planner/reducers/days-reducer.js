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
import {mergeDays, deleteItemFromDays} from '../utilities/daysUtils'

const defaultState = []

function deletedPlannerItem(state, action) {
  if (action.error) return state
  return deleteItemFromDays(state, action.payload)
}

export default handleActions(
  {
    GOT_DAYS_SUCCESS: (state, action) => mergeDays(state, action.payload.internalDays),
    DELETED_PLANNER_ITEM: deletedPlannerItem,
    WEEK_LOADED: (state, action) => {
      // If we're preloading a week, don't update the days that are currently displayed
      return action.payload.isPreload ? state : action.payload.weekDays
    },
    JUMP_TO_WEEK: (_state, action) => {
      return action.payload.weekDays
    },
    JUMP_TO_THIS_WEEK: (_state, action) => {
      return action.payload.weekDays
    },
    CLEAR_DAYS: () => {
      return defaultState
    },
  },
  defaultState
)
