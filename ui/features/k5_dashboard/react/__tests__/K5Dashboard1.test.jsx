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
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import React from 'react'
import {
  createPlannerMocks,
  MOCK_TODOS,
  defaultEnv,
  defaultK5DashboardProps as defaultProps,
} from './mocks'

import {destroyContainer} from '@canvas/alerts/react/FlashAlert'
import K5Dashboard from '../K5Dashboard'
import fakeENV from '@canvas/test-utils/fakeENV'

import {MockedQueryProvider} from '@canvas/test-utils/query'

vi.mock('@canvas/util/globalUtils', () => ({
  reloadWindow: vi.fn(),
}))

const render = children =>
  testingLibraryRender(<MockedQueryProvider>{children}</MockedQueryProvider>)

const server = setupServer()

// Track requests for assertions
let requestLog = []
const trackRequest = url => requestLog.push(url)

beforeAll(() => {
  server.listen()
})

beforeEach(() => {
  requestLog = []

  // Set up planner mocks (already MSW)
  server.use(...createPlannerMocks())

  // Set up K5 Dashboard mocks with request tracking
  server.use(
    http.get(/\/api\/v1\/announcements.*/, ({request}) => {
      trackRequest(request.url)
      return HttpResponse.json([
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
      ])
    }),
    http.get(/\/api\/v1\/users\/self\/courses.*/, () =>
      HttpResponse.json([
        {
          id: '1',
          name: 'Economics 101',
          has_grading_periods: false,
          enrollments: [
            {computed_current_score: 82, computed_current_grade: 'B-', type: 'student'},
          ],
          homeroom_course: false,
        },
        {
          id: '2',
          name: 'Homeroom Class',
          has_grading_periods: false,
          enrollments: [
            {computed_current_score: null, computed_current_grade: null, type: 'student'},
          ],
          homeroom_course: true,
        },
      ]),
    ),
    http.get('api/v1/courses/2', () =>
      HttpResponse.json({
        id: '2',
        syllabus_body: "<p>Here's the grading scheme for this class.</p>",
      }),
    ),
    http.get(/\/api\/v1\/external_tools\/visible_course_nav_tools.*/, ({request}) => {
      trackRequest(request.url)
      return HttpResponse.json([
        {
          id: '17',
          course_navigation: {text: 'Google Apps', icon_url: 'google.png'},
          context_id: '1',
          context_name: 'Economics 101',
        },
      ])
    }),
    http.get(/\/api\/v1\/courses\/2\/users.*/, () =>
      HttpResponse.json([
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
      ]),
    ),
    http.get(/\/api\/v1\/users\/self\/todo.*/, () =>
      HttpResponse.json([
        {
          assignment: {
            id: '10',
            due_at: null,
            all_dates: [{base: true, due_at: null}],
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
      ]),
    ),
    http.put('/api/v1/users/self/settings', async ({request}) => {
      trackRequest(request.url)
      const body = await request.text()
      requestLog.push({url: request.url, body})
      return HttpResponse.json({})
    }),
    http.get('/api/v1/calendar_events', ({request}) => {
      const url = new URL(request.url)
      const type = url.searchParams.get('type')
      const importantDates = url.searchParams.get('important_dates')

      if (importantDates === 'true' && type === 'assignment') {
        return HttpResponse.json(MOCK_ASSIGNMENTS)
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
  sessionStorage.clear()
  window.location.hash = ''
  destroyContainer()
})

afterAll(() => {
  server.close()
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
      const settingsRequests = requestLog.filter(
        r => typeof r === 'object' && r.url && r.url.includes('/api/v1/users/self/settings'),
      )
      expect(settingsRequests.length).toBeGreaterThan(0)
      const lastRequest = settingsRequests[settingsRequests.length - 1]
      expect(lastRequest.body).toEqual(
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

    // FOO-3830: Test moved to K5DashboardDueTodayMissing.test.jsx for CI reliability
    // "shows due today and missing items links pointing to the schedule tab of the course"

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
    // Note: This test is simplified to work around MSW/axios interception issues.
    // It verifies that when the dashboard_cards API returns empty, no announcements
    // or external tools API calls are made (which happens when cards are empty).
    // The full empty state UI is tested in HomeroomPage.test.jsx
    it('displays an empty state on the homeroom and schedule tabs if the user has no cards', async () => {
      // Override the cards mock to return empty array
      server.use(http.get('/api/v1/dashboard/dashboard_cards', () => HttpResponse.json([])))
      sessionStorage.setItem('dashcards_for_user_1', JSON.stringify([]))
      render(<K5Dashboard {...defaultProps} plannerEnabled={true} />)
      // Verify the component respects empty cards by checking that no
      // card-dependent API calls are made
      await waitFor(() => {
        const announcementCalls = requestLog.filter(
          url => typeof url === 'string' && /\/api\/v1\/announcements.*/.test(url),
        )
        expect(announcementCalls).toHaveLength(0)
        const externalToolsCalls = requestLog.filter(
          url =>
            typeof url === 'string' &&
            /\/api\/v1\/external_tools\/visible_course_nav_tools.*/.test(url),
        )
        expect(externalToolsCalls).toHaveLength(0)
      })
    }, 10000)

    it('only fetches announcements based on cards once per page load', async () => {
      sessionStorage.setItem('dashcards_for_user_1', JSON.stringify(MOCK_CARDS))
      render(<K5Dashboard {...defaultProps} />)
      await waitFor(() => {
        const announcementCalls = requestLog.filter(
          url => typeof url === 'string' && /\/api\/v1\/announcements.*latest_only=true/.test(url),
        )
        expect(announcementCalls).toHaveLength(1)
      })
    })

    it('only fetches announcements and apps if there are any cards', async () => {
      // Override the cards mock to return empty array
      server.use(http.get('/api/v1/dashboard/dashboard_cards', () => HttpResponse.json([])))
      sessionStorage.setItem('dashcards_for_user_1', JSON.stringify([]))
      render(<K5Dashboard {...defaultProps} />)
      await waitFor(() => {
        const announcementCalls = requestLog.filter(
          url => typeof url === 'string' && /\/api\/v1\/announcements.*/.test(url),
        )
        expect(announcementCalls).toHaveLength(0)

        const externalToolsCalls = requestLog.filter(
          url =>
            typeof url === 'string' &&
            /\/api\/v1\/external_tools\/visible_course_nav_tools.*/.test(url),
        )
        expect(externalToolsCalls).toHaveLength(0)
      })
    })
  })
})
