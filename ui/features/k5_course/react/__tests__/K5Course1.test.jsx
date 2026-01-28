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
  describe('Tabs Header', () => {
    const bannerImageUrl = 'https://example.com/path/to/banner.jpeg'
    const cardImageUrl = 'https://example.com/path/to/image.png'

    it('displays a huge version of the course banner image if set', () => {
      const {getByTestId} = render(
        <K5Course {...defaultProps} bannerImageUrl={bannerImageUrl} cardImageUrl={cardImageUrl} />,
      )
      const hero = getByTestId('k5-course-header-hero')

      expect(hero).toBeInTheDocument()
      expect(hero.style.getPropertyValue('background-image')).toBe(`url(${bannerImageUrl})`)
    })

    it('displays a huge version of the course card image if set and no banner image is set', () => {
      const {getByTestId} = render(<K5Course {...defaultProps} cardImageUrl={cardImageUrl} />)
      const hero = getByTestId('k5-course-header-hero')

      expect(hero).toBeInTheDocument()
      expect(hero.style.getPropertyValue('background-image')).toBe(`url(${cardImageUrl})`)
    })

    it('displays the course color if one is set but no course images are set', () => {
      const {getByTestId} = render(<K5Course {...defaultProps} color="#bb8" />)
      const hero = getByTestId('k5-course-header-hero')

      expect(hero.style.getPropertyValue('background-color')).toBe('rgb(187, 187, 136)')
    })

    it('displays a gray background on the hero header if no course color or images are set', () => {
      const {getByTestId} = render(<K5Course {...defaultProps} />)
      const hero = getByTestId('k5-course-header-hero')

      expect(hero.style.getPropertyValue('background-color')).toBe('rgb(51, 68, 81)')
    })

    it('displays the course name', () => {
      const {getByText} = render(<K5Course {...defaultProps} />)
      expect(getByText(defaultProps.name)).toBeInTheDocument()
    })

    it('shows Home, Schedule, Modules, Grades, and Resources options if configured', () => {
      const {getByText} = render(<K5Course {...defaultProps} />)
      ;['Home', 'Schedule', 'Modules', 'Grades', 'Resources'].forEach(label => {
        expect(getByText(label)).toBeInTheDocument()
        expect(getByText('Arts and Crafts ' + label)).toBeInTheDocument()
      })
    })

    it('defaults to the first tab', () => {
      const {getByRole} = render(<K5Course {...defaultProps} />)
      expect(getByRole('tab', {name: 'Arts and Crafts Home', selected: true})).toBeInTheDocument()
    })

    it('only renders non-hidden tabs, in the order they are provided', () => {
      const tabs = [
        {id: '10'},
        {id: '5', hidden: true},
        {id: '19'},
        {id: 'context_external_tool_3', hidden: true},
      ]
      const {getAllByRole} = render(
        <K5Course {...defaultProps} tabs={tabs} hasSyllabusBody={false} />,
      )
      const renderedTabs = getAllByRole('tab')
      expect(renderedTabs.map(({id}) => id.replace('tab-', ''))).toEqual([
        TAB_IDS.MODULES,
        TAB_IDS.SCHEDULE,
      ])
    })

    it('still renders Resource tab if course has no LTIs but has Important Info', () => {
      const tabs = [{id: '10'}, {id: '5'}, {id: '19'}]
      const {getByText} = render(<K5Course {...defaultProps} tabs={tabs} />)
      expect(getByText('Resources')).toBeInTheDocument()
      expect(getByText('Arts and Crafts Resources')).toBeInTheDocument()
    })

    it('does not render Resource tab if course has no LTIs nor Important Info', () => {
      const tabs = [{id: '10'}, {id: '5'}, {id: '19'}]
      const {queryByText} = render(
        <K5Course {...defaultProps} tabs={tabs} hasSyllabusBody={false} />,
      )
      expect(queryByText('Resources')).not.toBeInTheDocument()
      expect(queryByText('Arts and Crafts Resources')).not.toBeInTheDocument()
    })

    it('renders an empty state instead of any tabs if none are provided', () => {
      const {getByTestId, getByText, queryByRole} = render(
        <K5Course {...defaultProps} tabs={[]} hasSyllabusBody={false} />,
      )
      expect(getByText(defaultProps.name)).toBeInTheDocument()
      expect(queryByRole('tab')).not.toBeInTheDocument()
      expect(getByTestId('space-panda')).toBeInTheDocument()
      expect(getByText('Welcome to the cold, dark void of Arts and Crafts.')).toBeInTheDocument()
    })

    it('renders a link to update tab settings if no tabs are provided and the user has manage permissions', () => {
      const {getByRole} = render(
        <K5Course {...defaultProps} canManage={true} tabs={[]} hasSyllabusBody={false} />,
      )
      const link = getByRole('link', {name: 'Reestablish your world'})
      expect(link).toBeInTheDocument()
      expect(link.href).toBe('http://localhost/courses/30/settings#tab-navigation')
    })

    it('does not render anything when tabContentOnly is true', () => {
      const {queryByText} = render(<K5Course {...defaultProps} tabContentOnly={true} />)

      // Course hero shouldn't be shown
      expect(queryByText(defaultProps.name)).not.toBeInTheDocument()

      // Tabs should not be shown
      ;['Home', 'Schedule', 'Modules', 'Grades', 'Resources', 'Groups'].forEach(t =>
        expect(queryByText(t)).not.toBeInTheDocument(),
      )
    })
  })

  describe('Manage course functionality', () => {
    it('Shows a manage button when the user has read_as_admin permissions', () => {
      const {getByText, getByRole} = render(<K5Course {...defaultProps} canReadAsAdmin={true} />)
      expect(getByRole('link', {name: 'Manage Subject: Arts and Crafts'})).toBeInTheDocument()
      expect(getByText('Manage Subject')).toBeInTheDocument()
    })

    it('Should redirect to course settings path when clicked', async () => {
      const {getByRole} = render(<K5Course {...defaultProps} canReadAsAdmin={true} />)
      const manageSubjectBtn = getByRole('link', {name: 'Manage Subject: Arts and Crafts'})
      expect(manageSubjectBtn.href).toBe('http://localhost/courses/30/settings')
    })

    it('Does not show a manage button when the user does not have read_as_admin permissions', () => {
      const {queryByRole} = render(<K5Course {...defaultProps} />)
      expect(queryByRole('link', {name: 'Manage Subject: Arts and Crafts'})).not.toBeInTheDocument()
    })
  })
})
