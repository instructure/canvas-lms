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

import _ from 'underscore'
import redux from 'redux'
import { handleActions } from 'redux-actions'
import {actions, actionTypes} from '../actions'
import {defaultState} from '../store'

export default handleActions({
  [actionTypes.ENROLL_USERS_SUCCESS]: (/* state, action */) => (
    // all the users are enrolled, clear the list
    (defaultState.usersToBeEnrolled)
  ),
  // action.payload: [users]
  [actionTypes.ENQUEUE_USERS_TO_BE_ENROLLED]: (state, action) => (
    // replace state with the incoming array
    action.payload
  ),
  [actionTypes.RESET]: (state, action) => (
    (!action.payload || action.payload.includes('usersToBeEnrolled')) ? defaultState.usersToBeEnrolled : state
  )
}, defaultState.usersToBeEnrolled)
