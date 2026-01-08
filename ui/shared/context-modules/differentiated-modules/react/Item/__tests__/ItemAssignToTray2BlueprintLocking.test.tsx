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

describe('ItemAssignToTray - Blueprint Locking Info', () => {
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

  it('renders blueprint locking info when there are locked dates', async () => {
    server.use(
      http.get('/api/v1/courses/1/assignments/31/date_details', () => {
        return HttpResponse.json({
          blueprint_date_locks: ['availability_dates'],
        })
      }),
    )
    const {getAllByText, getByTestId} = renderComponent({itemContentId: '31'})
    const loadingSpinner = getByTestId('cards-loading')
    await waitFor(() => {
      expect(loadingSpinner).not.toBeInTheDocument()
    })

    expect(
      getAllByText((_, e) => e?.textContent === 'Locked: Availability Dates')[0],
    ).toBeInTheDocument()
  })

  it('renders blueprint locking info when there are locked dates and default cards', async () => {
    server.use(
      http.get('/api/v1/courses/1/assignments/31/date_details', () => {
        return HttpResponse.json({
          blueprint_date_locks: ['availability_dates'],
        })
      }),
    )
    const {getAllByText, findAllByTestId} = renderComponent({
      itemContentId: '31',
      defaultCards: [
        // @ts-expect-error - partial card object for testing
        {
          defaultOptions: ['everyone'],
          key: 'key-card-0',
          isValid: true,
          highlightCard: false,
          hasAssignees: true,
          due_at: '2023-10-05T12:00:00Z',
          unlock_at: '2023-10-01T12:00:00Z',
          lock_at: '2023-11-01T12:00:00Z',
          selectedAssigneeIds: ['everyone'],
        },
      ],
    })
    await findAllByTestId('item-assign-to-card')
    expect(
      getAllByText((_, e) => e?.textContent === 'Locked: Availability Dates')[0],
    ).toBeInTheDocument()
  })

  it('does not render blueprint locking info when locked with unlocked due dates', async () => {
    server.use(
      http.get('/api/v1/courses/1/assignments/31/date_details', () => {
        return HttpResponse.json({
          blueprint_date_locks: [],
        })
      }),
    )
    const {getByTestId, queryByText} = renderComponent({itemContentId: '31'})

    const loadingSpinner = getByTestId('cards-loading')
    await waitFor(() => {
      expect(loadingSpinner).not.toBeInTheDocument()
    })

    await expect(queryByText('Locked:')).not.toBeInTheDocument()
  })

  it('disables add button if there are blueprint-locked dates', async () => {
    server.use(
      http.get('/api/v1/courses/1/assignments/31/date_details', () => {
        return HttpResponse.json({
          blueprint_date_locks: ['availability_dates'],
        })
      }),
    )
    const {getAllByTestId, findAllByText} = renderComponent({itemContentId: '31'})
    await findAllByText('Locked:')
    expect(getAllByTestId('add-card')[0]).toBeDisabled()
  })

  it('disables add button if there are blueprint-locked dates and default cards', async () => {
    server.use(
      http.get('/api/v1/courses/1/assignments/31/date_details', () => {
        return HttpResponse.json({
          blueprint_date_locks: ['availability_dates'],
        })
      }),
    )
    const {getAllByTestId, findAllByText} = renderComponent({
      itemContentId: '31',
      defaultCards: [
        // @ts-expect-error - partial card object for testing
        {
          defaultOptions: ['everyone'],
          key: 'key-card-0',
          isValid: true,
          highlightCard: false,
          hasAssignees: true,
          due_at: '2023-10-05T12:00:00Z',
          unlock_at: '2023-10-01T12:00:00Z',
          lock_at: '2023-11-01T12:00:00Z',
          selectedAssigneeIds: ['everyone'],
        },
      ],
    })
    await findAllByText('Locked:')

    expect(getAllByTestId('add-card')[0]).toBeDisabled()
  })
})
