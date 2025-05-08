/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import FilesHeader from '../FilesHeader'
import {render, screen} from '@testing-library/react'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import {queryClient} from '@canvas/query'
import {
  FileManagementProvider,
  FileManagementContextProps,
} from '../../../contexts/FileManagementContext'
import {createMockFileManagementContext} from '../../../__tests__/createMockContext'

const defaultProps = {
  isUserContext: false,
  size: 'small' as 'small' | 'medium' | 'large',
}

const renderComponent = (props = {}, context: Partial<FileManagementContextProps> = {}) => {
  return render(
    <MockedQueryClientProvider client={queryClient}>
      <FileManagementProvider value={createMockFileManagementContext(context)}>
        <FilesHeader {...defaultProps} {...props} />
      </FileManagementProvider>
    </MockedQueryClientProvider>,
  )
}

describe('FilesHeader', () => {
  it('renders "Files" when not in a user context', async () => {
    renderComponent()

    const headingElement = await screen.findByText('Files', {exact: true})
    expect(headingElement).toBeInTheDocument()
  })

  it('renders "All My Files" when in a user context', async () => {
    renderComponent({isUserContext: true})

    const headingElement = await screen.findByText(/All My Files/i)
    expect(headingElement).toBeInTheDocument()
  })

  it('renders toplevel buttons', async () => {
    const fileIndexMenuTools = [
      {id: '1', title: 'Tool 1', base_url: 'http://tool1.com', icon_url: 'http://someurl.com'},
    ]
    renderComponent({}, {fileIndexMenuTools})

    const allMyFilesButton = screen.getByText(/All My Files/i)
    const uploadButton = screen.getByText(/Upload/i)
    const createFolderButton = screen.getByText(/Folder/i)
    const externalToolsButton = screen.getByText(/external tools menu/i)

    expect(allMyFilesButton).toBeInTheDocument()
    expect(uploadButton).toBeInTheDocument()
    expect(createFolderButton).toBeInTheDocument()
    expect(externalToolsButton).toBeInTheDocument()
  })
})
