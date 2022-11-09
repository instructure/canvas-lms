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

import {REQUEST_INITIAL_PAGE, REQUEST_PAGE, RECEIVE_PAGE, FAIL_PAGE} from '../actions/data'
import collectionReducer from './collection'
import {combineReducers} from 'redux'

// binds a collection reducer to listen only to actions directed at it
function boundCollectionReducer(key) {
  return function (state = {}, action) {
    switch (action.type) {
      case REQUEST_INITIAL_PAGE:
      case REQUEST_PAGE:
      case RECEIVE_PAGE:
      case FAIL_PAGE:
        if (action.key === key) {
          return collectionReducer(state, action)
        } else {
          return state
        }

      default:
        return state
    }
  }
}

// combine a collection reducer for each collection we care about
export default combineReducers({
  announcements: boundCollectionReducer('announcements'),
  assignments: boundCollectionReducer('assignments'),
  discussions: boundCollectionReducer('discussions'),
  modules: boundCollectionReducer('modules'),
  quizzes: boundCollectionReducer('quizzes'),
  wikiPages: boundCollectionReducer('wikiPages'),
})
