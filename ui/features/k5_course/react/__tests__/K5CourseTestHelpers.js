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

import {OBSERVER_COOKIE_PREFIX} from '@canvas/observer-picker/ObserverGetObservee'
import fetchMock from 'fetch-mock'
import {http, HttpResponse} from 'msw'
import {
  MOCK_COURSE_SYLLABUS,
  MOCK_COURSE_APPS,
  MOCK_COURSE_TABS,
  MOCK_GRADING_PERIODS_EMPTY,
  MOCK_ASSIGNMENT_GROUPS,
  MOCK_ENROLLMENTS,
  MOCK_GROUPS,
} from './mocks'

export const currentUser = {
  id: '1',
  display_name: 'Geoffrey Jellineck',
  avatar_image_url: 'http://avatar',
}

export const observedUserCookieName = `${OBSERVER_COOKIE_PREFIX}${currentUser.id}`

export const defaultEnv = {
  current_user: currentUser,
  course_id: '30',
  K5_USER: true,
  FEATURES: {},
  PREFERENCES: {
    hide_dashcard_color_overlays: false,
  },
  MOMENT_LOCALE: 'en',
  TIMEZONE: 'America/Denver',
}

export const dtf = new Intl.DateTimeFormat('en', {
  weekday: 'short',
  month: 'short',
  day: 'numeric',
  year: 'numeric',
  hour: 'numeric',
  minute: 'numeric',
  timeZone: defaultEnv.TIMEZONE,
})

export const dateFormatter = d => dtf.format(d instanceof Date ? d : new Date(d))

export const getOneMonthAgo = () => {
  const date = new Date()
  date.setMonth(date.getMonth() - 1)
  return ('0' + (date.getMonth() + 1)).slice(-2)
}

export const defaultTabs = [
  {id: '0'},
  {id: '19'},
  {id: '10'},
  {id: '7'},
  {id: '5'},
  {id: 'context_external_tool_1'},
]

export const defaultProps = {
  currentUser,
  loadAllOpportunities: () => {},
  name: 'Arts and Crafts',
  id: '30',
  timeZone: defaultEnv.TIMEZONE,
  canManage: false,
  canReadAnnouncements: true,
  canReadAsAdmin: false,
  courseOverview: {
    body: '<h2>Time to learn!</h2>',
    url: 'home',
    canEdit: true,
  },
  hideFinalGrades: false,
  userIsStudent: true,
  showStudentView: false,
  studentViewPath: '/courses/30/student_view/1',
  showLearningMasteryGradebook: false,
  tabs: defaultTabs,
  settingsPath: '/courses/30/settings',
  groupsPath: '/courses/30/groups',
  latestAnnouncement: {
    id: '12',
    title: 'Important announcement',
    message: '<p>Read this closely.</p>',
    html_url: '/courses/30/discussion_topics/12',
    attachments: [
      {
        filename: 'hw.pdf',
        display_name: 'hw.pdf',
        url: 'http://address/to/hw.pdf',
      },
    ],
    permissions: {
      update: true,
    },
    posted_at: `2021-${getOneMonthAgo()}-14T17:06:21-06:00`,
  },
  pagesPath: '/courses/30/pages',
  hasWikiPages: true,
  hasSyllabusBody: true,
  observedUsersList: [{id: currentUser.id, name: currentUser.display_name}],
  selfEnrollment: {
    option: null,
    url: null,
  },
  assignmentsDueToday: {},
  assignmentsMissing: {},
  assignmentsCompletedForToday: {},
  currentUserRoles: ['user', 'student', 'teacher'],
  isMasterCourse: false,
  showImmersiveReader: false,
}

// API URLs
export const FETCH_IMPORTANT_INFO_URL = encodeURI('/api/v1/courses/30?include[]=syllabus_body')
export const FETCH_APPS_URL =
  '/api/v1/external_tools/visible_course_nav_tools?context_codes[]=course_30'
export const FETCH_TABS_URL = '/api/v1/courses/30/tabs'
export const GRADING_PERIODS_URL = encodeURI(
  '/api/v1/courses/30?include[]=grading_periods&include[]=current_grading_period_scores&include[]=total_scores',
)
export const OBSERVER_GRADING_PERIODS_URL = encodeURI(
  '/api/v1/courses/30?include[]=grading_periods&include[]=current_grading_period_scores&include[]=total_scores&include[]=observed_users',
)
export const ASSIGNMENT_GROUPS_URL = encodeURI(
  '/api/v1/courses/30/assignment_groups?include[]=assignments&include[]=submission&include[]=read_state&include[]=submission_comments',
)
export const OBSERVER_ASSIGNMENT_GROUPS_URL = encodeURI(
  '/api/v1/courses/30/assignment_groups?include[]=assignments&include[]=submission&include[]=read_state&include[]=submission_comments&include[]=observed_users',
)
export const ENROLLMENTS_URL = '/api/v1/courses/30/enrollments?user_id=1'
export const OBSERVER_ENROLLMENTS_URL =
  '/api/v1/courses/30/enrollments?user_id=1&include=observed_users'
export const ANNOUNEMENTS_URL_REGEX = /\/api\/v1\/announcements\.*/
export const GROUPS_URL = encodeURI(
  '/api/v1/courses/30/groups?include[]=users&include[]=group_category&include[]=permissions&include_inactive_users=true&section_restricted=true&filter=',
)

export const createModulesPartial = () => {
  const modulesContainer = document.createElement('div')
  modulesContainer.id = 'k5-modules-container'
  modulesContainer.style.display = 'none'
  const contextModules = document.createElement('div')
  contextModules.id = 'context_modules'
  modulesContainer.appendChild(contextModules)
  const moduleItem = document.createElement('p')
  moduleItem.innerHTML = 'Course modules content'
  contextModules.appendChild(moduleItem)
  return modulesContainer
}

export const createStudentView = () => {
  const resetStudentBtn = document.createElement('a')
  resetStudentBtn.className = 'reset_test_student'
  resetStudentBtn.href = '/courses/30/test_student'
  resetStudentBtn.innerHTML = 'Reset student'
  resetStudentBtn.setAttribute('data-method', 'delete')

  const leaveStudentViewBtn = document.createElement('a')
  leaveStudentViewBtn.className = 'leave_student_view'
  leaveStudentViewBtn.href = '/courses/30/student_view'
  leaveStudentViewBtn.innerHTML = 'Leave student view'
  leaveStudentViewBtn.setAttribute('data-method', 'delete')

  const studentViewBarContainer = document.createElement('div')
  studentViewBarContainer.id = 'student-view-bar-container'
  studentViewBarContainer.appendChild(resetStudentBtn)
  studentViewBarContainer.appendChild(leaveStudentViewBtn)
  return studentViewBarContainer
}

export const setupBasicFetchMocks = () => {
  fetchMock.get(FETCH_IMPORTANT_INFO_URL, MOCK_COURSE_SYLLABUS)
  fetchMock.get(FETCH_APPS_URL, MOCK_COURSE_APPS)
  fetchMock.get(FETCH_TABS_URL, MOCK_COURSE_TABS)
  fetchMock.get(GRADING_PERIODS_URL, MOCK_GRADING_PERIODS_EMPTY)
  fetchMock.get(ASSIGNMENT_GROUPS_URL, MOCK_ASSIGNMENT_GROUPS)
  fetchMock.get(ENROLLMENTS_URL, MOCK_ENROLLMENTS)
  fetchMock.get(ANNOUNEMENTS_URL_REGEX, [])
  fetchMock.get(GROUPS_URL, MOCK_GROUPS)
}

export const setupMswGroupsHandler = server => {
  server.use(
    http.get('/api/v1/courses/30/groups', () => {
      return HttpResponse.json(MOCK_GROUPS)
    }),
  )
}

export const cleanupModulesContainer = () => {
  const modulesContainer = document.getElementById('k5-modules-container')
  modulesContainer?.remove()
}
