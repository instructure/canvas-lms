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
import {MOCK_CARDS} from '@canvas/k5/react/__tests__/fixtures'
import {resetPlanner} from '@canvas/planner'
import {destroyContainer} from '@canvas/alerts/react/FlashAlert'
import {MockedQueryProvider} from '@canvas/test-utils/query'
import fakeENV from '@canvas/test-utils/fakeENV'
import {render as testingLibraryRender} from '@testing-library/react'
import fetchMock from 'fetch-mock'
import {setupServer} from 'msw/node'
import React from 'react'
import K5Dashboard from '../K5Dashboard'
import {createPlannerMocks, defaultEnv, defaultK5DashboardProps as defaultProps} from './mocks'

vi.mock('@canvas/util/globalUtils', () => ({
  reloadWindow: vi.fn(),
}))

const render = children =>
  testingLibraryRender(<MockedQueryProvider>{children}</MockedQueryProvider>)

const server = setupServer()

beforeAll(() => server.listen())

beforeEach(() => {
  server.use(...createPlannerMocks())
  // Use minimal mocks - empty arrays to avoid unnecessary async work
  fetchMock.get(/\/api\/v1\/announcements.*/, [])
  fetchMock.get(/\/api\/v1\/users\/self\/courses.*/, [])
  fetchMock.get(/\/api\/v1\/external_tools\/visible_course_nav_tools.*/, [])
  fetchMock.get(/\/api\/v1\/calendar_events\?type=assignment.*/, [])
  fetchMock.get(/\/api\/v1\/calendar_events\?type=event.*/, [])
  fetchMock.post(/\/api\/v1\/calendar_events\/save_selected_contexts.*/, {status: 'ok'})
  fetchMock.put(/\/api\/v1\/users\/\d+\/colors\.*/, [])
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

afterAll(() => server.close())

/**
 * Test for "missing items" link on dashboard cards.
 * Split from K5DashboardDueTodayMissing.test.jsx to improve CI performance.
 */
describe('K5Dashboard Missing Items Link', () => {
  it('shows missing items link pointing to the schedule tab of the course', async () => {
    // Pre-populate cards in session storage to avoid async loading delay
    sessionStorage.setItem('dashcards_for_user_1', JSON.stringify(MOCK_CARDS))

    const {findByTestId} = render(
      <K5Dashboard {...defaultProps} plannerEnabled={true} assignmentsMissing={{1: 2}} />,
    )

    const missingItemsLink = await findByTestId('number-missing')
    expect(missingItemsLink).toBeInTheDocument()
    expect(missingItemsLink).toHaveTextContent('View 2 missing items for course Economics 101')
    expect(missingItemsLink.getAttribute('href')).toMatch(
      '/courses/1?focusTarget=missing-items#schedule',
    )
  })
})
