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

import React, {forwardRef, useEffect, useImperativeHandle} from 'react'
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import UploadButton from '../UploadButton'
import {FileManagementContext} from '../../../Contexts'
import {BBFolderWrapper} from '../../../../../utils/fileFolderWrappers'
import {FAKE_COURSE_FOLDER} from '../../../../../fixtures/fakeData'

const createFileOptionsMock = jest.fn()
const addFilesMock = jest.fn()

// Mocked UploadForm to not process actual uploads
jest.mock('@canvas/files/react/components/UploadForm', () => {
  const MockUploadForm = forwardRef((props: any, ref) => {
    useImperativeHandle(ref, () => ({
      addFiles: addFilesMock,
    }))

    useEffect(() => {
      props.onFileOptionsChange?.(createFileOptionsMock())
      // eslint-disable-next-line react-compiler/react-compiler
      // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [])

    return <div />
  })

  return MockUploadForm
})

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
        currentFolder: new BBFolderWrapper(FAKE_COURSE_FOLDER),
      }}
    >
      <UploadButton {...defaultProps} {...props} />
    </FileManagementContext.Provider>,
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

  it('calls addFiles', async () => {
    renderComponent()
    await userEvent.click(screen.getByTestId('upload-button'))
    expect(addFilesMock).toHaveBeenCalled()
  })

  it('renders rename modal', async () => {
    const textFile = new File(['foo'], 'foo.txt', {type: 'text/plain'})
    createFileOptionsMock.mockReturnValue({
      zipOptions: [],
      nameCollisions: [
        {
          name: 'foo.txt',
          file: textFile,
          cannotOverwrite: false,
          expandZip: false,
        },
      ],
    })
    renderComponent()
    expect(
      await screen.getByText(
        'An file named "foo.txt" already exists in this location. Do you want to replace the existing file?',
      ),
    ).toBeInTheDocument()
  })

  it('renders zip modal', async () => {
    const zipFile = new File(['foo'], 'foo.zip', {type: 'application/zip'})
    createFileOptionsMock.mockReturnValue({
      zipOptions: [
        {
          name: 'foo.zip',
          file: zipFile,
          cannotOverwrite: false,
          expandZip: false,
        },
      ],
      nameCollisions: [],
    })
    renderComponent()
    expect(
      await screen.getByText(
        'Would you like to expand the contents of "foo.zip" into the current folder, or upload the zip file as is?',
      ),
    ).toBeInTheDocument()
  })
})
