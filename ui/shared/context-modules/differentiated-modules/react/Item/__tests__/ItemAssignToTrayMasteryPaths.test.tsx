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
import {
  renderComponent,
  server,
  setupBaseMocks,
  setupEnv,
  setupFlashHolder,
  http,
  HttpResponse,
} from './ItemAssignToTrayTestUtils'

describe('ItemAssignToTray - Mastery Paths & Errors', () => {
  const originalLocation = window.location

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

  it('renders mastery paths option for noop 1 overrides', async () => {
    server.use(
      http.get('/api/v1/courses/1/settings', () => {
        return HttpResponse.json({conditional_release: true})
      }),
      http.get('/api/v1/courses/1/assignments/23/date_details', () => {
        return HttpResponse.json({
          overrides: [
            {
              due_at: null,
              id: undefined,
              lock_at: null,
              noop_id: 1,
              unlock_at: null,
            },
          ],
        })
      }),
    )
    const {findAllByTestId} = renderComponent()
    const selectedOptions = await findAllByTestId('assignee_selector_selected_option')
    expect(selectedOptions).toHaveLength(1)
    waitFor(() => expect(selectedOptions[0]).toHaveTextContent('Mastery Paths'))
  })

  it('calls onDismiss when an error occurs while fetching data', async () => {
    server.use(
      http.get(/\/api\/v1\/courses\/.+\/sections/, () => {
        return new HttpResponse(null, {status: 500})
      }),
    )
    const onDismiss = vi.fn()
    renderComponent({onDismiss})
    await waitFor(() => expect(onDismiss).toHaveBeenCalledTimes(1))
  })
})
