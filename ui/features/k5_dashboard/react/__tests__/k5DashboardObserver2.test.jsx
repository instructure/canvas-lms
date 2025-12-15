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
import {clearObservedId, OBSERVER_COOKIE_PREFIX} from '@canvas/observer-picker/ObserverGetObservee'
import {MOCK_OBSERVED_USERS_LIST} from '@canvas/observer-picker/react/__tests__/fixtures'
import {fetchShowK5Dashboard} from '@canvas/observer-picker/react/utils'
import {MockedQueryProvider} from '@canvas/test-utils/query'
import injectGlobalAlertContainers from '@canvas/util/react/testing/injectGlobalAlertContainers'
import {act, render as testingLibraryRender, waitFor} from '@testing-library/react'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import React from 'react'
import K5Dashboard from '../K5Dashboard'
import {defaultEnv, defaultK5DashboardProps as defaultProps} from './mocks'

vi.mock('@canvas/util/globalUtils', () => ({
  reloadWindow: vi.fn(),
}))

injectGlobalAlertContainers()

vi.mock('@canvas/observer-picker/react/utils', async () => {
  const actual = await vi.importActual('@canvas/observer-picker/react/utils')
  return {
    ...actual,
    fetchShowK5Dashboard: vi.fn(),
  }
})

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
  // Catch-all handlers to silently handle any remaining unmocked requests
  http.get('*', () => HttpResponse.json({})),
  http.post('*', () => HttpResponse.json({})),
  http.put('*', () => HttpResponse.json({})),
  http.delete('*', () => HttpResponse.json({})),
)

beforeAll(() => globalServer.listen({onUnhandledRequest: 'bypass'}))
afterEach(() => globalServer.resetHandlers())
afterAll(() => globalServer.close())

const render = children =>
  testingLibraryRender(<MockedQueryProvider>{children}</MockedQueryProvider>)

const currentUserId = defaultProps.currentUser.id
const observedUserCookieName = `${OBSERVER_COOKIE_PREFIX}${currentUserId}`

describe('K5Dashboard Parent Support - Dashboard Options', () => {
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
    vi.clearAllMocks()
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
})
