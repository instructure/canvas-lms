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
import fakeENV from '@canvas/test-utils/fakeENV'
import {mockRowsContext} from '../../__tests__/testUtils'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

const server = setupServer()

let capturedRequest: {path: string; body: any} | null = null

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
    capturedRequest = null
    fakeENV.setup()
    server.use(
      http.put('/api/v1/files/:fileId', async ({request}) => {
        capturedRequest = {
          path: new URL(request.url).pathname,
          body: await request.json(),
        }
        return HttpResponse.json({})
      }),
      http.put('/api/v1/folders/:folderId', async ({request}) => {
        capturedRequest = {
          path: new URL(request.url).pathname,
          body: await request.json(),
        }
        return HttpResponse.json({})
      }),
    )
  })

  afterEach(() => {
    server.resetHandlers()
    vi.clearAllMocks()
    fakeENV.teardown()
  })

  it('performs fetch request and shows alert', async () => {
    renderComponent({
      items: [Object.assign({}, FAKE_FILES[0], {usage_rights: {}})],
    })
    await userEvent.click(screen.getByTestId('permissions-save-button'))

    await waitFor(() => {
      expect(screen.getAllByText(/permissions have been successfully set./i)[0]).toBeInTheDocument()
      expect(capturedRequest).not.toBeNull()
      expect(capturedRequest?.path).toBe('/api/v1/files/178')
      expect(capturedRequest?.body).toEqual({
        hidden: false,
        lock_at: '',
        locked: false,
        unlock_at: '',
        visibility_level: 'inherit',
      })
    })
  })

  it('fails fetch request and shows alert', async () => {
    server.use(
      http.put('/api/v1/files/:fileId', async ({request}) => {
        capturedRequest = {
          path: new URL(request.url).pathname,
          body: await request.json(),
        }
        return new HttpResponse(null, {status: 500})
      }),
    )

    renderComponent({
      items: [Object.assign({}, FAKE_FILES[0], {usage_rights: {}})],
    })

    await userEvent.click(await screen.getByTestId('permissions-save-button'))

    await waitFor(() => {
      expect(
        screen.getAllByText(/an error occurred while setting permissions. please try again./i)[0],
      ).toBeInTheDocument()
      expect(capturedRequest).not.toBeNull()
      expect(capturedRequest?.path).toBe('/api/v1/files/178')
      expect(capturedRequest?.body).toEqual({
        hidden: false,
        lock_at: '',
        locked: false,
        unlock_at: '',
        visibility_level: 'inherit',
      })
    })
  })

})
