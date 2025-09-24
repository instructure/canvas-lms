/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {MOCK_CARDS, MOCK_CARDS_2} from '@canvas/k5/react/__tests__/fixtures'
import {OBSERVER_COOKIE_PREFIX, clearObservedId} from '@canvas/observer-picker/ObserverGetObservee'
import {MOCK_OBSERVED_USERS_LIST} from '@canvas/observer-picker/react/__tests__/fixtures'
import {fetchShowK5Dashboard} from '@canvas/observer-picker/react/utils'
import {MockedQueryProvider} from '@canvas/test-utils/query'
import {reloadWindow} from '@canvas/util/globalUtils'
import injectGlobalAlertContainers from '@canvas/util/react/testing/injectGlobalAlertContainers'
import {act, render as testingLibraryRender, waitFor} from '@testing-library/react'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import React from 'react'
import K5Dashboard from '../K5Dashboard'
import {
  createPlannerMocks,
  defaultEnv,
  defaultK5DashboardProps as defaultProps,
  opportunities,
} from './mocks'

jest.mock('@canvas/util/globalUtils', () => ({
  reloadWindow: jest.fn(),
}))

injectGlobalAlertContainers()

jest.useFakeTimers()
jest.mock('@canvas/observer-picker/react/utils', () => ({
  ...jest.requireActual('@canvas/observer-picker/react/utils'),
  fetchShowK5Dashboard: jest.fn(),
}))

// Set up MSW server to handle unmocked requests and prevent console errors
const globalServer = setupServer(
  // Mock announcements endpoint that's called by K5Dashboard
  http.get('/api/v1/announcements', () => HttpResponse.json([])),
  // Mock dashboard cards endpoint
  http.get('/api/v1/dashboard/dashboard_cards', () => HttpResponse.json([])),
  // Mock missing submissions endpoint
  http.get('/api/v1/users/self/missing_submissions', () =>
    HttpResponse.json([], {headers: {link: 'url; rel="current"'}}),
  ),
  // Mock calendar events for important dates (assignments)
  http.get('/api/v1/calendar_events', ({request}) => {
    const url = new URL(request.url)
    const type = url.searchParams.get('type')
    const importantDates = url.searchParams.get('important_dates')

    if (importantDates === 'true') {
      return HttpResponse.json([])
    }
    return HttpResponse.json([])
  }),
  // Mock observer calendar events for important dates
  http.get('/api/v1/users/*/calendar_events', ({request}) => {
    const url = new URL(request.url)
    const importantDates = url.searchParams.get('important_dates')

    if (importantDates === 'true') {
      return HttpResponse.json([])
    }
    return HttpResponse.json([])
  }),
  // Mock planner items endpoint
  http.get('/api/v1/planner/items', () =>
    HttpResponse.json([], {headers: {link: 'url; rel="current"'}}),
  ),
  // Catch-all handler to silently handle any remaining unmocked requests
  http.get('*', () => HttpResponse.json({})),
)

beforeAll(() => globalServer.listen({onUnhandledRequest: 'bypass'}))
afterEach(() => globalServer.resetHandlers())
afterAll(() => globalServer.close())

const render = children =>
  testingLibraryRender(<MockedQueryProvider>{children}</MockedQueryProvider>)

const currentUserId = defaultProps.currentUser.id
const observedUserCookieName = `${OBSERVER_COOKIE_PREFIX}${currentUserId}`

describe('K5Dashboard Parent Support', () => {
  beforeEach(() => {
    document.cookie = `${observedUserCookieName}=4;path=/`
    global.ENV = defaultEnv
    fetchShowK5Dashboard.mockImplementation(() =>
      Promise.resolve({show_k5_dashboard: true, use_classic_font: false}),
    )
  })

  afterEach(() => {
    global.ENV = {}
    resetCardCache()
  })

  const opportunities2 = [
    {
      id: '3',
      course_id: '23',
      name: 'A new Assignment',
      points_possible: 10,
      html_url: '/courses/23/assignments/3',
      due_at: '2021-02-15T05:59:00Z',
      submission_types: ['online_text_entry'],
    },
  ]

  it('shows picker when user is an observer', () => {
    const {getByTestId} = render(
      <K5Dashboard
        {...defaultProps}
        canAddObservee={true}
        currentUserRoles={['user', 'observer']}
        observedUsersList={MOCK_OBSERVED_USERS_LIST}
      />,
    )
    const select = getByTestId('observed-student-dropdown')
    expect(select).toBeInTheDocument()
    expect(select.value).toBe('Student 4')
  })

  // LF-1141
  it.skip('prefetches dashboard cards with the correct url param', async () => {
    let requestUrl = null
    globalServer.use(
      http.get('/api/v1/dashboard/dashboard_cards', ({request}) => {
        requestUrl = request.url
        return HttpResponse.json(MOCK_CARDS)
      }),
    )

    render(
      <K5Dashboard
        {...defaultProps}
        currentUserRoles={['user', 'observer', 'teacher']}
        canAddObservee={true}
        observedUsersList={MOCK_OBSERVED_USERS_LIST}
      />,
    )
    // let the dashboard execute all its queries and render
    await waitFor(
      () => {
        expect(requestUrl).not.toBeNull()
      },
      {timeout: 5000},
    )
    expect(requestUrl).toContain('observed_user_id=4')
  })

  it.skip('does not make a request if the user has been already requested (flaky)', async () => {
    const requestUrls = []
    globalServer.use(
      http.get('/api/v1/dashboard/dashboard_cards', ({request}) => {
        requestUrls.push(request.url)
        const url = request.url
        if (url.includes('observed_user_id=4')) {
          return HttpResponse.json(MOCK_CARDS)
        } else if (url.includes('observed_user_id=2')) {
          return HttpResponse.json(MOCK_CARDS_2)
        }
      }),
    )

    const {findByText, getByTestId, getByText, queryByText} = render(
      <K5Dashboard
        {...defaultProps}
        currentUserRoles={['user', 'observer', 'teacher']}
        canAddObservee={true}
        observedUsersList={MOCK_OBSERVED_USERS_LIST}
      />,
    )
    expect(await findByText('Economics 101')).toBeInTheDocument()
    expect(queryByText('Economics 203')).not.toBeInTheDocument()
    const select = getByTestId('observed-student-dropdown')
    expect(select.value).toBe('Student 4')
    expect(requestUrls[requestUrls.length - 1]).toContain('observed_user_id=4')
    act(() => select.click())
    act(() => getByText('Student 2').click())
    expect(await findByText('Economics 203')).toBeInTheDocument()
    expect(queryByText('Economics 101')).not.toBeInTheDocument()
    expect(requestUrls[requestUrls.length - 1]).toContain('observed_user_id=2')
    act(() => select.click())
    act(() => getByText('Student 4').click())
    expect(await findByText('Economics 101')).toBeInTheDocument()
    expect(queryByText('Economics 203')).not.toBeInTheDocument()
    // Should not fetch student 4's cards again; they've been cached
    expect(requestUrls[requestUrls.length - 1]).toContain('observed_user_id=2')
    // 2 total requests - one for student 4, one for student 2
    expect(requestUrls).toHaveLength(2)
  })

  it.skip('shows the observee missing items on dashboard cards (flaky)', async () => {
    globalServer.use(
      http.get('/api/v1/dashboard/dashboard_cards', ({request}) => {
        const url = request.url
        if (url.includes('observed_user_id=4')) {
          return HttpResponse.json(MOCK_CARDS)
        } else if (url.includes('observed_user_id=2')) {
          return HttpResponse.json(MOCK_CARDS_2)
        }
      }),
      http.get('/api/v1/users/self/missing_submissions', ({request}) => {
        const url = request.url
        if (url.includes('observed_user_id=4')) {
          return HttpResponse.json(opportunities, {
            headers: {link: 'url; rel="current"'},
          })
        } else if (url.includes('observed_user_id=2')) {
          return HttpResponse.json(opportunities2, {
            headers: {link: 'url; rel="current"'},
          })
        }
      }),
    )
    createPlannerMocks()

    const {getByText, findByTestId, getByTestId} = render(
      <K5Dashboard
        {...defaultProps}
        currentUserRoles={['user', 'observer', 'teacher']}
        observedUsersList={MOCK_OBSERVED_USERS_LIST}
        canAddObservee={true}
        plannerEnabled={true}
      />,
    )
    // let the dashboard execute all its queries and render
    await waitFor(
      () => {
        expect(document.querySelectorAll('.ic-DashboardCard').length).toBeGreaterThan(0)
      },
      {timeout: 5000},
    )

    const missingItemsLink = await findByTestId('number-missing')
    expect(missingItemsLink).toBeInTheDocument()
    expect(missingItemsLink).toHaveTextContent(
      'View 2 missing items for course Economics 1012 missing',
    )

    const observerSelect = getByTestId('observed-student-dropdown')
    act(() => observerSelect.click())
    act(() => getByText('Student 2').click())

    await waitFor(() => {
      expect(getByTestId('number-missing')).toHaveTextContent(
        'View 1 missing items for course Economics 203',
      )
    })
    expect(getByTestId('number-missing')).toBeInTheDocument()
  })

  it('does not show options to disable k5 dashboard if student is selected', async () => {
    clearObservedId(defaultProps.currentUser.id)
    const {getByTestId, findByTestId, getByText, queryByTestId} = render(
      <K5Dashboard
        {...defaultProps}
        currentUserRoles={['user', 'observer', 'teacher']}
        observedUsersList={[defaultProps.currentUser, ...MOCK_OBSERVED_USERS_LIST]}
      />,
    )
    const select = getByTestId('observed-student-dropdown')
    expect(select.value).toBe('Geoffrey Jellineck')
    expect(await findByTestId('k5-dashboard-options')).toBeInTheDocument()

    act(() => select.click())
    act(() => getByText('Student 4').click())
    expect(select.value).toBe('Student 4')
    await waitFor(() => expect(queryByTestId('k5-dashboard-options')).not.toBeInTheDocument())
  })

  describe('switching to classic student', () => {
    const switchToStudent2 = async () => {
      const {findByRole, getByText} = render(
        <K5Dashboard
          {...defaultProps}
          currentUserRoles={['user', 'observer', 'teacher']}
          observedUsersList={MOCK_OBSERVED_USERS_LIST}
          canAddObservee={true}
          plannerEnabled={true}
        />,
      )
      const select = await findByRole('combobox', {name: 'Select a student to view'})
      await act(async () => {
        select.click()
        await waitFor(() => expect(getByText('Student 2')).toBeInTheDocument())
        getByText('Student 2').click()
      })
      // Wait for any async operations to complete
      await waitFor(() => expect(fetchShowK5Dashboard).toHaveBeenCalledWith('2'))
    }

    it('does not reload the page if a k5 student with the same font selection is selected in the picker', async () => {
      // Clear any previous calls
      reloadWindow.mockClear()
      // Explicitly set the same K5 settings for Student 2
      fetchShowK5Dashboard.mockImplementationOnce(() =>
        Promise.resolve({show_k5_dashboard: true, use_classic_font: false}),
      )
      await switchToStudent2()
      // Wait for any pending state updates
      await waitFor(() => {
        expect(reloadWindow).not.toHaveBeenCalled()
      })
    })

    it('reloads the page when a classic student is selected in the students picker', async () => {
      fetchShowK5Dashboard.mockImplementationOnce(() =>
        Promise.resolve({show_k5_dashboard: false, use_classic_font: false}),
      )
      await switchToStudent2()
      expect(reloadWindow).toHaveBeenCalled()
    })

    it('reloads the page when a k5 student with a different font selection is selected in the picker', async () => {
      fetchShowK5Dashboard.mockImplementationOnce(() =>
        Promise.resolve({show_k5_dashboard: true, use_classic_font: true}),
      )
      await switchToStudent2()
      expect(reloadWindow).toHaveBeenCalled()
    })
  })

  describe('grades tab', () => {
    it('is visible to observers who have student enrollments', async () => {
      clearObservedId(defaultProps.currentUser.id)
      const {findByRole} = render(
        <K5Dashboard
          {...defaultProps}
          currentUserRoles={['student', 'observer']}
          observedUsersList={[defaultProps.currentUser, ...MOCK_OBSERVED_USERS_LIST]}
        />,
      )
      expect(await findByRole('tab', {name: 'Grades'})).toBeInTheDocument()
    })

    it('is visible to observers who have selected a student', async () => {
      const {findByRole} = render(
        <K5Dashboard
          {...defaultProps}
          currentUserRoles={['observer']}
          observedUsersList={MOCK_OBSERVED_USERS_LIST}
        />,
      )
      expect(await findByRole('tab', {name: 'Grades'})).toBeInTheDocument()
    })

    it('is not visible to observers who have themself selected (and no student/teacher enrollments)', async () => {
      clearObservedId(defaultProps.currentUser.id)
      const {findByRole, queryByRole} = render(
        <K5Dashboard
          {...defaultProps}
          currentUserRoles={['observer']}
          observedUsersList={[defaultProps.currentUser, ...MOCK_OBSERVED_USERS_LIST]}
        />,
      )
      await findByRole('tab', {name: 'Homeroom'})
      expect(queryByRole('tab', {name: 'Grades'})).not.toBeInTheDocument()
    })
  })
})
