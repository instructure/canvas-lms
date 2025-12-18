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

import {cleanup, waitFor} from '@testing-library/react'
import fetchMock from 'fetch-mock'
import {
  OVERRIDES_URL,
  renderComponent,
  SECTIONS_URL,
  setupBaseMocks,
  setupEnv,
  setupFlashHolder,
} from './ItemAssignToTrayTestUtils'

describe('ItemAssignToTray - Mastery Paths & Errors', () => {
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
    cleanup()
  })

  it('renders mastery paths option for noop 1 overrides', async () => {
    fetchMock.get(
      '/api/v1/courses/1/settings',
      {conditional_release: true},
      {overwriteRoutes: true},
    )
    fetchMock.get(
      OVERRIDES_URL,
      {
        overrides: [
          {
            due_at: null,
            id: undefined,
            lock_at: null,
            noop_id: 1,
            unlock_at: null,
          },
        ],
      },
      {overwriteRoutes: true},
    )
    const {findAllByTestId} = renderComponent()
    const selectedOptions = await findAllByTestId('assignee_selector_selected_option')
    expect(selectedOptions).toHaveLength(1)
    waitFor(() => expect(selectedOptions[0]).toHaveTextContent('Mastery Paths'))
  })

  it('calls onDismiss when an error occurs while fetching data', async () => {
    fetchMock.getOnce(SECTIONS_URL, 500, {overwriteRoutes: true})
    const onDismiss = vi.fn()
    renderComponent({onDismiss})
    await waitFor(() => expect(onDismiss).toHaveBeenCalledTimes(1))
  })
})
