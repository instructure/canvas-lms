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
import {cloneDeep} from 'es-toolkit/compat'
import {resetPlanner} from '@canvas/planner'
import {MOCK_CARDS, MOCK_CARDS_2, MOCK_PLANNER_ITEM} from '@canvas/k5/react/__tests__/fixtures'
import {
  createPlannerMocks,
  opportunities,
  defaultK5DashboardProps as defaultProps,
  defaultEnv,
} from './mocks'
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

const currentUserId = defaultProps.currentUser.id

const server = setupServer(
  ...createPlannerMocks(),
  http.get(/\/api\/v1\/announcements.*/, () => HttpResponse.json([])),
  http.get('/api/v1/calendar_events', () => HttpResponse.json([])),
  http.put(/\/api\/v1\/users\/\d+\/colors.*/, () => HttpResponse.json({})),
)

describe('K5Dashboard Schedule Section', () => {
  beforeAll(() => server.listen())
  afterEach(() => server.resetHandlers())
  afterAll(() => server.close())

  beforeEach(() => {
    global.ENV = defaultEnv
    fetchShowK5Dashboard.mockImplementation(() =>
      Promise.resolve({show_k5_dashboard: true, use_classic_font: false}),
    )
  })

  afterEach(async () => {
    global.ENV = {}
    resetPlanner()
    // Wait a bit for any pending transitions to complete
    await new Promise(resolve => setTimeout(resolve, 100))
  })

  // FOO-3831 - flaky test
  it.skip('reloads the planner with correct data when the selected observee is updated', async () => {
    const observerPlannerItem = cloneDeep(MOCK_PLANNER_ITEM)
    observerPlannerItem[0].plannable.title = 'Assignment for Observee'
    const observedUsersList = [
      {
        id: currentUserId,
        name: 'Self',
      },
      {
        id: '2',
        name: 'Student 2',
      },
    ]

    let lastRequestUrl = null
    server.use(
      http.get('/api/v1/dashboard/dashboard_cards', ({request}) => {
        const url = request.url
        if (url.includes('observed_user_id=1')) {
          return HttpResponse.json(MOCK_CARDS)
        } else if (url.includes('observed_user_id=2')) {
          return HttpResponse.json(MOCK_CARDS_2)
        }
      }),
      http.get('/api/v1/planner/items', ({request}) => {
        lastRequestUrl = request.url
        if (request.url.includes('observed_user_id=2')) {
          return HttpResponse.json(observerPlannerItem, {
            headers: {link: 'url; rel="current"'},
          })
        }
        return HttpResponse.json([])
      }),
      http.get('/api/v1/users/self/missing_submissions', ({request}) => {
        if (request.url.includes('observed_user_id=2')) {
          return HttpResponse.json([opportunities[0]], {
            headers: {link: 'url; rel="current"'},
          })
        }
        return HttpResponse.json(opportunities, {
          headers: {link: 'url; rel="current"'},
        })
      }),
    )

    const {findByText, findByTestId, getByTestId, getByText} = render(
      <K5Dashboard
        {...defaultProps}
        defaultTab="tab-schedule"
        plannerEnabled={true}
        canAddObservee={true}
        currentUserRoles={['user', 'observer']}
        observedUsersList={observedUsersList}
      />,
    )
    expect(await findByText('Assignment 15')).toBeInTheDocument()
    expect(await findByTestId('missing-item-info')).toHaveTextContent('Show 2 missing items')

    const observerSelect = getByTestId('observed-student-dropdown')
    act(() => observerSelect.click())
    act(() => getByText('Student 2').click())
    expect(await findByText('Assignment for Observee')).toBeInTheDocument()
    expect(await findByTestId('missing-item-info')).toHaveTextContent('Show 1 missing item')
    await waitFor(() => expect(lastRequestUrl).toContain('observed_user_id=2'))
  })
})
