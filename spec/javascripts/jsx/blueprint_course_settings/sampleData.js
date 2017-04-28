/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

export default {
  terms: [
    { id: '1', name: 'Term One' },
    { id: '2', name: 'Term Two' },
  ],
  subAccounts: [
    { id: '1', name: 'Account One' },
    { id: '2', name: 'Account Two' },
  ],
  courses: [
    {
      id: '1',
      name: 'Course One',
      course_code: 'course_1',
      term: {
        id: '1',
        name: 'Term One',
      },
      teachers: [{
        display_name: 'Teacher One',
      }],
      sis_course_id: '1001',
    },
    {
      id: '2',
      name: 'Course Two',
      course_code: 'course_2',
      term: {
        id: '2',
        name: 'Term Two',
      },
      teachers: [{
        display_name: 'Teacher Two',
      }],
      sis_course_id: '1001',
    }
  ],
}
