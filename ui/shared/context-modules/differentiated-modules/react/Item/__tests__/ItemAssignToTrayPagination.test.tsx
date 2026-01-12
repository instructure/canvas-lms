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

import {cleanup} from '@testing-library/react'
import {
  clearQueryCache,
  renderComponent,
  server,
  setupBaseMocks,
  setupEnv,
  setupFlashHolder,
  teardownEnv,
  http,
  HttpResponse,
} from './ItemAssignToTrayTestUtils'

describe('ItemAssignToTray - Pagination', () => {
  beforeAll(() => {
    setupFlashHolder()
    server.listen({onUnhandledRequest: 'bypass'})
  })

  beforeEach(() => {
    setupEnv()
    setupBaseMocks()
  })

  afterEach(() => {
    server.resetHandlers()
    teardownEnv()
    clearQueryCache()
    cleanup()
  })

  afterAll(() => {
    server.close()
  })

  it('fetches and combines multiple pages of overrides', async () => {
    // Use 2 pages instead of 3 to reduce sequential network round-trips
    // This still adequately tests pagination while being faster in CI
    const page1 = {
      id: '23',
      due_at: '2023-10-05T12:00:00Z',
      unlock_at: '2023-10-01T12:00:00Z',
      lock_at: '2023-11-01T12:00:00Z',
      only_visible_to_overrides: true,
      visible_to_everyone: false,
      overrides: [
        {
          id: '1',
          title: 'Section 1',
          course_section_id: '10',
          due_at: '2023-10-02T12:00:00Z',
          unlock_at: null,
          lock_at: null,
        },
        {
          id: '2',
          title: 'Section 2',
          course_section_id: '11',
          due_at: '2023-10-03T12:00:00Z',
          unlock_at: null,
          lock_at: null,
        },
      ],
    }

    const page2 = {
      id: '23',
      due_at: '2023-10-05T12:00:00Z',
      unlock_at: '2023-10-01T12:00:00Z',
      lock_at: '2023-11-01T12:00:00Z',
      only_visible_to_overrides: true,
      visible_to_everyone: false,
      overrides: [
        {
          id: '3',
          title: 'Section 3',
          course_section_id: '12',
          due_at: '2023-10-04T12:00:00Z',
          unlock_at: null,
          lock_at: null,
        },
      ],
    }

    // Override the default handler with pagination support
    server.use(
      http.get('/api/v1/courses/1/assignments/23/date_details', ({request}) => {
        const url = new URL(request.url)
        const page = url.searchParams.get('page')

        if (page === '2') {
          // Final page - no Link header
          return HttpResponse.json(page2)
        }
        // Default: page 1 with Link to page 2
        return new HttpResponse(JSON.stringify(page1), {
          headers: {
            'Content-Type': 'application/json',
            Link: '</api/v1/courses/1/assignments/23/date_details?page=2&per_page=100>; rel="next"',
          },
        })
      }),
    )

    const {findAllByTestId} = renderComponent()

    // Wait for all cards to render - this implicitly verifies:
    // 1. All pages were fetched
    // 2. Overrides were combined correctly
    // 3. Loading completed
    const cards = await findAllByTestId('item-assign-to-card')
    expect(cards).toHaveLength(3)
  })
})
