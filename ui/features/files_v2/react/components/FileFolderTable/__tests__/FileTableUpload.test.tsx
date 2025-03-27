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
import {render, screen} from '@testing-library/react'
import FileTableUpload from '../FileTableUpload'
import {BBFolderWrapper, FileFolderWrapper} from '../../../../utils/fileFolderWrappers'
import {FAKE_COURSE_FOLDER, FAKE_FILES} from '../../../../fixtures/fakeData'

let defaultProps: any
describe('FileTableUpload', () => {
  beforeEach(() => {
    defaultProps = {
        currentFolder: new BBFolderWrapper(FAKE_COURSE_FOLDER),
        isDragging: false,
        handleDrop: () => {},
    }
  })

  it('renders the FileTableUpload component', () => {
    render(<FileTableUpload {...defaultProps} />)
    expect(screen.getByTestId('file-upload')).toBeInTheDocument()
  })

  it('renders a FileDrop when there are no files', () => {
    render(<FileTableUpload {...defaultProps} />)
    expect(screen.getByText('Drop files here to upload')).toBeInTheDocument()
    expect(screen.getByText('or choose files')).toBeInTheDocument()
    const uploader = screen.getByTestId('file-upload')
    expect(uploader).toBeInTheDocument()
    expect(uploader.classList.contains('FileDrag__full')).toBe(true)
  })

  it('renders fileDrop when isDragging is true', () => {
    defaultProps.isDragging = true
    render(<FileTableUpload {...defaultProps} />)
    const uploader = screen.getByTestId('file-upload')
    expect(uploader.classList.contains('FileDrag__dragging')).toBe(true)
    expect(uploader.classList.contains('FileDrag__full')).toBe(false)
  })

  it('does not render FileDrop when the currentFolder is not empty and isDragging is false', () => {
    const non_empty_folder = new BBFolderWrapper(FAKE_COURSE_FOLDER)
    const files = new FileFolderWrapper(FAKE_FILES[0])
    non_empty_folder.files.set([files])
    defaultProps.currentFolder = non_empty_folder

    render(<FileTableUpload {...defaultProps} />)
    const uploader = screen.getByTestId('file-upload')
    expect(uploader.classList.contains('FileDrag__dragging')).toBe(false)
    expect(uploader.classList.contains('FileDrag__full')).toBe(false)
  })
})
