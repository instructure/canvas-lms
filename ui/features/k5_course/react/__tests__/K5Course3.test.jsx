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
  describe('Subject announcements', () => {
    // LX-2162
    // Skipped: Date formatting differs between Jest and Vitest due to timezone handling
    it.skip('shows the latest announcement, attachment, date, and edit button on the subject home', () => {
      const {getByText, getByRole} = render(<K5Course {...defaultProps} canManage={true} />)
      const button = getByRole('link', {name: 'Edit announcement Important announcement'})
      const attachment = getByRole('link', {name: 'hw.pdf'})
      const targetDate = new Date(`2021-${getOneMonthAgo()}-14T17:06:21Z`)
      const datePortion = new Intl.DateTimeFormat('en', {
        month: 'short',
        day: 'numeric',
        timeZone: defaultEnv.TIMEZONE,
      }).format(targetDate)
      const timePortion = new Intl.DateTimeFormat('en', {
        hour: 'numeric',
        minute: 'numeric',
        timeZone: defaultEnv.TIMEZONE,
      })
        .format(targetDate)
        .replace(/ [AP]M$/i, '')

      expect(getByText('Important announcement')).toBeInTheDocument()
      expect(getByText('Read this closely.')).toBeInTheDocument()
      expect(button).toBeInTheDocument()
      expect(button.href).toContain('/courses/30/discussion_topics/12')
      expect(attachment).toBeInTheDocument()
      expect(attachment.href).toBe('http://address/to/hw.pdf')
      expect(getByText(new RegExp(`${datePortion} at ${timePortion}`, 'i'))).toBeInTheDocument()
    })

    it('hides the edit button if student', () => {
      const props = defaultProps
      props.latestAnnouncement.permissions.update = false
      const {queryByRole} = render(<K5Course {...props} />)
      expect(
        queryByRole('link', {name: 'Edit announcement Important announcement'}),
      ).not.toBeInTheDocument()
    })

    it('puts the announcement on whichever tab is set as main tab', () => {
      const tabs = [{id: '10'}, {id: '0'}]
      const {getByText} = render(<K5Course {...defaultProps} tabs={tabs} />)
      expect(getByText('Important announcement')).toBeInTheDocument()
    })
  })

  describe('Home tab', () => {
    it('shows front page content if a front page is set', () => {
      const {getByText} = render(<K5Course {...defaultProps} defaultTab={TAB_IDS.HOME} />)
      expect(getByText('Time to learn!')).toBeInTheDocument()
    })

    it('shows an edit button when front page is set', () => {
      const {getByRole} = render(<K5Course {...defaultProps} defaultTab={TAB_IDS.HOME} />)
      const button = getByRole('link', {name: 'Edit home page'})
      expect(button).toBeInTheDocument()
      expect(button.href).toContain('/courses/30/pages/home/edit')
    })

    const emptyCourseOverview = {
      body: null,
      url: null,
      canEdit: null,
    }

    it('shows an empty home state if the front page is not set', () => {
      const {getByText, getByTestId} = render(
        <K5Course
          {...defaultProps}
          courseOverview={emptyCourseOverview}
          defaultTab={TAB_IDS.HOME}
        />,
      )
      expect(getByTestId('empty-home-panda')).toBeInTheDocument()
      expect(getByText("This is where you'll land when your home is complete.")).toBeInTheDocument()
    })

    describe('manage home button', () => {
      it('shows the home manage button to teachers when the front page is not set ', () => {
        const {getByTestId} = render(
          <K5Course
            {...defaultProps}
            courseOverview={emptyCourseOverview}
            defaultTab={TAB_IDS.HOME}
            canManage={true}
          />,
        )
        expect(getByTestId('manage-home-button')).toBeInTheDocument()
      })

      it('does not show the home manage button to students', () => {
        const {queryByTestId} = render(
          <K5Course
            {...defaultProps}
            courseOverview={emptyCourseOverview}
            defaultTab={TAB_IDS.HOME}
          />,
        )
        expect(queryByTestId('manage-home-button')).not.toBeInTheDocument()
      })

      it('sends the user to the course pages list if the course has wiki pages', () => {
        const {getByTestId} = render(
          <K5Course
            {...defaultProps}
            courseOverview={emptyCourseOverview}
            defaultTab={TAB_IDS.HOME}
            canManage={true}
          />,
        )
        const manageHomeLink = getByTestId('manage-home-button')
        expect(manageHomeLink.href).toMatch('/courses/30/pages')
      })

      it('sends the user to create a new page if the course does not have any wiki page', () => {
        const {getByTestId} = render(
          <K5Course
            {...defaultProps}
            hasWikiPages={false}
            courseOverview={emptyCourseOverview}
            defaultTab={TAB_IDS.HOME}
            canManage={true}
          />,
        )
        const manageHomeLink = getByTestId('manage-home-button')
        expect(manageHomeLink.href).toMatch('/courses/30/pages/home')
      })
    })
  })
})
