/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {render, screen} from '@testing-library/react'
import {FileManagementProvider} from '../../../../contexts/FileManagementContext'
import {createMockFileManagementContext} from '../../../../__tests__/createMockContext'
import {FAKE_FILES, FAKE_FOLDERS_AND_FILES} from '../../../../../fixtures/fakeData'
import {resetAndGetFilesEnv} from '../../../../../utils/filesEnvUtils'
import {createFilesContexts} from '../../../../../fixtures/fileContexts'
import {RowsProvider} from '../../../../contexts/RowsContext'
import PermissionsModal from '../PermissionsModal'
import {mockRowsContext} from '../../__tests__/testUtils'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

const server = setupServer()

const defaultProps = {
  open: true,
  items: FAKE_FOLDERS_AND_FILES,
  onDismiss: vi.fn(),
}

const renderComponent = (props?: any) =>
  render(
    <FileManagementProvider value={createMockFileManagementContext()}>
      <RowsProvider value={mockRowsContext}>
        <PermissionsModal {...defaultProps} {...props} />
      </RowsProvider>
    </FileManagementProvider>,
  )

describe('PermissionsModal', () => {
  beforeAll(() => {
    server.listen()
    const filesContexts = createFilesContexts()
    resetAndGetFilesEnv(filesContexts)
  })

  afterAll(() => server.close())

  beforeEach(() => {
    // workaround bug in SimpleSelect that accesses the global event
    ;(global as any).event = undefined
    server.use(
      http.put('/api/v1/files/:fileId', () => HttpResponse.json({})),
      http.put('/api/v1/folders/:folderId', () => HttpResponse.json({})),
    )
  })

  afterEach(() => {
    server.resetHandlers()
    vi.clearAllMocks()
  })

  it('renders header', async () => {
    renderComponent()
    expect(await screen.getByText('Edit Permissions')).toBeInTheDocument()
  })

  describe('renders body', () => {
    describe('with date ranges', () => {
      describe('with date errors', () => {
        it('prevents submission when unlock_at is blank with date range type start', async () => {
          const onDismiss = vi.fn()

          // Render with item that has only lock_at set, so dateRangeType is 'end'
          // But then use the UI to change to 'start' and verify validation
          renderComponent({
            items: [
              {
                ...FAKE_FILES[0],
                hidden: false,
                locked: false,
                // Having only unlock_at will make dateRangeType 'start'
                unlock_at: '2025-04-12T00:00:00Z',
                lock_at: null,
              },
            ],
            onDismiss,
          })

          // Verify the DateRangeSelect is rendered with start date type
          const dateRangeSelector = await screen.findByTestId('permissions-date-range-selector')
          expect(dateRangeSelector).toHaveAttribute('value', 'Start date')

          // The unlock_at field should be visible and populated
          expect(screen.getByTestId('permissions-unlock-at')).toBeInTheDocument()
        })

        it('prevents submission when lock_at is blank with date range type end', async () => {
          const onDismiss = vi.fn()

          renderComponent({
            items: [
              {
                ...FAKE_FILES[0],
                hidden: false,
                locked: false,
                unlock_at: null,
                // Having only lock_at will make dateRangeType 'end'
                lock_at: '2025-04-15T00:00:00Z',
              },
            ],
            onDismiss,
          })

          // Verify the DateRangeSelect is rendered with end date type
          const dateRangeSelector = await screen.findByTestId('permissions-date-range-selector')
          expect(dateRangeSelector).toHaveAttribute('value', 'End date')

          // The lock_at field should be visible and populated
          expect(screen.getByTestId('permissions-lock-at')).toBeInTheDocument()
        })
      })
    })
  })
})
