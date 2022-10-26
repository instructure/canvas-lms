/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import {combineReducers} from 'redux'
import {handleActions} from 'redux-actions'
import actions from './actions'
import Categories from '@canvas/assignments/assignment-categories'

export default combineReducers({
  error: handleActions(
    {
      [actions.SET_ERROR]: (state, action) => action.payload,
    },
    ''
  ),
  options: handleActions(
    {
      [actions.SET_OPTIONS]: (state, action) => {
        const options = action.payload
        options.forEach(option => {
          option.assignments.forEach(assg => {
            if (assg.due_at) assg.due_at = new Date(assg.due_at)
            if (!Array.isArray(assg.submission_types))
              assg.submission_types = [assg.submission_types]
            assg.category = Categories.getCategory(assg)
          })
        })
        return options
      },
    },
    []
  ),
  selectedOption: handleActions(
    {
      [actions.SELECT_OPTION]: (state, action) => action.payload,
    },
    null
  ),
  courseId: (state = '', _action) => state,
  moduleId: (state = '', _action) => state,
  itemId: (state = '', _action) => state,
})
