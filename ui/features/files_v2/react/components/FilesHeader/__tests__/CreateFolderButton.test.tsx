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

import React from 'react'
import CreateFolderButton from '../CreateFolderButton'
import {render, screen, waitFor} from '@testing-library/react'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import {queryClient} from '@canvas/query'
import userEvent from '@testing-library/user-event'
import {FileManagementProvider} from '../../Contexts'
import {createMockFileManagementContext} from '../../../__tests__/createMockContext'

const renderComponent = () => {
  return render(
    <FileManagementProvider value={createMockFileManagementContext()}>
      <MockedQueryClientProvider client={queryClient}>
        <CreateFolderButton buttonDisplay="block" />
      </MockedQueryClientProvider>
    </FileManagementProvider>,
  )
}

describe('CreateFolderButton', () => {
  it('can open and close the create folder modal', async () => {
    const user = userEvent.setup()
    renderComponent()

    const createFolderButton = await screen.findByRole('button', {name: /Folder/i})
    await user.click(createFolderButton)
    const modalElement = await screen.findByRole('heading', {name: /create folder/i})
    expect(modalElement).toBeInTheDocument()

    const closeButton = screen.getByRole('button', {name: /close/i})
    await user.click(closeButton)
    await waitFor(() => {
      expect(modalElement).not.toBeInTheDocument()
    })
  })
})
