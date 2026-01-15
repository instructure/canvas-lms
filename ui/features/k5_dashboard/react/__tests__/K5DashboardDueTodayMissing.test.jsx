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
import {http, HttpResponse} from 'msw'
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
  server.use(
    ...createPlannerMocks(),
    // Use minimal mocks - empty arrays to avoid unnecessary async work
    http.get(/\/api\/v1\/announcements.*/, () => HttpResponse.json([])),
    http.get(/\/api\/v1\/users\/self\/courses.*/, () => HttpResponse.json([])),
    http.get(/\/api\/v1\/external_tools\/visible_course_nav_tools.*/, () => HttpResponse.json([])),
    http.get('/api/v1/calendar_events', () => HttpResponse.json([])),
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

describe.skip('K5Dashboard Due Today and Missing Items', () => {
  // FOO-3830: Tests for due today and missing items links on dashboard cards
  // These tests were moved from K5Dashboard1.test.jsx to reduce test file overhead
  // and improve CI reliability
  //
  // NOTE: This combined test was further split for better CI performance:
  // - K5DashboardDueToday.test.jsx (due today link test)
  // - K5DashboardMissingItems.test.jsx (missing items link test)
  // This file kept for reference but can be deleted once new tests are verified.
  it('placeholder', () => {})
})
