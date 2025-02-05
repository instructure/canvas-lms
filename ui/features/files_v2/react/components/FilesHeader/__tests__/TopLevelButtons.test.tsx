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
import {FileManagementContext} from '../../Contexts'

const defaultProps = {
  isUserContext: false,
  size: 'small',
  onCreateFolderButtonClick: jest.fn(),
}

const defaultContext = {
  contextType: 'course',
  contextId: '1',
  folderId: '1',
  showingAllContexts: false,
}

const renderComponent = (props?: any, context?: any) => {
  return render(
    <FileManagementContext.Provider value={{...defaultContext, ...context}}>
      <TopLevelButtons {...defaultProps} {...props} />
    </FileManagementContext.Provider>,
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

  it('does not render upload or create folder buttons when shouldHideUploadButtons is true', () => {
    renderComponent({shouldHideUploadButtons: true})

    const uploadButton = screen.queryByText(/Upload/i)
    const createFolderButton = screen.queryByText(/Folder/i)
    expect(uploadButton).not.toBeInTheDocument()
    expect(createFolderButton).not.toBeInTheDocument()
  })
})
