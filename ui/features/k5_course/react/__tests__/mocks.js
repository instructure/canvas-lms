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

export const MOCK_COURSE_SYLLABUS = {
  id: '30',
  syllabus_body: '<p>This is really important.</p>',
}

export const MOCK_COURSE_APPS = [
  {
    id: '7',
    course_navigation: {
      text: 'Studio',
      icon_url: 'studio.png',
    },
    context_id: '30',
    context_name: 'Arts and Crafts',
  },
]

export const MOCK_COURSE_TABS = [
  {
    id: 'home',
    html_url: '/courses/30',
    label: 'Home',
    visibility: 'public',
  },
  {
    id: 'modules',
    html_url: '/courses/30/modules',
    label: 'Modules',
    visibility: 'public',
  },
  {
    id: 'assignments',
    html_url: '/courses/30/assignments',
    label: 'Assignments',
    visibility: 'admins',
    hidden: true,
  },
  {
    id: 'groups',
    html_url: '/courses/30/groups',
    label: 'Groups',
    visibility: 'public',
  },
  {
    id: 'settings',
    html_url: '/courses/30/settings',
    label: 'Settings',
    visibility: 'admins',
  },
]

export const MOCK_GRADING_PERIODS_EMPTY = {
  grading_periods: null,
  enrollments: [
    {
      current_grading_period_id: null,
      totals_for_all_grading_periods_option: false,
    },
  ],
}

export const MOCK_GRADING_PERIODS_NORMAL = {
  grading_periods: [
    {
      id: '1',
      title: 'Quarter 1',
      start_date: moment().subtract(10, 'months').toISOString(),
      end_date: moment().subtract(4, 'months').toISOString(),
      workflow_state: 'active',
    },
    {
      id: '2',
      title: 'Quarter 2',
      start_date: moment().subtract(4, 'months').toISOString(),
      end_date: moment().add(2, 'months').toISOString(),
      workflow_state: 'active',
    },
  ],
  enrollments: [
    {
      current_grading_period_id: '2',
      totals_for_all_grading_periods_option: true,
    },
  ],
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
          grading_period_id: '2',
          submission_comments: [
            {
              id: '1',
            },
          ],
        },
      },
    ],
  },
]

export const MOCK_ASSIGNMENT_GROUPS_WITH_OBSERVED_USERS = [
  {
    id: '52',
    name: 'Assignments',
    rules: {},
    group_weight: 0.0,
    assignments: [
      {
        id: '9',
        description: '',
        html_url: 'http://localhost:3000/courses/30/assignments/9',
        due_at: '2021-10-25T05:59:59Z',
        points_possible: 10,
        grading_type: 'points',
        position: 5,
        name: 'Assignment 3',
        submission: [
          {
            id: '51',
            assignment_id: '9',
            grade: '6',
            score: 6,
            submitted_at: '2021-09-20T23:55:08Z',
            user_id: '5',
            workflow_state: 'submitted',
            grader_id: '1',
            excused: false,
            points_deducted: null,
            grading_period_id: '2',
            late: false,
            missing: false,
            seconds_late: 0,
            submission_comments: [
              {
                id: '1',
              },
            ],
            read_state: 'read',
          },
          {
            id: '53',
            assignment_id: '9',
            grade: '8',
            score: 8,
            submitted_at: '2021-09-22T21:25:08Z',
            user_id: '6',
            workflow_state: 'submitted',
            grader_id: '2',
            excused: false,
            points_deducted: null,
            grading_period_id: '2',
            late: false,
            missing: false,
            seconds_late: 0,
            submission_comments: [
              {
                id: '1',
              },
            ],
            read_state: 'read',
          },
        ],
      },
    ],
  },
]

export const MOCK_ENROLLMENTS = [
  {
    user_id: 'fake',
  },
  {
    user_id: '1',
    grades: {
      current_score: 89.39,
    },
  },
]

export const MOCK_ENROLLMENTS_WITH_OBSERVED_USERS = [
  {
    user_id: '1',
    associated_user_id: '5',
    enrollment_state: 'active',
    observed_user: {
      id: '5',
      enrollments: [
        {
          user_id: '5',
          id: '15',
          grades: {
            current_grade: null,
            current_score: 88,
            final_grade: null,
            final_score: 88,
          },
        },
      ],
    },
  },
  {
    user_id: '1',
    associated_user_id: '6',
    enrollment_state: 'active',
    observed_user: {
      id: '6',
      enrollments: [
        {
          user_id: '6',
          id: '16',
          grades: {
            current_grade: null,
            current_score: 76.2,
            final_grade: null,
            final_score: 76.2,
          },
        },
      ],
    },
  },
]

export const MOCK_GROUPS = [
  {
    id: '17',
    group_category_id: '5',
    name: 'Fight Club',
    created_at: '2021-09-07T18:18:30Z',
    max_membership: null,
    is_public: false,
    join_level: 'invitation_only',
    description: null,
    members_count: 0,
    storage_quota_mb: 50,
    permissions: {
      create_discussion_topic: false,
      join: false,
      create_announcement: false,
    },
    context_type: 'Course',
    course_id: '30',
    avatar_url: null,
    role: null,
    leader: null,
    users: [],
    group_category: {
      id: '5',
      role: null,
      name: 'Student Clubs',
      self_signup: null,
      group_limit: null,
      auto_leader: null,
      created_at: '2021-09-07T16:51:09Z',
      context_type: 'Course',
      course_id: '30',
      protected: false,
      allows_multiple_memberships: false,
      is_member: false,
    },
    has_submission: false,
    concluded: false,
  },
]
