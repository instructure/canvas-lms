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
import {MOCK_CARDS} from '@canvas/k5/react/__tests__/fixtures'
import {resetPlanner} from '@canvas/planner'
import {destroyContainer} from '@canvas/alerts/react/FlashAlert'
import {MockedQueryProvider} from '@canvas/test-utils/query'
import fakeENV from '@canvas/test-utils/fakeENV'
import injectGlobalAlertContainers from '@canvas/util/react/testing/injectGlobalAlertContainers'
import {render as testingLibraryRender} from '@testing-library/react'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import React from 'react'
import K5Dashboard from '../K5Dashboard'
import {createPlannerMocks, defaultEnv, defaultK5DashboardProps as defaultProps} from './mocks'

vi.mock('@canvas/util/globalUtils', () => ({
  reloadWindow: vi.fn(),
}))

injectGlobalAlertContainers()

const render = children =>
  testingLibraryRender(<MockedQueryProvider>{children}</MockedQueryProvider>)

const server = setupServer()

beforeAll(() => server.listen())

beforeEach(() => {
  vi.restoreAllMocks()
  resetCardCache()
  resetPlanner()
  sessionStorage.clear()
  server.use(
    ...createPlannerMocks(),
    http.get(/\/api\/v1\/announcements.*/, () => HttpResponse.json([])),
    http.get(/\/api\/v1\/users\/self\/courses.*/, () => HttpResponse.json([])),
    http.get(/\/api\/v1\/external_tools\/visible_course_nav_tools.*/, () => HttpResponse.json([])),
    http.get('/api/v1/calendar_events', ({request}) => {
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

afterAll(() => server.close())

describe('K5Dashboard Missing Items', () => {
  it('shows missing items on dashboard cards', async () => {
    sessionStorage.setItem('dashcards_for_user_1', JSON.stringify(MOCK_CARDS))

    const {findByTestId, findByText} = render(
      <K5Dashboard {...defaultProps} plannerEnabled={true} assignmentsMissing={{1: 2}} />,
    )

    await findByText('Economics 101')

    const missingItemsLink = await findByTestId('number-missing', {}, {timeout: 5000})
    expect(missingItemsLink).toBeInTheDocument()
    expect(missingItemsLink).toHaveTextContent(
      'View 2 missing items for course Economics 1012 missing',
    )
  }, 10000)

  it('links to the schedule tab with missing items focus target', async () => {
    sessionStorage.setItem('dashcards_for_user_1', JSON.stringify(MOCK_CARDS))

    const {findByTestId, findByText} = render(
      <K5Dashboard {...defaultProps} plannerEnabled={true} assignmentsMissing={{1: 2}} />,
    )

    await findByText('Economics 101')

    const missingItemsLink = await findByTestId('number-missing', {}, {timeout: 5000})
    expect(missingItemsLink.getAttribute('href')).toMatch(
      '/courses/1?focusTarget=missing-items#schedule',
    )
  }, 10000)
})
