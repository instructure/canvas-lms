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
import {
  FileManagementProvider,
  FileManagementContextProps,
} from '../../../contexts/FileManagementContext'
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

    // The current implementation has the Switch to Old Files button first, then All My Files, then Folder, then Upload
    const buttons = screen.getAllByRole('button')

    // Find the buttons by their text content rather than relying on order
    const allMyFilesButton = screen.getByText(/All My Files/i)
    const folderButton = screen.getByText(/Folder/i)
    const uploadButton = screen.getByText(/Upload/i)

    // Verify all buttons exist
    expect(allMyFilesButton).toBeInTheDocument()
    expect(folderButton).toBeInTheDocument()
    expect(uploadButton).toBeInTheDocument()

    // Verify the upload button is the last one
    expect(buttons[buttons.length - 1]).toHaveTextContent(/Upload/i)
  })

  it('renders upload button first when size is small', () => {
    // Mock ENV.FEATURES to ensure consistent test environment
    ENV.FEATURES = {files_a11y_rewrite_toggle: false}

    renderComponent({size: 'small'})

    // Find the buttons by their text content
    const uploadButton = screen.getByText(/Upload/i)
    const folderButton = screen.getByText(/Folder/i)
    const allMyFilesButton = screen.getByText(/All My Files/i)

    // Verify all buttons exist
    expect(uploadButton).toBeInTheDocument()
    expect(folderButton).toBeInTheDocument()
    expect(allMyFilesButton).toBeInTheDocument()

    // For small size, according to the component implementation, the upload button should appear before the folder button
    // We can test this by checking their positions in the DOM
    const uploadButtonElement = uploadButton.closest('button')
    const folderButtonElement = folderButton.closest('button')
    const allMyFilesButtonElement = allMyFilesButton.closest('button')

    // Get the DOM positions of the buttons
    const buttons = Array.from(document.querySelectorAll('button'))
    const uploadIndex = buttons.indexOf(uploadButtonElement as HTMLButtonElement)
    const folderIndex = buttons.indexOf(folderButtonElement as HTMLButtonElement)
    const allMyFilesIndex = buttons.indexOf(allMyFilesButtonElement as HTMLButtonElement)

    // Verify the upload button comes before the folder button in the DOM
    expect(uploadIndex).toBeLessThan(folderIndex)
    // Verify the folder button comes before the all my files button in the DOM
    expect(folderIndex).toBeLessThan(allMyFilesIndex)
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

  it('renders switch to Old Files button when toggle flag is on', () => {
    ENV.FEATURES.files_a11y_rewrite_toggle = true
    ENV.current_user_id = '12345'
    renderComponent()
    const switchButton = screen.getByText(/Switch to Old Files Page/i)
    expect(switchButton).toBeInTheDocument()
  })

  it('does not render switch to Old Files button when toggle flag is off', () => {
    ENV.FEATURES.files_a11y_rewrite_toggle = false
    ENV.current_user_id = '12345'
    renderComponent()
    const switchButton = screen.queryByText(/Switch to Old Files Page/i)
    expect(switchButton).not.toBeInTheDocument()
  })

  it('does not render switch to Old Files button when user is anonymous', () => {
    ENV.FEATURES.files_a11y_rewrite_toggle = true
    ENV.current_user_id = null
    renderComponent()
    const switchButton = screen.queryByText(/Switch to Old Files Page/i)
    expect(switchButton).not.toBeInTheDocument()
  })
})
