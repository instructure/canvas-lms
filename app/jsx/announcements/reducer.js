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

import { combineReducers } from 'redux'
import { handleActions } from 'redux-actions'
import { actionTypes } from './actions'
import { reduceNotifications } from '../shared/reduxNotifications'
import { createPaginatedReducer } from '../shared/reduxPagination'

const MIN_SEATCH_LENGTH = 3

const identity = (defaultState = null) => (
  state => (state === undefined ? defaultState : state)
)

export default combineReducers({
  courseId: identity(null),
  permissions: identity({}),
  masterCourseData: identity(null),
  atomFeedUrl: identity(null),
  announcements: createPaginatedReducer('announcements'),
  announcementsSearch: combineReducers({
    term: handleActions({
      [actionTypes.UPDATE_ANNOUNCEMENTS_SEARCH]: (state, action) => {
        const term = action.payload && action.payload.term
        if (term === undefined) {
          return state
        } else if (term.length < MIN_SEATCH_LENGTH) {
          return ''
        } else {
          return term
        }
      }
    }, ''),
    filter: handleActions({
      [actionTypes.UPDATE_ANNOUNCEMENTS_SEARCH]: (state, action) => {
        const filter = action.payload && action.payload.filter
        if (filter === undefined) {
          return state
        } else {
          return filter
        }
      }
    }, 'all'),
  }),
  notifications: reduceNotifications,
})
