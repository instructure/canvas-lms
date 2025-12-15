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

describe('K5Dashboard Parent Support - Switching and Grades', () => {
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

    // TODO: This test is skipped due to slow rendering in Vitest.
    // Consider splitting to separate test file with its own setup/teardown.
    it.skip(
      'does not reload the page if a k5 student with the same font selection is selected in the picker',
      async () => {
        // Explicitly set the same K5 settings for Student 2
        fetchShowK5Dashboard.mockImplementationOnce(() =>
          Promise.resolve({show_k5_dashboard: true, use_classic_font: false}),
        )
        await switchToStudent2()
        expect(reloadWindow).not.toHaveBeenCalled()
      },
    )

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
