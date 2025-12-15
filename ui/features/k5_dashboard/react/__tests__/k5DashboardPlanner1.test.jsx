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
import {setupServer} from 'msw/node'
import {resetPlanner} from '@canvas/planner'
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

  // FOO-3831 - flaky test
  it.skip('displays the planner with a planned item', async () => {
    const {findByText} = render(
      <K5Dashboard {...defaultProps} defaultTab="tab-schedule" plannerEnabled={true} />,
    )
    expect(await findByText('Assignment 15')).toBeInTheDocument()
  })
})
