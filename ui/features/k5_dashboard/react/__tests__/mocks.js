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
import moxios from 'moxios'
import moment from 'moment-timezone'
import {MOCK_CARDS, MOCK_PLANNER_ITEM} from '@canvas/k5/react/__tests__/fixtures'

export const MOCK_TODOS = [
  {
    assignment: {
      id: '10',
      due_at: null,
      all_dates: [
        {
          base: true,
          due_at: null,
        },
      ],
      name: 'Drain a drain',
      points_possible: 10,
    },
    context_id: '7',
    context_type: 'Course',
    context_name: 'Plumbing',
    html_url: '/courses/7/gradebook/speed_grader?assignment_id=10',
    ignore: '/api/v1/users/self/todo/assignment_10/grading?permanent=0',
    ignore_permanently: '/api/v1/users/self/todo/assignment_10/grading?permanent=1',
    needs_grading_count: 2,
    type: 'grading',
  },
  {
    assignment: {
      id: '11',
      due_at: '2021-06-22T23:59:59Z',
      all_dates: [
        {
          base: true,
          due_at: '2021-06-22T23:59:59Z',
        },
      ],
      name: 'Plant a plant',
      points_possible: 15,
    },
    context_id: '5',
    context_type: 'Course',
    context_name: 'Horticulture',
    html_url: '/courses/5/gradebook/speed_grader?assignment_id=11',
    ignore: '/api/v1/users/self/todo/assignment_11/grading?permanent=0',
    ignore_permanently: '/api/v1/users/self/todo/assignment_11/grading?permanent=1',
    needs_grading_count: 3,
    type: 'grading',
  },
  {
    assignment: {
      id: '12',
      due_at: '2021-07-15T23:59:59Z',
      all_dates: [
        {
          base: true,
          due_at: '2021-07-15T23:59:59Z',
        },
      ],
      name: 'Dream a dream',
      points_possible: 5,
    },
    context_id: '2',
    context_type: 'Course',
    context_name: 'Oneirology',
    html_url: '/courses/2/gradebook/speed_grader?assignment_id=12',
    ignore: '/api/v1/users/self/todo/assignment_12/grading?permanent=0',
    ignore_permanently: '/api/v1/users/self/todo/assignment_12/grading?permanent=1',
    needs_grading_count: 1,
    type: 'grading',
  },
  {
    assignment: {
      id: '13',
      due_at: '2021-07-15T23:59:59Z',
      all_dates: [
        {
          base: true,
          due_at: '2021-07-15T23:59:59Z',
        },
      ],
      name: 'Long essay',
      points_possible: 50,
    },
    context_id: '2',
    context_type: 'Course',
    context_name: 'Oneirology',
    html_url: '/courses/2/gradebook/speed_grader?assignment_id=13',
    ignore: '/api/v1/users/self/todo/assignment_13/grading?permanent=0',
    ignore_permanently: '/api/v1/users/self/todo/assignment_13/grading?permanent=1',
    needs_grading_count: 1,
    type: 'submitting',
  },
]

export const opportunities = [
  {
    id: '1',
    course_id: '1',
    name: 'Assignment 1',
    points_possible: 23,
    html_url: '/courses/1/assignments/1',
    due_at: '2021-01-10T05:59:00Z',
    submission_types: ['online_quiz'],
  },
  {
    id: '2',
    course_id: '1',
    name: 'Assignment 2',
    points_possible: 10,
    html_url: '/courses/1/assignments/2',
    due_at: '2021-01-15T05:59:00Z',
    submission_types: ['online_url'],
  },
]

export function createPlannerMocks() {
  moxios.stubRequest(/\/api\/v1\/dashboard\/dashboard_cards$/, {
    status: 200,
    response: MOCK_CARDS,
  })
  moxios.stubRequest(/api\/v1\/planner\/items\?start_date=.*end_date=.*/, {
    status: 200,
    headers: {link: 'url; rel="current"'},
    response: MOCK_PLANNER_ITEM,
  })
  moxios.stubRequest(/api\/v1\/planner\/items\?start_date=.*per_page=1/, {
    status: 200,
    headers: {link: 'url; rel="current"'},
    response: [
      {
        context_name: 'Course2',
        context_type: 'Course',
        course_id: '1',
        html_url: '/courses/2/announcements/12',
        new_activity: false,
        plannable: {
          created_at: '2020-03-16T17:17:17Z',
          id: '12',
          title: 'Announcement 12',
          updated_at: '2020-03-16T17:31:52Z',
        },
        plannable_date: moment().subtract(6, 'months').toISOString(),
        plannable_id: '12',
        plannable_type: 'announcement',
        planner_override: null,
        submissions: {},
      },
    ],
  })
  moxios.stubRequest(/api\/v1\/planner\/items\?end_date=.*per_page=1/, {
    status: 200,
    headers: {link: 'url; rel="current"'},
    response: [
      {
        context_name: 'Course2',
        context_type: 'Course',
        course_id: '1',
        html_url: '/courses/2/discussion_topics/8',
        new_activity: false,
        plannable: {
          created_at: '2022-03-16T17:17:17Z',
          id: '8',
          title: 'Discussion 8',
          updated_at: '2022-03-16T17:31:52Z',
        },
        plannable_date: moment().add(6, 'months').toISOString(),
        plannable_id: '8',
        plannable_type: 'discussion',
        planner_override: null,
        submissions: {},
      },
    ],
  })
  moxios.stubRequest(/\/api\/v1\/users\/self\/missing_submission.*/, {
    status: 200,
    headers: {link: 'url; rel="current"'},
    response: opportunities,
  })
}

const currentUser = {
  id: '1',
  display_name: 'Geoffrey Jellineck',
  name: 'Geoffrey Jellineck',
  avatar_image_url: 'http://avatar',
}

export const defaultEnv = {
  current_user: currentUser,
  current_user_id: '1',
  K5_USER: true,
  PREFERENCES: {
    hide_dashcard_color_overlays: false,
  },
  MOMENT_LOCALE: 'en',
  TIMEZONE: 'America/Denver',
  USE_CLASSIC_FONT: false,
}

const accountCalendarContexts = [
  {asset_string: 'account_1', name: 'CSU'},
  {asset_string: 'account_2', name: 'Math Dept'},
]

export const defaultK5DashboardProps = {
  canDisableElementaryDashboard: false,
  currentUser,
  currentUserRoles: ['admin'],
  createPermission: null,
  restrictCourseCreation: false,
  plannerEnabled: false,
  loadingOpportunities: false,
  loadAllOpportunities: () => {},
  timeZone: defaultEnv.TIMEZONE,
  hideGradesTabForStudents: false,
  selectedContextCodes: ['course_1', 'course_3'],
  selectedContextsLimit: 2,
  canAddObservee: false,
  observedUsersList: [{id: currentUser.id, name: currentUser.display_name}],
  openTodosInNewTab: true,
  accountCalendarContexts,
}
