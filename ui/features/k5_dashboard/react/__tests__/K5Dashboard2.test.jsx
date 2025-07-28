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
import {
  MOCK_ACCOUNT_CALENDAR_EVENT,
  MOCK_ASSIGNMENTS,
  MOCK_CARDS,
  MOCK_EVENTS,
} from '@canvas/k5/react/__tests__/fixtures'
import {resetPlanner} from '@canvas/planner'
import {act, screen, render as testingLibraryRender, waitFor} from '@testing-library/react'
import fetchMock from 'fetch-mock'
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
import * as ReactQuery from '@tanstack/react-query'

jest.mock('@canvas/util/globalUtils', () => ({
  reloadWindow: jest.fn(),
}))

const render = children =>
  testingLibraryRender(<MockedQueryProvider>{children}</MockedQueryProvider>)

const server = setupServer()

const ASSIGNMENTS_URL = /\/api\/v1\/calendar_events\?type=assignment&important_dates=true&.*/
const EVENTS_URL = /\/api\/v1\/calendar_events\?type=event&important_dates=true&.*/
const announcements = [
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
const gradeCourses = [
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
const syllabus = {
  id: '2',
  syllabus_body: "<p>Here's the grading scheme for this class.</p>",
}
const apps = [
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
const staff = [
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

beforeAll(() => {
  server.listen()
})

beforeEach(() => {
  const handlers = createPlannerMocks()
  server.use(...handlers)
  fetchMock.get(/\/api\/v1\/announcements.*/, announcements)
  fetchMock.get(/\/api\/v1\/users\/self\/courses.*/, gradeCourses)
  fetchMock.get(encodeURI('api/v1/courses/2?include[]=syllabus_body'), syllabus)
  fetchMock.get(/\/api\/v1\/external_tools\/visible_course_nav_tools.*/, apps)
  fetchMock.get(/\/api\/v1\/courses\/2\/users.*/, staff)
  fetchMock.get(/\/api\/v1\/users\/self\/todo.*/, MOCK_TODOS)
  fetchMock.put('/api/v1/users/self/settings', {})
  fetchMock.get(ASSIGNMENTS_URL, MOCK_ASSIGNMENTS)
  fetchMock.get(EVENTS_URL, MOCK_EVENTS)
  fetchMock.post(/\/api\/v1\/calendar_events\/save_selected_contexts.*/, {
    status: 200,
    body: {status: 'ok'},
  })
  fetchMock.put(/\/api\/v1\/users\/\d+\/colors\.*/, {status: 200, body: []})
  fakeENV.setup(defaultEnv)
})

afterEach(() => {
  server.resetHandlers()
  fetchMock.restore()
  fakeENV.teardown()
  resetPlanner()
  resetCardCache()
  sessionStorage.clear()
  window.location.hash = ''
  destroyContainer()
})

afterAll(() => {
  server.close()
})

describe('K-5 Dashboard', () => {
  describe('Grades Section', () => {
    it('does not show the grades tab to students if hideGradesTabForStudents is set', async () => {
      const {findByRole, queryByRole} = render(
        <K5Dashboard
          {...defaultProps}
          currentUserRoles={['student']}
          hideGradesTabForStudents={true}
        />,
      )
      await findByRole('tab', {name: 'Homeroom'})
      expect(queryByRole('tab', {name: 'Grades'})).not.toBeInTheDocument()
    })

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
  describe('Important Dates', () => {
    it('renders a sidebar with important dates and no tray buttons on large screens', async () => {
      const {getByText, queryByText} = render(<K5Dashboard {...defaultProps} />)
      await waitFor(() => expect(getByText('History Discussion')).toBeInTheDocument())
      expect(getByText('Algebra 2')).toBeInTheDocument()
      expect(getByText('Important Dates')).toBeInTheDocument()
      expect(queryByText('View Important Dates')).not.toBeInTheDocument()
      expect(queryByText('Hide Important Dates')).not.toBeInTheDocument()
    })

    it('filters important dates to those selected', async () => {
      server.use(
        http.get('/api/v1/dashboard/dashboard_cards', () =>
          HttpResponse.json(MOCK_CARDS.map(c => ({...c, enrollmentState: 'active'}))),
        ),
      )
      // Only return assignments associated with course_1 on next call
      fetchMock.get(ASSIGNMENTS_URL, MOCK_ASSIGNMENTS.slice(0, 1), {overwriteRoutes: true})
      const {getByLabelText, getByTestId, getByText, queryByText} = render(
        <K5Dashboard
          {...defaultProps}
          selectedContextsLimit={1}
          selectedContextCodes={['course_1']}
        />,
      )
      await waitFor(() => {
        expect(getByText('Algebra 2')).toBeInTheDocument()
        expect(queryByText('History Discussion')).not.toBeInTheDocument()
        expect(queryByText('History Exam')).not.toBeInTheDocument()
      })
      expect(fetchMock.lastUrl(ASSIGNMENTS_URL)).toMatch('context_codes%5B%5D=course_1')
      expect(fetchMock.lastUrl(ASSIGNMENTS_URL)).not.toMatch('context_codes%5B%5D=course_3')
      // Only return assignments associated with course_3 on next call
      fetchMock.get(ASSIGNMENTS_URL, MOCK_ASSIGNMENTS.slice(1, 3), {overwriteRoutes: true})
      act(() => getByTestId('filter-important-dates-button').click())

      const subjectCalendarEconomics = getByLabelText('Economics 101', {selector: 'input'})
      expect(subjectCalendarEconomics).toBeChecked()

      const subjectCalendarMaths = getByLabelText('The Maths', {selector: 'input'})
      expect(subjectCalendarMaths).not.toBeChecked()

      act(() => subjectCalendarEconomics.click())
      act(() => subjectCalendarMaths.click())
      act(() => getByText('Submit').click())
      await waitFor(() => {
        expect(queryByText('Algebra 2')).not.toBeInTheDocument()
        expect(getByText('History Discussion')).toBeInTheDocument()
        expect(getByText('History Exam')).toBeInTheDocument()
      })
      expect(fetchMock.lastUrl(ASSIGNMENTS_URL)).not.toMatch('context_codes%5B%5D=course_1')
      expect(fetchMock.lastUrl(ASSIGNMENTS_URL)).toMatch('context_codes%5B%5D=course_3')
    })

    it('loads important dates on the grades tab', async () => {
      const {getByText} = render(<K5Dashboard {...defaultProps} defaultTab="tab-grades" />)
      await waitFor(() => expect(getByText('History Discussion')).toBeInTheDocument())
    })

    it('includes account calendar events', async () => {
      fetchMock.get(EVENTS_URL, [...MOCK_EVENTS, MOCK_ACCOUNT_CALENDAR_EVENT], {
        overwriteRoutes: true,
      })
      const {getByText} = render(
        <K5Dashboard {...defaultProps} selectedContextCodes={['course_1', 'account_1']} />,
      )
      await waitFor(() => expect(getByText('History Discussion')).toBeInTheDocument())
      expect(fetchMock.lastUrl(EVENTS_URL)).toMatch(
        'context_codes%5B%5D=course_1&context_codes%5B%5D=account_1',
      )
      ;['Morning Yoga', 'Football Game', 'CSU'].forEach(label =>
        expect(getByText(label)).toBeInTheDocument(),
      )
    })
  })
})
