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

import {handleActions} from 'redux-actions'
import {useScope as useI18nScope} from '@canvas/i18n'
import {actionTypes} from '../actions'
import {defaultState} from '../store'

const I18n = useI18nScope('add_peopleapiState_reducer')
// helpers -----------------------
//
// There are 2 paths to *_ERROR actions.
//  1. The api call fails completely.  In this case the promise is rejected and
//     the .catch handler is called with an err object as argument,
//     and  err.response.data contains the error. Put this into apiState.error.
//  2. The api call succeeds, but an exception is thrown in handling the response.
//     In this case the .catch handler is called with the thrown exception.
//     Set apistate.error = err.message.
function payloadToErrorMessage(err) {
  let msg = ''
  if (err.stack) {
    // an exception.
    msg = I18n.t('An internal error occurred')
  } else if (err.response && err.response.data) {
    msg = err.response.data
  } else if (err.message) {
    msg = err.message
  } else {
    msg = err.toString()
  }
  return msg
}

function startApi(state) {
  return {pendingCount: state.pendingCount + 1, error: undefined}
}
function endApi(state) {
  return {pendingCount: state.pendingCount - 1, error: undefined}
}
function handleApiError(state, action) {
  return {
    pendingCount: state.pendingCount - 1,
    error: payloadToErrorMessage(action.payload),
  }
}

// the returned module ---------------------
export default handleActions(
  {
    // when api calls start
    [actionTypes.VALIDATE_USERS_START]: startApi,
    [actionTypes.CREATE_USERS_START]: startApi,
    [actionTypes.ENROLL_USERS_START]: startApi,

    // when api calls complete successfully
    [actionTypes.VALIDATE_USERS_SUCCESS]: endApi,
    [actionTypes.CREATE_USERS_SUCCESS]: (state, action) => {
      const newstate = endApi(state)
      const erroredUsers = action.payload.errored_users
      if (erroredUsers && erroredUsers.length) {
        newstate.error = erroredUsers.map(
          errUsr =>
            `${errUsr.email}: ${
              (errUsr.errors && errUsr.errors.length && errUsr.errors[0].message) ||
              I18n.t('Failed creating user')
            }`
        )
      }
      return newstate
    },
    [actionTypes.ENROLL_USERS_SUCCESS]: endApi,

    // when api calls complete with an error
    [actionTypes.VALIDATE_USERS_ERROR]: handleApiError,
    [actionTypes.CREATE_USERS_ERROR]: handleApiError,
    [actionTypes.ENROLL_USERS_ERROR]: handleApiError,

    [actionTypes.RESET]: function resetReducer(/* state, action */) {
      return {pendingCount: 0, error: undefined}
    },
  },
  defaultState.apiState
)
