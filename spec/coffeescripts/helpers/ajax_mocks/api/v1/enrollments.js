/*
 * Copyright (C) 2012 - present Instructure, Inc.
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

import $ from 'support/jquery.mockjax'

export default $.mockjax({
  url: /\/api\/v1\/courses\/\d+\/enrollments(\?.+)?$/,
  headers: {Link: 'rel="next"'},
  responseText: [
    {
      course_id: 1,
      course_section_id: 1,
      enrollment_state: 'active',
      limit_privileges_to_course_section: true,
      root_account_id: 1,
      type: 'StudentEnrollment',
      user_id: 1,
      user: {
        id: 1,
        login_id: 'bieberfever@example.com',
        name: 'Justin Bieber',
        short_name: 'Justin B.',
        sortable_name: 'Bieber, Justin'
      }
    },
    {
      course_id: 1,
      course_section_id: 2,
      enrollment_state: 'active',
      limit_privileges_to_course_section: false,
      root_account_id: 1,
      type: 'TeacherEnrollment',
      user_id: 2,
      user: {
        id: 2,
        login_id: 'changyourmind@example.com',
        name: 'Señor Chang',
        short_name: 'S. Chang',
        sortable_name: 'Chang, Señor'
      }
    }
  ]
})
