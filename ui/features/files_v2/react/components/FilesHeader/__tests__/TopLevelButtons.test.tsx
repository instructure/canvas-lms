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
import {render, screen} from '@testing-library/react'
import TopLevelButtons from '../TopLevelButtons'
import {FileManagementProvider, FileManagementContextProps} from '../../Contexts'
import {createMockFileManagementContext} from '../../../__tests__/createMockContext'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import {queryClient} from '@canvas/query'

const defaultProps = {
  isUserContext: false,
  size: 'small',
  onCreateFolderButtonClick: jest.fn(),
}

const renderComponent = (props?: any, context: Partial<FileManagementContextProps> = {}) => {
  const contextValue = createMockFileManagementContext(context)
  return render(
    <MockedQueryClientProvider client={queryClient}>
      <FileManagementProvider value={contextValue}>
        <TopLevelButtons {...defaultProps} {...props} />
      </FileManagementProvider>
    </MockedQueryClientProvider>,
  )
}

describe('TopLevelButtons', () => {
  it('renders "All My Files" button when isUserContext is false', () => {
    renderComponent()

    const allMyFilesButton = screen.getByText(/All My Files/i)
    expect(allMyFilesButton).toBeInTheDocument()
  })

  it('does not render "All My Files" button when isUserContext is true', () => {
    renderComponent({isUserContext: true})

    const allMyFilesButton = screen.queryByText(/All My Files/i)
    expect(allMyFilesButton).not.toBeInTheDocument()
  })

  it('renders upload button last when size is not small', () => {
    renderComponent({size: 'medium'})

    const buttons = screen.getAllByRole('button')
    expect(buttons[0]).toHaveTextContent(/All My Files/i)
    expect(buttons[1]).toHaveTextContent(/Folder/i)
    expect(buttons[2]).toHaveTextContent(/Upload/i)
  })

  it('renders upload button first when size is small', () => {
    renderComponent({size: 'small'})

    const buttons = screen.getAllByRole('button')
    expect(buttons[0]).toHaveTextContent(/Upload/i)
    expect(buttons[1]).toHaveTextContent(/Folder/i)
    expect(buttons[2]).toHaveTextContent(/All My Files/i)
  })

  it('renders external tools button when fileIndexMenuTools is provided', () => {
    const fileIndexMenuTools = [
      {id: '1', title: 'Tool 1', base_url: 'http://tool1.com', icon_url: 'http://someurl.com'},
    ]
    renderComponent({}, {fileIndexMenuTools})
    const externalToolsButton = screen.getByText(/external tools menu/i)
    expect(externalToolsButton).toBeInTheDocument()
  })

  it('does not render upload or create folder buttons when shouldHideUploadButtons is true', () => {
    const fileIndexMenuTools = [
      {id: '1', title: 'Tool 1', base_url: 'http://tool1.com', icon_url: 'http://someurl.com'},
    ]
    renderComponent({shouldHideUploadButtons: true}, {fileIndexMenuTools})

    const uploadButton = screen.queryByText(/Upload/i)
    const createFolderButton = screen.queryByText(/Folder/i)
    const externalToolsButton = screen.queryByText(/external tools menu/i)

    expect(uploadButton).not.toBeInTheDocument()
    expect(createFolderButton).not.toBeInTheDocument()
    expect(externalToolsButton).not.toBeInTheDocument()
  })

  it('does not render external tools button when no tools', () => {
    renderComponent()

    const externalToolsButton = screen.queryByText(/external tools menu/i)
    expect(externalToolsButton).not.toBeInTheDocument()
  })
})
