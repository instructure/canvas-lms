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
import {MOCK_ASSIGNMENTS, MOCK_CARDS, MOCK_EVENTS} from '@canvas/k5/react/__tests__/fixtures'
import {resetPlanner} from '@canvas/planner'
import {act, screen, render as testingLibraryRender, waitFor} from '@testing-library/react'
import fetchMock from 'fetch-mock'
import axios from 'axios'
import AxiosMockAdapter from 'axios-mock-adapter'
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

jest.mock('@canvas/util/globalUtils', () => ({
  reloadWindow: jest.fn(),
}))

const render = children =>
  testingLibraryRender(<MockedQueryProvider>{children}</MockedQueryProvider>)

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

let axiosMock

beforeEach(() => {
  axiosMock = new AxiosMockAdapter(axios)
  axiosMock.onGet(/\/api\/v1\/dashboard\/dashboard_cards(\?.*)?$/).reply(200, MOCK_CARDS)
  axiosMock.onGet(/\/api\/v1\/announcements.*latest_only=true/).reply(200, announcements)
  createPlannerMocks()
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
  axiosMock.restore()
  fetchMock.restore()
  fakeENV.teardown()
  resetPlanner()
  resetCardCache()
  sessionStorage.clear()
  window.location.hash = ''
  destroyContainer()
})

describe('K-5 Dashboard', () => {
  it('displays a welcome message to the logged-in user', () => {
    const {getByText} = render(<K5Dashboard {...defaultProps} />)
    expect(getByText('Welcome, Geoffrey Jellineck!')).toBeInTheDocument()
  })

  it('allows admins and teachers to turn off the elementary dashboard', async () => {
    const {getByRole} = render(
      <K5Dashboard {...defaultProps} canDisableElementaryDashboard={true} />,
    )
    const optionsButton = getByRole('button', {name: 'Dashboard Options'})
    act(() => optionsButton.click())
    // There should be an Homeroom View menu option already checked
    const elementaryViewOption = screen.getByRole('menuitemradio', {
      name: 'Homeroom View',
      checked: true,
    })
    expect(elementaryViewOption).toBeInTheDocument()
    // There should be a Classic View menu option initially un-checked
    const classicViewOption = screen.getByRole('menuitemradio', {
      name: 'Classic View',
      checked: false,
    })
    expect(classicViewOption).toBeInTheDocument()
    // Clicking the Classic View option should update the user's dashboard setting
    act(() => classicViewOption.click())
    await waitFor(() => {
      expect(fetchMock.called('/api/v1/users/self/settings', 'PUT')).toBe(true)
      expect(fetchMock.lastOptions('/api/v1/users/self/settings').body).toEqual(
        JSON.stringify({
          elementary_dashboard_disabled: true,
        }),
      )
    })
  })

  describe('Homeroom Section', () => {
    it('displays "My Subjects" heading', async () => {
      const {findByText} = render(<K5Dashboard {...defaultProps} />)
      expect(await findByText('My Subjects')).toBeInTheDocument()
    })

    it('shows course cards, excluding homerooms and subjects with pending invites', async () => {
      const {findByLabelText, queryByLabelText} = render(<K5Dashboard {...defaultProps} />)
      expect(await findByLabelText('Economics 101')).toBeInTheDocument()
      expect(queryByLabelText('Home Room')).not.toBeInTheDocument()
      expect(queryByLabelText('The Maths')).not.toBeInTheDocument()
    })

    it('shows latest announcement from each homeroom', async () => {
      const {findByText, getByText} = render(<K5Dashboard {...defaultProps} />)
      expect(await findByText('Announcement here')).toBeInTheDocument()
      expect(getByText('This is the announcement')).toBeInTheDocument()
      const attachment = getByText('exam1.pdf')
      expect(attachment).toBeInTheDocument()
      expect(attachment.href).toBe('http://google.com/download')
    })

    it('shows unpublished indicator if homeroom is unpublished', async () => {
      const {findByText, getByText} = render(<K5Dashboard {...defaultProps} />)
      await findByText('Announcement here')
      expect(getByText('Your homeroom is currently unpublished.')).toBeInTheDocument()
    })

    // FOO-3830
    it.skip('shows due today and missing items links pointing to the schedule tab of the course (flaky)', async () => {
      const {findByTestId} = render(<K5Dashboard {...defaultProps} plannerEnabled={true} />)
      const dueTodayLink = await findByTestId('number-due-today')
      expect(dueTodayLink).toBeInTheDocument()
      expect(dueTodayLink).toHaveTextContent('View 1 items due today for course Economics 101')
      expect(dueTodayLink.getAttribute('href')).toMatch('/courses/1?focusTarget=today#schedule')

      const missingItemsLink = await findByTestId('number-missing')
      expect(missingItemsLink).toBeInTheDocument()
      expect(missingItemsLink).toHaveTextContent('View 2 missing items for course Economics 101')
      expect(missingItemsLink.getAttribute('href')).toMatch(
        '/courses/1?focusTarget=missing-items#schedule',
      )
    })

    it('shows the latest announcement for each subject course if one exists', async () => {
      const {findByText} = render(<K5Dashboard {...defaultProps} />)
      const announcementLink = await findByText("This sure isn't a homeroom")
      expect(announcementLink).toBeInTheDocument()
      expect(announcementLink.closest('a').href).toMatch('/courses/1/announcements/21')
    })

    it('shows loading skeletons for course cards while they load', () => {
      const {container} = render(<K5Dashboard {...defaultProps} />)
      expect(container.querySelector('[data-testid="skeleton-wrapper"]')).toBeInTheDocument()
    })

    // FOO-3830
    it.skip('displays an empty state on the homeroom and schedule tabs if the user has no cards (flaky)', async () => {
      const {getByTestId, getByText} = render(
        <K5Dashboard {...defaultProps} plannerEnabled={true} />,
      )
      await waitFor(() =>
        expect(getByText("You don't have any active courses yet.")).toBeInTheDocument(),
      )
      expect(getByTestId('empty-dash-panda')).toBeInTheDocument()
      const scheduleTab = getByText('Schedule')
      act(() => scheduleTab.click())
      expect(getByText("You don't have any active courses yet.")).toBeInTheDocument()
      expect(getByTestId('empty-dash-panda')).toBeInTheDocument()
    })

    it('only fetches announcements based on cards once per page load', async () => {
      sessionStorage.setItem('dashcards_for_user_1', JSON.stringify(MOCK_CARDS))
      render(<K5Dashboard {...defaultProps} />)
      await waitFor(() => {
        const announcementCalls = fetchMock.calls(/\/api\/v1\/announcements.*latest_only=true/)
        expect(announcementCalls).toHaveLength(1)
      })
    })

    it('only fetches announcements and apps if there are any cards', async () => {
      sessionStorage.setItem('dashcards_for_user_1', JSON.stringify([]))
      render(<K5Dashboard {...defaultProps} />)
      await waitFor(() => {
        const announcementCalls = axiosMock.history.get.filter(call =>
          call.url.match(/\/api\/v1\/announcements.*/)
        )
        expect(announcementCalls).toHaveLength(0)

        const externalToolsCalls = axiosMock.history.get.filter(call =>
          call.url.match(/\/api\/v1\/external_tools\/visible_course_nav_tools.*/)
        )
        expect(externalToolsCalls).toHaveLength(0)
      })
    })
  })
})
