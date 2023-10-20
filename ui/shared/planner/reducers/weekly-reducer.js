/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import moment from 'moment-timezone'
import {handleActions} from 'redux-actions'

export default handleActions(
  {
    GETTING_WEEK_ITEMS: (state, action) => {
      return {
        ...state,
        weekStart: action.payload.weekStart,
        weekEnd: action.payload.weekEnd,
      }
    },
    INITIAL_OPTIONS: (state, action) => {
      const env = action.payload.env
      state = null
      if (env.K5_USER || env.K5_SUBJECT_COURSE) {
        const thisWeekStart = moment.tz(env.TIMEZONE).startOf('week')
        state = {
          weekStart: thisWeekStart,
          weekEnd: moment.tz(env.TIMEZONE).endOf('week'),
          thisWeek: thisWeekStart,
          weeks: {},
        }
      }
      return state
    },
    WEEK_LOADED: (state, action) => {
      const newState = {...state}
      newState.weeks = {...state.weeks}
      newState.weeks[action.payload.weekStart.format()] = action.payload.weekDays
      return newState
    },
    GOT_WAY_PAST_ITEM_DATE: (state, action) => {
      const newState = {...state}
      newState.wayPastItemDate = action.payload
      return newState
    },
    GOT_WAY_FUTURE_ITEM_DATE: (state, action) => {
      const newState = {...state}
      newState.wayFutureItemDate = action.payload
      return newState
    },
    CLEAR_WEEKLY_ITEMS: state => {
      const newState = {...state}
      newState.weeks = {}
      return newState
    },
  },
  null
)
