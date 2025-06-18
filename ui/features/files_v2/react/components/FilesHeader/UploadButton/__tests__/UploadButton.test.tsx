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
import {render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import UploadButton from '../UploadButton'
import {FileManagementProvider} from '../../../../contexts/FileManagementContext'
import {createMockFileManagementContext} from '../../../../__tests__/createMockContext'
import {BBFolderWrapper} from '../../../../../utils/fileFolderWrappers'
import {FAKE_COURSE_FOLDER} from '../../../../../fixtures/fakeData'

const defaultProps = {
  disabled: false,
  'data-testid': 'upload-button',
}

const renderComponent = (props = {}) =>
  render(
    <FileManagementProvider
      value={createMockFileManagementContext({
        currentFolder: new BBFolderWrapper(FAKE_COURSE_FOLDER),
      })}
    >
      <UploadButton {...defaultProps} {...props} />
    </FileManagementProvider>,
  )

describe('UploadButton', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    jest.resetAllMocks()
  })

  it('renders', () => {
    renderComponent()
    expect(screen.getByTestId('upload-button')).toBeInTheDocument()
  })

  it('renders file drag and drop modal when clicked', async () => {
    renderComponent()
    await userEvent.click(screen.getByTestId('upload-button'))
    expect(screen.getByTestId('file-upload-drop')).toBeInTheDocument()
  })

  it('closes drop modal when close button is clicked', async () => {
    renderComponent()
    await userEvent.click(screen.getByTestId('upload-button'))

    const dropModal = screen.getByTestId('file-upload-drop')
    expect(dropModal).toBeInTheDocument()

    const closeButton = screen
      .getByTestId('upload-close-button')
      .querySelector('button') as HTMLButtonElement
    await userEvent.click(closeButton)

    await waitFor(() => {
      expect(dropModal).not.toBeInTheDocument()
    })
  })

  it('closes drop modal when cancel button is clicked', async () => {
    renderComponent()
    await userEvent.click(screen.getByTestId('upload-button'))

    const dropModal = screen.getByTestId('file-upload-drop')
    expect(dropModal).toBeInTheDocument()

    const cancelButton = screen.getByTestId('upload-cancel-button')
    await userEvent.click(cancelButton)

    await waitFor(() => {
      expect(dropModal).not.toBeInTheDocument()
    })
  })
})
