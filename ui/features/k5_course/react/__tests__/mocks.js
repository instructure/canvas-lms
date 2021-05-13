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

import moment from 'moment-timezone'

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

export const MOCK_GRADING_PERIODS_EMPTY = {
  grading_periods: null,
  enrollments: [
    {
      current_grading_period_id: null,
      totals_for_all_grading_periods_option: false
    }
  ]
}

export const MOCK_GRADING_PERIODS_NORMAL = {
  grading_periods: [
    {
      id: '1',
      title: 'Quarter 1',
      start_date: moment().subtract(10, 'months').toISOString(),
      end_date: moment().subtract(4, 'months').toISOString(),
      workflow_state: 'active'
    },
    {
      id: '2',
      title: 'Quarter 2',
      start_date: moment().subtract(4, 'months').toISOString(),
      end_date: moment().add(2, 'months').toISOString(),
      workflow_state: 'active'
    }
  ],
  enrollments: [
    {
      current_grading_period_id: '2',
      totals_for_all_grading_periods_option: true
    }
  ]
}

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
          missing: false,
          read_state: 'read',
          grading_period_id: '2'
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
