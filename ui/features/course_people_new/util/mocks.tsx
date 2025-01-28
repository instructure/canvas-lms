/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import type {Enrollment, User} from '../react/types'

export const enrollments: Enrollment[] = [
  {
    id: '1',
    name: 'Section 1',
    role: 'Student',
    type: 'StudentEnrollment',
    enrollment_state: 'active',
    last_activity: '2025-01-01T12:00:00Z',
  }, {
    id: '2',
    name: 'Section 2',
    role: 'Teacher',
    type: 'TeacherEnrollment',
    enrollment_state: 'invited',
    last_activity: '2025-01-02T12:00:00Z',
    total_activity: 20778,
  }, {
    id: '3',
    name: 'Section 3',
    role: 'TA',
    type: 'TaEnrollment',
    enrollment_state: 'inactive',
    last_activity: '2025-01-08T12:00:00Z',
  }
]

export const users: User[] = [
  {
    id: '1',
    short_name: 'Carl Martinez',
    login_id: 'carl.martinez',
    last_login: '2025-01-08T12:00:00Z',
    avatar_url: 'https://example.com/avatar.jpg',
    pronouns: 'he/him',
    sis_user_id: '123',
    enrollments: [enrollments[0]]
  }, {
    id: '2',
    short_name: 'Mark Lambert',
    login_id: 'mark.lambert',
    last_login: '2025-01-01T12:00:00Z',
    avatar_url: 'https://example.com/avatar.jpg',
    sis_user_id: '456',
    enrollments: [enrollments[1], enrollments[2]]
  }, {
    id: '3',
    short_name: 'Jane Walton',
    login_id: 'jane.walton',
    last_login: '2025-01-01T12:00:00Z',
    avatar_url: 'https://www.instructure.com/images/face.jpg',
    sis_user_id: '789',
    enrollments: [enrollments[0], enrollments[2]]
  }
]