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
import {cloneDeep} from 'lodash'
import {resetPlanner} from '@canvas/planner'
import {MOCK_CARDS, MOCK_CARDS_2, MOCK_PLANNER_ITEM} from '@canvas/k5/react/__tests__/fixtures'
import {
  createPlannerMocks,
  opportunities,
  defaultK5DashboardProps as defaultProps,
  defaultEnv,
} from './mocks'
import fetchMock from 'fetch-mock'
import {fetchShowK5Dashboard} from '@canvas/observer-picker/react/utils'
import {MockedQueryProvider} from '@canvas/test-utils/query'

jest.mock('@canvas/observer-picker/react/utils', () => ({
  ...jest.requireActual('@canvas/observer-picker/react/utils'),
  fetchShowK5Dashboard: jest.fn(),
}))

const render = children =>
  testingLibraryRender(<MockedQueryProvider>{children}</MockedQueryProvider>)

const currentUserId = defaultProps.currentUser.id

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

  afterEach(() => {
    global.ENV = {}
    resetPlanner()
    fetchMock.reset()
  })

  // FOO-3831
  it.skip('displays the planner with a planned item', async () => {
    const {findByText} = render(
      <K5Dashboard {...defaultProps} defaultTab="tab-schedule" plannerEnabled={true} />,
    )
    expect(await findByText('Assignment 15')).toBeInTheDocument()
  })

  // FOO-3831
  it.skip('displays a list of missing assignments if there are any (flaky)', async () => {
    const {findByTestId, findByText} = render(
      <K5Dashboard {...defaultProps} defaultTab="tab-schedule" plannerEnabled={true} />,
    )
    const missingAssignments = await findByTestId('missing-item-info')
    expect(missingAssignments).toHaveTextContent('Show 2 missing items')
    expect(missingAssignments).toBeInTheDocument()

    act(() => missingAssignments.click())
    expect(missingAssignments).toHaveTextContent('Hide 2 missing items')
    expect(await findByText('Assignment 1')).toBeInTheDocument()
    expect(await findByText('Assignment 2')).toBeInTheDocument()
  })

  // FOO-3831
  it.skip('renders the weekly planner header (flaky)', async () => {
    const {findByTestId} = render(
      <K5Dashboard {...defaultProps} defaultTab="tab-schedule" plannerEnabled={true} />,
    )
    const planner = await findByTestId('PlannerApp', {timeout: 4000}) // give it some more time
    expect(planner).toBeInTheDocument()
    const header = await findByTestId('WeeklyPlannerHeader')
    expect(header).toBeInTheDocument()
  })

  it('renders an "jump to navigation" button at the bottom of the schedule tab', async () => {
    const {findByTestId} = render(
      <K5Dashboard {...defaultProps} defaultTab="tab-schedule" plannerEnabled={true} />,
    )
    const jumpToNavButton = await findByTestId('jump-to-weekly-nav-button')
    expect(jumpToNavButton).not.toBeVisible()
    act(() => jumpToNavButton.focus())
    expect(jumpToNavButton).toBeVisible()
    act(() => jumpToNavButton.click())
    expect(document.activeElement.id).toBe('weekly-header-active-button')
    expect(jumpToNavButton).not.toBeVisible()
  })

  it('allows navigating to next/previous weeks if there are plannable items in the future/past', async () => {
    const {findByTestId, getByTestId} = render(
      <K5Dashboard {...defaultProps} defaultTab="tab-schedule" plannerEnabled={true} />,
    )
    const todayButton = await findByTestId('jump-to-today-button')
    expect(todayButton).toBeEnabled()
    const previousButton = getByTestId('view-previous-week-button')
    await waitFor(() => expect(previousButton).toBeEnabled())
    const nextButton = getByTestId('view-next-week-button')
    expect(nextButton).toBeEnabled()
  })

  it('displays a teacher preview if the user has no student enrollments', async () => {
    const {findByTestId, getByText} = render(
      <K5Dashboard {...defaultProps} defaultTab="tab-schedule" plannerEnabled={false} />,
    )
    expect(await findByTestId('kinder-panda')).toBeInTheDocument()
    expect(getByText('Schedule Preview')).toBeInTheDocument()
    expect(
      getByText('Below is an example of how students will see their schedule'),
    ).toBeInTheDocument()
    expect(getByText('Math')).toBeInTheDocument()
    expect(getByText('A wonderful assignment')).toBeInTheDocument()
    expect(getByText('Social Studies')).toBeInTheDocument()
    expect(getByText('Exciting discussion')).toBeInTheDocument()
  })

  it('preloads surrounding weeks only once schedule tab is visible', async () => {
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
  })

  // FOO-3831
  it.skip('reloads the planner with correct data when the selected observee is updated (flaky)', async () => {
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
