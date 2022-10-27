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

// I am transforming the api response. Sometimes to add fields
// I have from the api input that is not returned in the response,
// and sometimes to map a response field to a new field name based
// on the api input.
//
import axios from '@canvas/axios'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('add_people_api_client')

export default {
  // @param courseId: id of current course
  // @param users: array of user ids
  // @param searchType: one of ['unique_id', 'sis_user_id', 'cc_path']
  // @returns {
  //   duplicates: [{ }] -- multiple matches found
  //   users: [{ account_id, account_name, address, user_id, user_name }] -- single match found
  //   missing: [{ address, type }] -- no user match found
  //   errors: [{ message }]
  // }
  validateUsers({courseId, users, searchType}) {
    // strip empty values
    users = users.filter(u => u.length > 0)
    return axios
      .post(`/courses/${courseId}/user_lists.json`, {
        user_list: users,
        v2: true,
        search_type: searchType,
      })
      .then(response => {
        // fill out the api response
        response.data.users = response.data.users.map(u => {
          if (searchType === 'unique_id') {
            u.login_id = u.address
          } else if (searchType === 'cc_path') {
            u.email = u.address
          } else if (searchType === 'sis_user_id') {
            u.sis_user_id = u.address
          }
          return u
        })
        return response
      })
  },

  // @param users: array of user objects, email is req [{ email, name }]
  // @param inviteUsersURL: string: URL to invite_users api endpoint.
  // @returns {
  //   invited_users:  [{ email, id }] -- successfully created users
  //   errored_users:  [{ email, errors[{ message }] }] -- bad & already existing users end up in here
  // }
  createUsers({users, inviteUsersURL}) {
    if (users.length === 0) {
      return Promise.resolve({data: {invited_users: [], errored_users: []}})
    }
    // if inviteUsersURL is missing, error
    if (inviteUsersURL) {
      return axios.post(inviteUsersURL, {users}).then(response => {
        response.data.invited_users = response.data.invited_users.map(u => {
          u.user_id = u.id
          delete u.id
          // find the matching user from the action input
          const uindex = users.findIndex(u2 => u2.email === u.email)
          if (uindex >= 0) {
            u.name = users[uindex].name
          }
          return u
        })
        return response
      })
    }
    // eslint-disable-next-line prefer-promise-reject-errors
    return Promise.reject({
      message: I18n.t('You do not have permission to invite users that do not already exist.'),
    })
  },

  // @param courseId: the course id
  // @param user_tokens: array of user tokens returned by user_lists(v2) / invite_users
  // @param role: role id of users being enrolled in
  // @param section: section id the users are being enrolled in
  // @returns [{enrollment: {user_id amongst other properties}, ...}]
  //
  enrollUsers({courseId, user_tokens, role, section, limitPrivilege}) {
    return axios.post(`/courses/${courseId}/enroll_users`, {
      user_tokens,
      role_id: role,
      course_section_id: section,
      limit_privileges_to_course_section: limitPrivilege,
    })
  },
}
