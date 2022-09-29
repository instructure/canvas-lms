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
import {defaultState} from './store'
import apiState from './reducers/apiState_reducer'
import inputParams from './reducers/inputParams_reducer'
import userValidationResult from './reducers/userValidationResult_reducer'
import usersToBeEnrolled from './reducers/usersToBeEnrolled_reducer'
import usersEnrolled from './reducers/usersEnrolled_reducer'

const reducer = combineReducers({
  courseParams: handleActions({}, defaultState.courseParams),
  apiState,
  inputParams,
  userValidationResult,
  usersToBeEnrolled,
  usersEnrolled,
})

export default reducer
