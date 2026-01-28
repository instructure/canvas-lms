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
import {render as testingLibraryRender} from '@testing-library/react'
import K5Dashboard from '../K5Dashboard'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import {resetPlanner} from '@canvas/planner'
import {createPlannerMocks, defaultK5DashboardProps as defaultProps, defaultEnv} from './mocks'
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

  it('renders an "jump to navigation" button at the bottom of the schedule tab', async () => {
    const {findByTestId} = render(
      <K5Dashboard {...defaultProps} defaultTab="tab-schedule" plannerEnabled={true} />,
    )
    const jumpToNavButton = await findByTestId('jump-to-weekly-nav-button')
    expect(jumpToNavButton).not.toBeVisible()
    jumpToNavButton.focus()
    expect(jumpToNavButton).toBeVisible()
    jumpToNavButton.click()
    expect(document.activeElement.id).toBe('weekly-header-active-button')
    expect(jumpToNavButton).not.toBeVisible()
  })
})
