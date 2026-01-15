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

import {resetCardCache} from '@canvas/dashboard-card'
import {MOCK_ASSIGNMENTS, MOCK_EVENTS} from '@canvas/k5/react/__tests__/fixtures'
import {resetPlanner} from '@canvas/planner'
import {act, screen, render as testingLibraryRender, waitFor} from '@testing-library/react'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import React from 'react'
import {
  MOCK_TODOS,
  createPlannerMocks,
  defaultEnv,
  defaultK5DashboardProps as defaultProps,
} from './mocks'

import {destroyContainer} from '@canvas/alerts/react/FlashAlert'
import K5Dashboard from '../K5Dashboard'
import fakeENV from '@canvas/test-utils/fakeENV'

import {MockedQueryProvider} from '@canvas/test-utils/query'
import {queryClient} from '@canvas/query'

vi.mock('@canvas/util/globalUtils', () => ({
  reloadWindow: vi.fn(),
}))

const render = children =>
  testingLibraryRender(<MockedQueryProvider>{children}</MockedQueryProvider>)

const server = setupServer()

// Track requests for assertions
let requestLog = []
const trackRequest = url => requestLog.push(url)

// Mock data
const announcements = [
  {
    id: '20',
    context_code: 'course_2',
    title: 'Announcement here',
    message: '<p>This is the announcement</p>',
    html_url: 'http://google.com/announcement',
    permissions: {update: true},
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
const gradeCourses = [
  {
    id: '1',
    name: 'Economics 101',
    has_grading_periods: false,
    enrollments: [{computed_current_score: 82, computed_current_grade: 'B-', type: 'student'}],
    homeroom_course: false,
  },
  {
    id: '2',
    name: 'Homeroom Class',
    has_grading_periods: false,
    enrollments: [{computed_current_score: null, computed_current_grade: null, type: 'student'}],
    homeroom_course: true,
  },
]
const syllabus = {
  id: '2',
  syllabus_body: "<p>Here's the grading scheme for this class.</p>",
}
const apps = [
  {
    id: '17',
    course_navigation: {text: 'Google Apps', icon_url: 'google.png'},
    context_id: '1',
    context_name: 'Economics 101',
  },
]
const staff = [
  {
    id: '1',
    short_name: 'Mrs. Thompson',
    bio: 'Office Hours: 1-3pm W',
    avatar_url: '/images/avatar1.png',
    enrollments: [{role: 'TeacherEnrollment'}],
  },
  {
    id: '2',
    short_name: 'Tommy the TA',
    bio: 'Office Hours: 1-3pm F',
    avatar_url: '/images/avatar2.png',
    enrollments: [{role: 'TaEnrollment'}],
  },
]

// Store for dynamic assignment responses
let assignmentResponse = MOCK_ASSIGNMENTS

beforeAll(() => {
  server.listen()
})

beforeEach(() => {
  requestLog = []
  assignmentResponse = MOCK_ASSIGNMENTS

  server.use(
    ...createPlannerMocks(),
    http.get(/\/api\/v1\/announcements.*/, ({request}) => {
      trackRequest(request.url)
      return HttpResponse.json(announcements)
    }),
    http.get(/\/api\/v1\/users\/self\/courses.*/, () => HttpResponse.json(gradeCourses)),
    http.get('api/v1/courses/2', () =>
      HttpResponse.json({id: '2', syllabus_body: syllabus.syllabus_body}),
    ),
    http.get(/\/api\/v1\/external_tools\/visible_course_nav_tools.*/, ({request}) => {
      trackRequest(request.url)
      return HttpResponse.json(apps)
    }),
    http.get(/\/api\/v1\/courses\/2\/users.*/, () => HttpResponse.json(staff)),
    http.get(/\/api\/v1\/users\/self\/todo.*/, () => HttpResponse.json(MOCK_TODOS)),
    http.put('/api/v1/users/self/settings', () => HttpResponse.json({})),
    http.get('/api/v1/calendar_events', ({request}) => {
      const url = new URL(request.url)
      trackRequest(request.url)
      const type = url.searchParams.get('type')
      const importantDates = url.searchParams.get('important_dates')

      if (importantDates === 'true' && type === 'assignment') {
        return HttpResponse.json(assignmentResponse)
      }
      if (importantDates === 'true' && type === 'event') {
        return HttpResponse.json(MOCK_EVENTS)
      }
      return HttpResponse.json([])
    }),
    http.post(/\/api\/v1\/calendar_events\/save_selected_contexts.*/, () =>
      HttpResponse.json({status: 'ok'}),
    ),
    http.put(/\/api\/v1\/users\/\d+\/colors.*/, () => HttpResponse.json([])),
  )
  fakeENV.setup(defaultEnv)
})

afterEach(() => {
  server.resetHandlers()
  fakeENV.teardown()
  resetPlanner()
  resetCardCache()
  queryClient.clear()
  sessionStorage.clear()
  window.location.hash = ''
  destroyContainer()
})

afterAll(() => {
  server.close()
})

describe('K-5 Dashboard', () => {
  describe('Grades Section', () => {
    it(
      'does not show the grades tab to students if hideGradesTabForStudents is set',
      {timeout: 15000},
      async () => {
        const {findByRole, queryByRole} = render(
          <K5Dashboard
            {...defaultProps}
            currentUserRoles={['student']}
            hideGradesTabForStudents={true}
          />,
        )
        await findByRole('tab', {name: 'Homeroom'}, {timeout: 10000})
        expect(queryByRole('tab', {name: 'Grades'})).not.toBeInTheDocument()
      },
    )

    it('shows the grades tab to teachers even if hideGradesTabForStudents is set', async () => {
      const {findByRole} = render(
        <K5Dashboard
          {...defaultProps}
          currentUserRoles={['student', 'teacher']}
          hideGradesTabForStudents={true}
        />,
      )
      expect(await findByRole('tab', {name: 'Grades'})).toBeInTheDocument()
    })

    it('displays a score summary for each non-homeroom course', async () => {
      const {getByText, queryByText, findByRole} = render(
        <K5Dashboard {...defaultProps} defaultTab="tab-grades" />,
      )
      expect(await findByRole('link', {name: 'Economics 101'})).toBeInTheDocument()
      expect(getByText('B-')).toBeInTheDocument()
      expect(queryByText('Homeroom Class')).not.toBeInTheDocument()
    })
  })

  describe('Resources Section', () => {
    it('displays syllabus content for homeroom under important info section', async () => {
      const {getByText, findByText} = render(
        <K5Dashboard {...defaultProps} defaultTab="tab-resources" />,
      )
      expect(await findByText("Here's the grading scheme for this class.")).toBeInTheDocument()
      expect(getByText('Important Info')).toBeInTheDocument()
    })

    it("shows apps installed in the user's courses", async () => {
      const wrapper = render(<K5Dashboard {...defaultProps} defaultTab="tab-resources" />)

      const button = await wrapper.findByTestId('k5-app-button')
      expect(button).toBeInTheDocument()
      expect(button).toHaveTextContent('Google Apps')

      const icon = wrapper.getByTestId('renderedIcon')
      expect(icon).toBeInTheDocument()
      expect(icon.src).toContain('google.png')
    })

    it('shows the staff contact info for each staff member in all homeroom courses', async () => {
      const wrapper = render(<K5Dashboard {...defaultProps} defaultTab="tab-resources" />)
      expect(await wrapper.findByText('Mrs. Thompson')).toBeInTheDocument()
      expect(wrapper.getByText('Office Hours: 1-3pm W')).toBeInTheDocument()
      expect(wrapper.getByText('Teacher')).toBeInTheDocument()
      expect(wrapper.getByText('Tommy the TA')).toBeInTheDocument()
      expect(wrapper.getByText('Teaching Assistant')).toBeInTheDocument()
    })
  })

  describe('Todos Section', () => {
    it('displays todo tab to teachers', async () => {
      const {findByText} = render(<K5Dashboard {...defaultProps} currentUserRoles={['teacher']} />)
      const todoTab = await findByText('To Do')
      expect(todoTab).toBeInTheDocument()
      act(() => todoTab.click())

      const gradeButton = await findByText('Grade Plant a plant')
      expect(gradeButton).toBeInTheDocument()
    })

    it('does not show the todos tab to students or admins', async () => {
      const {findByRole, queryByRole} = render(
        <K5Dashboard {...defaultProps} currentUserRoles={['admin', 'student']} />,
      )
      expect(await findByRole('tab', {name: 'Homeroom', selected: true})).toBeInTheDocument()
      expect(queryByRole('tab', {name: 'To Do'})).not.toBeInTheDocument()
    })
  })
})
