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

import React from 'react'
import {act, render as testingLibraryRender, waitFor} from '@testing-library/react'
import K5Dashboard from '../K5Dashboard'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import {resetPlanner} from '@canvas/planner'
import {MOCK_PLANNER_ITEM} from '@canvas/k5/react/__tests__/fixtures'
import {createPlannerMocks, defaultK5DashboardProps as defaultProps, defaultEnv} from './mocks'
import fetchMock from 'fetch-mock'
import {fetchShowK5Dashboard} from '@canvas/observer-picker/react/utils'
import {MockedQueryProvider} from '@canvas/test-utils/query'

vi.mock('@canvas/observer-picker/react/utils', async importOriginal => {
  const actual = await importOriginal()
  return {
    ...actual,
    fetchShowK5Dashboard: vi.fn(),
  }
})

const render = children =>
  testingLibraryRender(<MockedQueryProvider>{children}</MockedQueryProvider>)

const server = setupServer(...createPlannerMocks())

describe('K5Dashboard Schedule Section', () => {
  beforeAll(() => server.listen())
  afterEach(() => server.resetHandlers())
  afterAll(() => server.close())

  beforeEach(() => {
    fetchMock.get(/\/api\/v1\/announcements/, [])
    fetchMock.get(/\/api\/v1\/calendar_events/, [])
    fetchMock.put(/.*\/api\/v1\/users\/\d+\/colors/, {})
    fetchMock.spy()
    global.ENV = defaultEnv
    fetchShowK5Dashboard.mockImplementation(() =>
      Promise.resolve({show_k5_dashboard: true, use_classic_font: false}),
    )
  })

  afterEach(async () => {
    global.ENV = {}
    resetPlanner()
    fetchMock.reset()
    // Wait a bit for any pending transitions to complete
    await new Promise(resolve => setTimeout(resolve, 100))
  })

  // FOO-3831 - flaky when run in isolation
  it.skip('preloads surrounding weeks only once schedule tab is visible', async () => {
    let requestCount = 0
    server.use(
      http.get('/api/v1/planner/items', ({request}) => {
        const url = new URL(request.url)
        const perPage = url.searchParams.get('per_page')

        requestCount++

        if (perPage === '1') {
          // These are the preload requests for prev/next week
          return HttpResponse.json([])
        } else {
          // Return the main planner item for the current week
          return HttpResponse.json(MOCK_PLANNER_ITEM, {headers: {link: 'url; rel="current"'}})
        }
      }),
    )

    const {findByText, getByText} = render(
      <K5Dashboard
        {...defaultProps}
        currentUserRoles={['user', 'student']}
        plannerEnabled={true}
      />,
    )
    expect(await findByText('Assignment 15')).toBeInTheDocument()
    const countBefore = requestCount
    act(() => getByText('Schedule').click())
    await waitFor(() => expect(requestCount).toBe(countBefore + 2)) // 2 more requests for prev and next week preloads
  }, 15000)
})
