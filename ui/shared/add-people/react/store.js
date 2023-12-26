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

import {applyMiddleware, createStore as reduxCreateStore} from 'redux'
import {thunk} from 'redux-thunk'

// returns createStore(reducer, initialState)
export const createStore = applyMiddleware(thunk)(reduxCreateStore)

export const defaultState = {
  courseParams: {
    courseId: '', // the course ID
    roles: [], // the roles available to assign people to
    sections: [], // the sections in this course
    inviteUser: false, // can the current user invite new users into a course?
  },
  inputParams: {
    searchType: 'cc_path', // cc_path=email, unique_id=login_id, sis_user_id=sis_user_id
    nameList: '', // user entered list of names to add to this course
    role: '', // the role to assign each of the added users
    section: '', // the section to assign each of the added users
    limitPrivilege: false, // user can interact with users in their section only
    canReadSIS: true,
  },
  apiState: {
    pendingCount: 0, // >0 while api calls are in-flight
    error: undefined, // api error message
  },
  userValidationResult: {
    validUsers: [], // the validated users
    duplicates: {}, // key: address, value: instance of duplicateShape
    missing: {}, // key: address, value: instance of missingShape
  },
  usersToBeEnrolled: [], // [{user_id, name, email, ...}]
  usersEnrolled: false, // true when students have been enrolled and we're finished
}
