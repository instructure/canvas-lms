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
import {http, HttpResponse} from 'msw'
import moment from 'moment-timezone'
import {
  MOCK_CARDS,
  MOCK_PLANNER_ITEM,
  MOCK_ASSIGNMENTS,
  MOCK_EVENTS,
} from '@canvas/k5/react/__tests__/fixtures'

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
  return [
    http.get('/api/v1/dashboard/dashboard_cards', () => HttpResponse.json(MOCK_CARDS)),
    http.get('/api/v1/planner/items', ({request}) => {
      const url = new URL(request.url)
      const startDate = url.searchParams.get('start_date')
      const endDate = url.searchParams.get('end_date')
      const perPage = url.searchParams.get('per_page')

      if (startDate && perPage === '1') {
        return HttpResponse.json(
          [
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
          {headers: {link: 'url; rel="current"'}},
        )
      } else if (endDate && perPage === '1') {
        return HttpResponse.json(
          [
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
          {headers: {link: 'url; rel="current"'}},
        )
      } else if (startDate && endDate) {
        return HttpResponse.json(MOCK_PLANNER_ITEM, {headers: {link: 'url; rel="current"'}})
      }
      return HttpResponse.json([])
    }),
    http.get('/api/v1/users/self/missing_submission*', () =>
      HttpResponse.json(opportunities, {headers: {link: 'url; rel="current"'}}),
    ),
  ]
}

// Common test data for K5 Dashboard tests
export const k5DashboardAnnouncements = [
  {
    id: '20',
    context_code: 'course_2',
    title: 'Announcement here',
    message: '<p>This is the announcement</p>',
    html_url: 'http://google.com/announcement',
    permissions: {
      update: true,
    },
    attachments: [
      {
        display_name: 'exam1.pdf',
        url: 'http://google.com/download',
        filename: '1608134586_366__exam1.pdf',
      },
    ],
  },
  {
    id: '21',
    context_code: 'course_1',
    title: "This sure isn't a homeroom",
    message: '<p>Definitely not!</p>',
    html_url: '/courses/1/announcements/21',
  },
]

export const k5DashboardGradeCourses = [
  {
    id: '1',
    name: 'Economics 101',
    has_grading_periods: false,
    enrollments: [
      {
        computed_current_score: 82,
        computed_current_grade: 'B-',
        type: 'student',
      },
    ],
    homeroom_course: false,
  },
  {
    id: '2',
    name: 'Homeroom Class',
    has_grading_periods: false,
    enrollments: [
      {
        computed_current_score: null,
        computed_current_grade: null,
        type: 'student',
      },
    ],
    homeroom_course: true,
  },
]

export const k5DashboardSyllabus = {
  id: '2',
  syllabus_body: "<p>Here's the grading scheme for this class.</p>",
}

export const k5DashboardApps = [
  {
    id: '17',
    course_navigation: {
      text: 'Google Apps',
      icon_url: 'google.png',
    },
    context_id: '1',
    context_name: 'Economics 101',
  },
]

export const k5DashboardStaff = [
  {
    id: '1',
    short_name: 'Mrs. Thompson',
    bio: 'Office Hours: 1-3pm W',
    avatar_url: '/images/avatar1.png',
    enrollments: [
      {
        role: 'TeacherEnrollment',
      },
    ],
  },
  {
    id: '2',
    short_name: 'Tommy the TA',
    bio: 'Office Hours: 1-3pm F',
    avatar_url: '/images/avatar2.png',
    enrollments: [
      {
        role: 'TaEnrollment',
      },
    ],
  },
]

/**
 * Creates a request tracker for MSW handlers.
 * Use this to track API calls similar to fetchMock.calls()
 */
export function createRequestTracker() {
  const requests = []
  return {
    track: request => {
      requests.push({
        url: request.url,
        method: request.method,
        body: request.body,
      })
    },
    calls: pattern => {
      if (!pattern) return requests
      const regex = pattern instanceof RegExp ? pattern : new RegExp(pattern)
      return requests.filter(r => regex.test(r.url))
    },
    lastUrl: pattern => {
      const calls = pattern ? this.calls(pattern) : requests
      return calls.length > 0 ? calls[calls.length - 1].url : null
    },
    called: pattern => this.calls(pattern).length > 0,
    reset: () => {
      requests.length = 0
    },
  }
}

/**
 * Creates MSW handlers for K5 Dashboard API endpoints.
 * @param {Object} overrides - Optional overrides for default mock data
 * @returns {Array} Array of MSW request handlers
 */
export function createK5DashboardMocks(overrides = {}) {
  const {
    announcements = k5DashboardAnnouncements,
    gradeCourses = k5DashboardGradeCourses,
    syllabus = k5DashboardSyllabus,
    apps = k5DashboardApps,
    staff = k5DashboardStaff,
    todos = MOCK_TODOS,
    assignments = MOCK_ASSIGNMENTS,
    events = MOCK_EVENTS,
  } = overrides

  return [
    http.get(/\/api\/v1\/announcements.*/, () => HttpResponse.json(announcements)),
    http.get(/\/api\/v1\/users\/self\/courses.*/, () => HttpResponse.json(gradeCourses)),
    http.get('api/v1/courses/2', ({request}) => {
      const url = new URL(request.url, 'http://localhost')
      if (url.searchParams.get('include[]') === 'syllabus_body') {
        return HttpResponse.json(syllabus)
      }
      return HttpResponse.json({id: '2'})
    }),
    http.get(/\/api\/v1\/external_tools\/visible_course_nav_tools.*/, () =>
      HttpResponse.json(apps),
    ),
    http.get(/\/api\/v1\/courses\/2\/users.*/, () => HttpResponse.json(staff)),
    http.get(/\/api\/v1\/users\/self\/todo.*/, () => HttpResponse.json(todos)),
    http.put('/api/v1/users/self/settings', () => HttpResponse.json({})),
    http.get(/\/api\/v1\/calendar_events\?type=assignment&important_dates=true.*/, () =>
      HttpResponse.json(assignments),
    ),
    http.get(/\/api\/v1\/calendar_events\?type=event&important_dates=true.*/, () =>
      HttpResponse.json(events),
    ),
    http.post(/\/api\/v1\/calendar_events\/save_selected_contexts.*/, () =>
      HttpResponse.json({status: 'ok'}),
    ),
    http.put(/\/api\/v1\/users\/\d+\/colors.*/, () => HttpResponse.json([])),
  ]
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
