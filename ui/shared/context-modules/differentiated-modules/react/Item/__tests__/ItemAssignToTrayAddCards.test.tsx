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

import {act, cleanup} from '@testing-library/react'
import fetchMock from 'fetch-mock'
import {
  clearQueryCache,
  OVERRIDES_URL,
  renderComponent,
  setupBaseMocks,
  setupEnv,
  setupFlashHolder,
} from './ItemAssignToTrayTestUtils'

describe('ItemAssignToTray - Add Cards', () => {
  const originalLocation = window.location

  beforeAll(() => {
    setupFlashHolder()
  })

  beforeEach(() => {
    setupEnv()
    setupBaseMocks()
    vi.resetAllMocks()
  })

  afterEach(() => {
    window.location = originalLocation
    fetchMock.resetHistory()
    fetchMock.restore()
    clearQueryCache()
    cleanup()
  })

  it('adds a card when add button is clicked', async () => {
    fetchMock.get(
      OVERRIDES_URL,
      {
        id: '23',
        due_at: '2023-10-05T12:00:00Z',
        unlock_at: '2023-10-01T12:00:00Z',
        lock_at: '2023-11-01T12:00:00Z',
        only_visible_to_overrides: false,
        visible_to_everyone: true,
        overrides: [],
      },
      {
        overwriteRoutes: true,
      },
    )
    const {findAllByTestId, getAllByTestId} = renderComponent()
    const cards = await findAllByTestId('item-assign-to-card')
    expect(cards).toHaveLength(1)
    act(() => getAllByTestId('add-card')[0].click())
    expect(getAllByTestId('item-assign-to-card')).toHaveLength(2)
  })

  it('shows top add button if more than 3 cards exist', async () => {
    fetchMock.get(
      OVERRIDES_URL,
      {
        id: '23',
        due_at: '2023-10-05T12:00:00Z',
        unlock_at: '2023-10-01T12:00:00Z',
        lock_at: '2023-11-01T12:00:00Z',
        only_visible_to_overrides: false,
        visible_to_everyone: true,
        overrides: [
          {
            id: '2',
            assignment_id: '23',
            course_section_id: '4',
          },
          {
            id: '3',
            assignment_id: '23',
            course_section_id: '5',
          },
          {
            id: '4',
            assignment_id: '23',
            course_section_id: '6',
          },
        ],
      },
      {
        overwriteRoutes: true,
      },
    )
    const {findAllByTestId, getAllByTestId} = renderComponent()
    const cards = await findAllByTestId('item-assign-to-card')
    expect(cards).toHaveLength(4)
    expect(getAllByTestId('add-card')).toHaveLength(2)
    act(() => getAllByTestId('add-card')[0].click())
    expect(getAllByTestId('item-assign-to-card')).toHaveLength(5)
  })
})
