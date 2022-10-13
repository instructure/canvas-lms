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
import {handleActions, identity, getPayload} from '../helpers/reducer'
import {actionTypes} from '../actions'

const studentCache = handleActions(
  {
    [actionTypes.ADD_STUDENT_TO_CACHE]: (state, action) => {
      const {studentId, data} = action.payload
      state[studentId] = {
        followOnAssignments: data.follow_on_assignments,
        triggerAssignment: data.trigger_assignment,
      }
      return state
    },
  },
  {}
)

const isInitialDataLoading = handleActions(
  {
    [actionTypes.LOAD_INITIAL_DATA_START]: () => true,
    [actionTypes.LOAD_INITIAL_DATA_END]: () => false,
  },
  false
)

const isStudentDetailsLoading = handleActions(
  {
    [actionTypes.LOAD_STUDENT_DETAILS_START]: () => true,
    [actionTypes.LOAD_STUDENT_DETAILS_END]: () => false,
  },
  false
)

const errors = handleActions(
  {
    [actionTypes.SET_ERRORS]: (state, action) => [
      ...Array.from(action.payload),
      ...Array.from(state),
    ],
  },
  []
)

const ranges = handleActions(
  {
    [actionTypes.SET_INITIAL_DATA]: (state, action) => action.payload.ranges,
    [actionTypes.SET_SCORING_RANGES]: getPayload,
  },
  []
)

const assignment = handleActions(
  {
    [actionTypes.SET_ASSIGNMENT]: getPayload,
  },
  {}
)

const rule = handleActions(
  {
    [actionTypes.SET_INITIAL_DATA]: (state, action) => action.payload.rule,
    [actionTypes.SET_RULE]: getPayload,
  },
  {course_id: '', trigger_assignment: ''}
)

const enrolled = handleActions(
  {
    [actionTypes.SET_INITIAL_DATA]: (state, action) => action.payload.enrolled,
    [actionTypes.SET_ENROLLED]: getPayload,
  },
  0
)

const sidebarTrigger = handleActions(
  {
    [actionTypes.OPEN_SIDEBAR]: (state, action) => action.payload,
    [actionTypes.CLOSE_SIDEBAR]: () => null,
  },
  null
)

const showDetails = handleActions(
  {
    [actionTypes.OPEN_SIDEBAR]: () => true,
    [actionTypes.CLOSE_SIDEBAR]: () => false,
    [actionTypes.SELECT_RANGE]: (state, action) => action.payload !== null,
  },
  false
)

const selectedPath = handleActions(
  {
    [actionTypes.SELECT_RANGE]: (state, action) => {
      state.range = action.payload
      return state
    },
    [actionTypes.SELECT_STUDENT]: (state, action) => {
      state.student = action.payload
      return state
    },
    [actionTypes.CLOSE_SIDEBAR]: state => {
      state.student = null
      return state
    },
  },
  {range: 0, student: null}
)

export default combineReducers({
  apiUrl: identity(),
  jwt: identity(),
  studentCache,
  isInitialDataLoading,
  isStudentDetailsLoading,
  errors,
  ranges,
  assignment,
  rule,
  enrolled,
  sidebarTrigger,
  showDetails,
  selectedPath,
})
