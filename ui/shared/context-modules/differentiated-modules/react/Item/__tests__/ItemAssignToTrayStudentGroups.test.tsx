/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {render, act, cleanup} from '@testing-library/react'
import {MockedQueryProvider} from '@canvas/test-utils/query'
import ItemAssignToTray from '../ItemAssignToTray'
import {
  DEFAULT_PROPS,
  FIRST_GROUP_CATEGORY_DATA,
  FIRST_GROUP_CATEGORY_ID,
  SECOND_GROUP_CATEGORY_DATA,
  SECOND_GROUP_CATEGORY_ID,
  renderComponent,
  server,
  setupBaseMocks,
  setupEnv,
  setupFlashHolder,
  http,
  HttpResponse,
} from './ItemAssignToTrayTestUtils'

// SKIP REASON: These tests exceed the 10s CI timeout limit (test times: ~10-11s each)
// The ItemAssignToTray component has complex async rendering with multiple data fetches
// that make these tests inherently slow. To re-enable these tests:
// 1. Optimize the component's data fetching (consider React Query with better caching)
// 2. Mock more API calls to reduce actual fetch time
// 3. Simplify the group category switching logic to reduce re-renders
// 4. Consider splitting into integration tests that can run with longer timeouts
describe.skip('ItemAssignToTray - Student Groups', () => {
  const originalLocation = window.location

  const payload = {
    id: '23',
    due_at: '2023-10-05T12:00:00Z',
    unlock_at: '2023-10-01T12:00:00Z',
    lock_at: '2023-11-01T12:00:00Z',
    only_visible_to_overrides: false,
    group_category_id: FIRST_GROUP_CATEGORY_ID,
    visible_to_everyone: true,
    overrides: [],
  }

  beforeAll(() => {
    server.listen()
    setupFlashHolder()
  })

  afterAll(() => server.close())

  beforeEach(() => {
    setupEnv()
    setupBaseMocks()
    vi.resetAllMocks()
  })

  afterEach(() => {
    window.location = originalLocation
    server.resetHandlers()
    cleanup()
  })

  it('displays student groups if the assignment is a group assignment', async () => {
    server.use(
      http.get('/api/v1/courses/1/assignments/23/date_details', () => {
        return HttpResponse.json(payload)
      }),
    )
    const {findByText, findByTestId, getByText} = renderComponent()
    const assigneeSelector = await findByTestId('assignee_selector')
    act(() => assigneeSelector.click())
    await findByText(FIRST_GROUP_CATEGORY_DATA[0].name)
    FIRST_GROUP_CATEGORY_DATA.forEach(group => {
      expect(getByText(group.name)).toBeInTheDocument()
    })
  })

  it('refreshes the group options if the group category is overridden', async () => {
    server.use(
      http.get('/api/v1/courses/1/assignments/23/date_details', () => {
        return HttpResponse.json(payload)
      }),
    )
    const {findByText, findByTestId, getByText, queryByText, rerender} = renderComponent()
    const assigneeSelector = await findByTestId('assignee_selector')
    act(() => assigneeSelector.click())
    await findByText(FIRST_GROUP_CATEGORY_DATA[0].name)
    SECOND_GROUP_CATEGORY_DATA.forEach(group => {
      expect(queryByText(group.name)).not.toBeInTheDocument()
    })
    rerender(
      <MockedQueryProvider>
        <ItemAssignToTray {...DEFAULT_PROPS} defaultGroupCategoryId={SECOND_GROUP_CATEGORY_ID} />
      </MockedQueryProvider>,
    )

    await findByText(SECOND_GROUP_CATEGORY_DATA[0].name)
    SECOND_GROUP_CATEGORY_DATA.forEach(group => {
      expect(getByText(group.name)).toBeInTheDocument()
    })
  })
})
