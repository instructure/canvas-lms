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

import {render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
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

describe('PermissionsModal - Usage Rights', () => {
  beforeAll(() => {
    server.listen()
    const filesContexts = createFilesContexts({usageRightsRequired: true})
    resetAndGetFilesEnv(filesContexts)
  })

  afterAll(() => server.close())

  beforeEach(() => {
    server.use(
      http.put('/api/v1/files/:fileId', () => HttpResponse.json({})),
      http.put('/api/v1/folders/:folderId', () => HttpResponse.json({})),
    )
  })

  afterEach(() => {
    server.resetHandlers()
    vi.clearAllMocks()
    vi.resetAllMocks()
  })

  it.skip('shows alert when trying to save without usage rights', async () => {
    // Render with items that have usage_rights: null (FAKE_FILES[0] has usage_rights: null)
    renderComponent({items: [FAKE_FILES[0]]})

    // Wait for modal to be fully rendered
    const saveButton = await screen.findByTestId('permissions-save-button')
    await screen.findByTestId('permissions-availability-selector')

    await userEvent.click(saveButton)

    // The error should be set synchronously, but use waitFor for React state updates
    await waitFor(() => {
      const alert = screen.getByTestId('permissions-usage-rights-alert')
      expect(alert).toBeInTheDocument()
      expect(alert).toHaveTextContent(
        'Selected items must have usage rights assigned before they can be published.',
      )
    })
  })
})
