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
import UploadForm from '@canvas/files/react/components/UploadForm'
import {FileManagementContext} from '../../Contexts'
import {MainFolderWrapper} from '../../../../utils/fileFolderWrappers'
import {FAKE_COURSE_FOLDER} from '../../../../fixtures/fakeData'

jest.mock('@canvas/files/react/modules/UploadQueue', () => ({
  addChangeListener: jest.fn().mockImplementation(callback => callback()),
  removeChangeListener: jest.fn(),
  pendingUploads: jest.fn(),
}))

const defaultProps = {
  disabled: false,
  'data-testid': 'upload-button',
}

const renderComponent = (props = {}) =>
  render(
    <FileManagementContext.Provider
      value={{
        contextType: 'course',
        contextId: '1',
        folderId: '1',
        showingAllContexts: false,
        currentFolder: new MainFolderWrapper(FAKE_COURSE_FOLDER),
      }}
    >
      <UploadButton {...defaultProps} {...props} />
    </FileManagementContext.Provider>,
  )

describe('UploadButton', () => {
  it('renders', () => {
    renderComponent()
    expect(screen.getByTestId('upload-button')).toBeInTheDocument()
  })

  it('click button', async () => {
    UploadForm.prototype.addFiles = jest.fn()
    renderComponent()
    userEvent.click(screen.getByTestId('upload-button'))
    await waitFor(() => {
      expect(UploadForm.prototype.addFiles).toHaveBeenCalled()
    })
  })
})
