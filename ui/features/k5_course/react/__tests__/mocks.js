/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

export const MOCK_COURSE_APPS = [
  {
    id: '7',
    course_navigation: {
      text: 'Studio',
      icon_url: 'studio.png'
    }
  }
]

export const MOCK_COURSE_TABS = [
  {
    id: 'home',
    html_url: '/courses/30',
    label: 'Home',
    visibility: 'public'
  },
  {
    id: 'modules',
    html_url: '/courses/30/modules',
    label: 'Modules',
    visibility: 'public'
  },
  {
    id: 'assignments',
    html_url: '/courses/30/assignments',
    label: 'Assignments',
    visibility: 'admins',
    hidden: true
  },
  {
    id: 'settings',
    html_url: '/courses/30/settings',
    label: 'Settings',
    visibility: 'admins'
  }
]

export const MOCK_ASSIGNMENT_GROUPS = [
  {
    id: '51',
    name: 'Reports',
    rules: {},
    group_weight: 0.0,
    assignments: [
      {
        id: '1',
        name: 'WWII Report',
        html_url: 'http://localhost/wwii-report',
        due_at: '2020-04-18T05:59:59Z',
        points_possible: 10.0,
        grading_type: 'points',
        submission: {
          score: 9.5,
          grade: '9.5',
          submitted_at: '2020-04-15T05:59:59Z',
          late: false,
          excused: false,
          missing: false
        }
      }
    ]
  }
]

export const MOCK_ENROLLMENTS = [
  {
    user_id: 'fake'
  },
  {
    user_id: '1',
    grades: {
      current_score: 89.39
    }
  }
]
