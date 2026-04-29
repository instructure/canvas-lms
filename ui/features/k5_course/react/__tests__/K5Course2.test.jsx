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

import {TAB_IDS} from '@canvas/k5/react/utils'
import {OBSERVER_COOKIE_PREFIX} from '@canvas/observer-picker/ObserverGetObservee'
import {MOCK_OBSERVED_USERS_LIST} from '@canvas/observer-picker/react/__tests__/fixtures'
import {act, render, waitFor} from '@testing-library/react'
import React from 'react'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import {K5Course} from '../K5Course'
import {
  MOCK_ASSIGNMENT_GROUPS,
  MOCK_ASSIGNMENT_GROUPS_WITH_OBSERVED_USERS,
  MOCK_COURSE_APPS,
  MOCK_COURSE_SYLLABUS,
  MOCK_COURSE_TABS,
  MOCK_ENROLLMENTS,
  MOCK_ENROLLMENTS_WITH_OBSERVED_USERS,
  MOCK_GRADING_PERIODS_EMPTY,
  MOCK_GROUPS,
} from './mocks'

vi.mock('@canvas/util/globalUtils', () => ({
  reloadWindow: vi.fn(),
}))

const currentUser = {
  id: '1',
  display_name: 'Geoffrey Jellineck',
  avatar_image_url: 'http://avatar',
}
const observedUserCookieName = `${OBSERVER_COOKIE_PREFIX}${currentUser.id}`
const defaultEnv = {
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

const dtf = new Intl.DateTimeFormat('en', {
  // MMM D, YYYY h:mma
  weekday: 'short',
  month: 'short',
  day: 'numeric',
  year: 'numeric',
  hour: 'numeric',
  minute: 'numeric',
  timeZone: defaultEnv.TIMEZONE,
})

const dateFormatter = d => dtf.format(d instanceof Date ? d : new Date(d))

const getOneMonthAgo = () => {
  const date = new Date()
  date.setMonth(date.getMonth() - 1)
  return ('0' + (date.getMonth() + 1)).slice(-2)
}

const defaultTabs = [
  {id: '0'},
  {id: '19'},
  {id: '10'},
  {id: '7'},
  {id: '5'},
  {id: 'context_external_tool_1'},
]
const defaultProps = {
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

const createModulesPartial = () => {
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

const createStudentView = () => {
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

const server = setupServer()

beforeAll(() => {
  server.listen()
})

afterAll(() => {
  server.close()
})

beforeEach(() => {
  server.use(
    http.get('*/api/v1/courses/30', ({request}) => {
      const url = new URL(request.url)
      const include = url.searchParams.getAll('include[]')
      if (include.includes('syllabus_body')) {
        return HttpResponse.json(MOCK_COURSE_SYLLABUS)
      }
      if (include.includes('grading_periods')) {
        return HttpResponse.json(MOCK_GRADING_PERIODS_EMPTY)
      }
      return HttpResponse.json({})
    }),
    http.get('*/api/v1/external_tools/visible_course_nav_tools', () => {
      return HttpResponse.json(MOCK_COURSE_APPS)
    }),
    http.get('*/api/v1/courses/30/tabs', () => {
      return HttpResponse.json(MOCK_COURSE_TABS)
    }),
    http.get('*/api/v1/courses/30/assignment_groups', () => {
      return HttpResponse.json(MOCK_ASSIGNMENT_GROUPS)
    }),
    http.get('*/api/v1/courses/30/enrollments', () => {
      return HttpResponse.json(MOCK_ENROLLMENTS)
    }),
    http.get('*/api/v1/announcements', () => {
      return HttpResponse.json([])
    }),
    http.get('*/api/v1/courses/30/groups', () => {
      return HttpResponse.json(MOCK_GROUPS)
    }),
  )

  global.ENV = defaultEnv
  document.body.appendChild(createModulesPartial())
})

afterEach(() => {
  global.ENV = {}

  // K5Course moves this element into the mounted React container, which gets auto-cleaned
  // by RTL
  const modulesContainer = document.getElementById('k5-modules-container')
  modulesContainer?.remove()

  localStorage.clear()
  server.resetHandlers()
  window.location.hash = ''
})

describe('K-5 Subject Course', () => {
  describe('Student View Button functionality', () => {
    it('Shows the Student View button when the user has student view mode access', () => {
      const {getByTestId} = render(<K5Course {...defaultProps} showStudentView={true} />)
      expect(getByTestId('student-view-btn')).toBeInTheDocument()
    })

    it('Does not show the Student View button when the user does not have student view mode access', () => {
      const {queryByTestId} = render(<K5Course {...defaultProps} />)
      expect(queryByTestId('student-view-btn')).not.toBeInTheDocument()
    })

    it('Should open student view path when clicked', () => {
      const {getByTestId} = render(<K5Course {...defaultProps} showStudentView={true} />)
      const studentViewBtn = getByTestId('student-view-btn')
      expect(studentViewBtn.href).toBe('http://localhost/courses/30/student_view/1')
    })

    it('Should keep the navigation tab when accessing student view mode', () => {
      const {getByRole, getByTestId} = render(<K5Course {...defaultProps} showStudentView={true} />)
      getByRole('tab', {name: 'Arts and Crafts Grades'}).click()
      const studentViewBtn = getByTestId('student-view-btn')
      expect(studentViewBtn.href).toBe('http://localhost/courses/30/student_view/1#grades')
    })

    describe('Student View mode enable', () => {
      beforeEach(() => {
        document.body.appendChild(createStudentView())
      })
      afterEach(() => {
        const studentViewBarContainer = document.getElementById('student-view-bar-container')
        studentViewBarContainer.remove()
      })

      it('Should keep the navigation tab when the fake student is reset', () => {
        const {getByRole} = render(<K5Course {...defaultProps} showStudentView={true} />)
        const resetStudentBtn = getByRole('link', {name: 'Reset student'})
        getByRole('tab', {name: 'Arts and Crafts Resources'}).click()
        expect(resetStudentBtn.href).toBe('http://localhost/courses/30/test_student#resources')
      })

      it('Should keep the navigation tab when leaving student view mode', () => {
        const {getByRole} = render(<K5Course {...defaultProps} showStudentView={true} />)
        const leaveStudentViewBtn = getByRole('link', {name: 'Leave student view'})
        getByRole('tab', {name: 'Arts and Crafts Grades'}).click()
        expect(leaveStudentViewBtn.href).toBe('http://localhost/courses/30/student_view#grades')
      })
    })
  })

  describe('Self-enrollment buttons', () => {
    it("renders a join button if selfEnrollment.option is 'enroll'", () => {
      const selfEnrollment = {
        option: 'enroll',
        url: 'http://enroll_url/',
      }
      const {getByRole} = render(<K5Course {...defaultProps} selfEnrollment={selfEnrollment} />)
      const button = getByRole('link', {name: 'Join this Subject'})
      expect(button).toBeInTheDocument()
      expect(button.href).toBe('http://enroll_url/')
    })

    it("renders a drop button and modal if selfEnrollment.option is 'unenroll'", () => {
      const selfEnrollment = {
        option: 'unenroll',
        url: 'http://unenroll_url/',
      }
      const {getByRole, getByText} = render(
        <K5Course {...defaultProps} selfEnrollment={selfEnrollment} />,
      )
      const button = getByRole('button', {name: 'Drop this Subject'})
      expect(button).toBeInTheDocument()
      act(() => button.click())
      expect(getByText('Drop Arts and Crafts')).toBeInTheDocument()
      expect(getByText('Confirm Unenrollment')).toBeInTheDocument()
      expect(
        getByText(
          'Are you sure you want to unenroll in this subject? You will no longer be able to see the subject roster or communicate directly with the teachers, and you will no longer see subject events in your stream and as notifications.',
        ),
      ).toBeInTheDocument()
      expect(getByRole('button', {name: 'Cancel'})).toBeInTheDocument()
    })

    it('sends a POST to drop the course after confirming in the modal', async () => {
      let postCalled = false
      server.use(
        http.post('http://unenroll_url/', () => {
          postCalled = true
          return new HttpResponse(null, {status: 200})
        }),
      )
      const selfEnrollment = {
        option: 'unenroll',
        url: 'http://unenroll_url/',
      }
      const {getByRole, getAllByRole, getByText} = render(
        <K5Course {...defaultProps} selfEnrollment={selfEnrollment} />,
      )
      const openModalButton = getByRole('button', {name: 'Drop this Subject'})
      act(() => openModalButton.click())
      const dropButton = getAllByRole('button', {name: 'Drop this Subject'})[1]
      act(() => dropButton.click())
      expect(getByText('Dropping subject')).toBeInTheDocument()
      await waitFor(() => expect(postCalled).toBe(true))
    })

    it('renders neither if selfEnrollment is nil', () => {
      const {getByText, queryByText} = render(<K5Course {...defaultProps} />)
      expect(getByText('Arts and Crafts')).toBeInTheDocument()
      expect(queryByText('Join this Subject')).not.toBeInTheDocument()
      expect(queryByText('Drop this Subject')).not.toBeInTheDocument()
    })
  })
})
