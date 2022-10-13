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

import {createActions} from 'redux-actions'
import api from './api_client'
import resolveValidationIssues from './resolveValidationIssues'
import {parseNameList, findEmailInEntry} from './helpers'

const actionDefs = [
  'SET_INPUT_PARAMS',

  'VALIDATE_USERS_START', // validate users api lifecycle
  'VALIDATE_USERS_SUCCESS',
  'VALIDATE_USERS_ERROR',

  'CREATE_USERS_START', // invite users api lifecycle
  'CREATE_USERS_SUCCESS',
  'CREATE_USERS_ERROR',

  'ENROLL_USERS_START', // enrols users api lifecycle
  'ENROLL_USERS_SUCCESS',
  'ENROLL_USERS_ERROR',

  'CHOOSE_DUPLICATE', // choose from a set of duplicates
  'SKIP_DUPLICATE', // skip this set of duplicates
  'ENQUEUE_NEW_FOR_DUPLICATE', // prepare to create a new user in lieu of one of the duplicates
  'ENQUEUE_NEW_FOR_MISSING', // prepare to create a new user for one of the missing users

  'ENQUEUE_USERS_TO_BE_ENROLLED', // prepare to enroll validated users

  'RESET', // reset([array of state subsections to reset]) undefined or empty = reset everything
]

export const actionTypes = actionDefs.reduce((types, action) => {
  types[action] = action
  return types
}, {})

export const actions = createActions(...actionDefs)

actions.validateUsers = () => (dispatch, getState) => {
  dispatch(actions.validateUsersStart())
  const state = getState()
  const courseId = state.courseParams.courseId
  let users = parseNameList(state.inputParams.nameList)
  if (state.inputParams.searchType === 'cc_path') {
    // normalize the input to be "User Name <email address>"
    // 1. include the email address w/in < ... >
    // 2. if the user includes a name and email, be sure the name is first
    users = users.map(u => {
      let email = findEmailInEntry(u)
      let user = u.replace(email, '')
      if (!/<.+>/.test(email)) {
        email = `<${email}>`
      }
      user = `${user.trim()} ${email}`
      return user
    })
  }
  const searchType = state.inputParams.searchType
  api
    .validateUsers({courseId, users, searchType})
    .then(res => {
      dispatch(actions.validateUsersSuccess(res.data))
      // if all the users were found, then we can jump right to enrolling
      if (res.data.duplicates.length === 0 && res.data.missing.length === 0) {
        const st = getState()
        dispatch(actions.enqueueUsersToBeEnrolled(st.userValidationResult.validUsers))
      }
    })
    .catch(err => {
      dispatch(actions.validateUsersError(err))
    })
}

actions.resolveValidationIssues = () => (dispatch, getState) => {
  dispatch(actions.createUsersStart())
  const state = getState()
  const courseId = state.courseParams.courseId
  const inviteUsersURL = state.courseParams.inviteUsersURL

  const newUsers = resolveValidationIssues(
    state.userValidationResult.duplicates,
    state.userValidationResult.missing
  )

  // the list of users to be enrolled
  let usersToBeEnrolled = state.userValidationResult.validUsers.concat(newUsers.usersToBeEnrolled)
  // and the list of users to be created
  const usersToBeCreated = newUsers.usersToBeCreated.map(u => {
    if (!u.name) {
      return Object.assign(u, {name: u.email})
    }
    return u
  })

  api
    .createUsers({courseId, users: usersToBeCreated, inviteUsersURL})
    .then(res => {
      dispatch(actions.createUsersSuccess(res.data))
      // merge in the newly created users
      usersToBeEnrolled = usersToBeEnrolled.concat(
        res.data.invited_users.map(u => {
          // adjust shape of users we just invited to match the existing users
          const user = {...u}
          user.user_name = u.name
          user.address = u.email
          return user
        })
      )
      dispatch(actions.enqueueUsersToBeEnrolled(usersToBeEnrolled))
    })
    .catch(err => dispatch(actions.createUsersError(err)))
}

actions.enrollUsers = () => (dispatch, getState) => {
  dispatch(actions.enrollUsersStart())
  const state = getState()
  const courseId = state.courseParams.courseId
  const user_tokens = state.usersToBeEnrolled.map(u => u.user_token)
  const role =
    state.inputParams.role ||
    (state.courseParams.roles &&
      state.courseParams.roles.length &&
      state.courseParams.roles[0].id) ||
    ''
  const section =
    state.inputParams.section ||
    (state.courseParams.sections &&
      state.courseParams.sections.length &&
      state.courseParams.sections[0].id) ||
    ''
  const limitPrivilege = state.inputParams.limitPrivilege || false
  api
    .enrollUsers({courseId, user_tokens, role, section, limitPrivilege})
    .then(res => dispatch(actions.enrollUsersSuccess(res.data)))
    .catch(err => dispatch(actions.enrollUsersError(err)))
}
