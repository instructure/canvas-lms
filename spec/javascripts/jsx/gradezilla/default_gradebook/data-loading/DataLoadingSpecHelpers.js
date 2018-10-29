/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

/* eslint-disable import/prefer-default-export */
export function createExampleStudents() {
  return [
    {
      enrollments: [
        {
          course_section_id: '2001',
          grades: {html_url: `http://canvas/courses/1201/users/1101`},
          type: 'StudentEnrollment'
        }
      ],

      id: '1101',
      login_id: 'adam.jones@example.com',
      name: 'Adam Jones',
      short_name: 'Adam',
      sis_user_id: '100110100',
      sortable_name: 'Ford, Betty'
    },
    {
      enrollments: [
        {
          course_section_id: '2002',
          grades: {html_url: `http://canvas/courses/1201/users/1102`},
          type: 'StudentEnrollment'
        }
      ],

      id: '1102',
      login_id: 'betty.ford@example.com',
      name: 'Betty Ford',
      short_name: 'Betty',
      sis_user_id: '100110200',
      sortable_name: 'Ford, Betty'
    },
    {
      enrollments: [
        {
          course_section_id: '2001',
          grades: {html_url: `http://canvas/courses/1201/users/1103`},
          type: 'StudentEnrollment'
        },
        {
          course_section_id: '2002',
          grades: {html_url: `http://canvas/courses/1201/users/1103`},
          type: 'StudentEnrollment'
        }
      ],

      id: '1103',
      login_id: 'charlie.xi@example.com',
      name: 'Charlie Xi',
      short_name: 'Chuck Xi',
      sis_user_id: '100110300',
      sortable_name: 'Xi, Charlie'
    },
    {
      enrollments: [
        {
          course_section_id: '2002',
          grades: {html_url: `http://canvas/courses/1201/users/1104`},
          type: 'StudentEnrollment'
        }
      ],

      id: '1104',
      login_id: 'dana.young@example.com',
      name: 'Dana Young',
      short_name: 'Dana',
      sis_user_id: '100110400',
      sortable_name: 'Young, Dana'
    }
  ]
}
