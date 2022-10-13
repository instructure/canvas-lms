/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import {List, Set} from 'immutable'
import {combineReducers} from 'redux-immutable'
import {handleActions} from 'redux-actions'

import {ALL_ID} from './categories'
import * as actions from './assignment-picker-actions'

const assignmentPickerReducer = combineReducers({
  is_open: handleActions(
    {
      [actions.OPEN_ASSIGNMENT_PICKER]: (_state, _actions) => true,
      [actions.CLOSE_ASSIGNMENT_PICKER]: (_state, _actions) => false,
    },
    false
  ),

  target: handleActions(
    {
      [actions.SET_ASSIGNMENT_PICKER_TARGET]: (state, action) => action.payload,
      [actions.CLOSE_ASSIGNMENT_PICKER]: () => null,
    },
    null
  ),

  disabled_assignments: handleActions(
    {
      [actions.SET_ASSIGNMENT_PICKER_TARGET]: (state, action) =>
        action.payload
          .get('assignment_set_associations', List())
          .map(a => a.get('assignment_id'))
          .toSet(),
      [actions.CLOSE_ASSIGNMENT_PICKER]: () => Set(),
    },
    Set()
  ),

  selected_assignments: handleActions(
    {
      [actions.SELECT_ASSIGNMENT_IN_PICKER]: (state, action) => state.toSet().add(action.payload),
      [actions.UNSELECT_ASSIGNMENT_IN_PICKER]: (state, action) =>
        state.toSet().delete(action.payload),
      [actions.CLOSE_ASSIGNMENT_PICKER]: () => Set(),
    },
    Set()
  ),

  name_filter: handleActions(
    {
      [actions.FILTER_ASSIGNMENTS_BY_NAME]: (state, action) => action.payload,
      [actions.CLOSE_ASSIGNMENT_PICKER]: () => '',
    },
    ''
  ),

  category_filter: handleActions(
    {
      [actions.FILTER_ASSIGNMENTS_BY_CATEGORY]: (state, action) => action.payload,
      [actions.CLOSE_ASSIGNMENT_PICKER]: () => ALL_ID,
    },
    ALL_ID
  ),
})

export default assignmentPickerReducer
