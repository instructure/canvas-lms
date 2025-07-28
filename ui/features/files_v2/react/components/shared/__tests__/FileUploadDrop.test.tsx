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
import {render, screen, fireEvent} from '@testing-library/react'
import {FileUploadDrop} from '../FileUploadDrop'
import {BBFolderWrapper} from '../../../../utils/fileFolderWrappers'
import {FAKE_COURSE_FOLDER} from '../../../../fixtures/fakeData'
import FileOptionsCollection from '@canvas/files/react/modules/FileOptionsCollection'
import {queueOptionsCollectionUploads} from '../../../../utils/uploadUtils'

const defaultProps = {
  contextId: '1',
  contextType: 'course',
  currentFolder: new BBFolderWrapper(FAKE_COURSE_FOLDER),
  onClose: jest.fn(),
  fileDropHeight: '100%',
  handleFileDropRef: jest.fn(),
}

const renderComponent = (props = {}) => render(<FileUploadDrop {...defaultProps} {...props} />)

describe('FileUploadDrop', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders drop area', () => {
    renderComponent()
    expect(screen.getByText('Drop files here to upload')).toBeInTheDocument()
    expect(screen.getByText('or choose files')).toBeInTheDocument()
  })

  it('calls onClose when file is dropped', () => {
    const files = [new File(['foo'], 'foo.txt', {type: 'text/plain'})]
    const onClose = jest.fn()

    renderComponent({onClose})
    const dropArea = screen.getByTestId('file-upload-drop')
    fireEvent.drop(dropArea, {
      dataTransfer: {
        files,
        items: [],
      },
    })
    expect(onClose).toHaveBeenCalled()
  })

  // --- queueOptionsCollectionUploads unit tests ---
  describe('queueOptionsCollectionUploads', () => {
    let mockOnClose: jest.Mock
    let mockQueueUploads: jest.SpyInstance
    let mockHasNewOptions: jest.SpyInstance

    const defaultFileOptions = {
      resolvedNames: [
        {
          file: new File(['foo'], 'foo.txt', {type: 'text/plain'}),
          dup: 'dup',
          name: 'foo.txt',
          expandZip: false,
        },
      ],
      nameCollisions: [],
      zipOptions: [],
    }

    beforeEach(() => {
      mockOnClose = jest.fn()
      mockQueueUploads = jest
        .spyOn(FileOptionsCollection, 'queueUploads')
        .mockImplementation(jest.fn())
      mockHasNewOptions = jest.spyOn(FileOptionsCollection, 'hasNewOptions')
    })

    afterEach(() => {
      jest.restoreAllMocks()
    })

    it('does nothing if fileOptions is null', () => {
      queueOptionsCollectionUploads('1', 'course', undefined, mockOnClose)
      expect(mockQueueUploads).not.toHaveBeenCalled()
      expect(mockOnClose).not.toHaveBeenCalled()
    })

    it('does nothing if hasNewOptions is false', () => {
      mockHasNewOptions.mockReturnValue(false)
      queueOptionsCollectionUploads('1', 'course', defaultFileOptions, mockOnClose)
      expect(mockQueueUploads).not.toHaveBeenCalled()
      expect(mockOnClose).not.toHaveBeenCalled()
    })

    it('queues uploads and calls onClose if resolvedNames present and no collisions/zips', () => {
      mockHasNewOptions.mockReturnValue(true)
      queueOptionsCollectionUploads('1', 'course', defaultFileOptions, mockOnClose)
      expect(mockQueueUploads).toHaveBeenCalledWith('1', 'course')
      expect(mockOnClose).toHaveBeenCalled()
    })

    it('calls onClose if no resolvedNames but hasNewOptions is true and no collisions/zips', () => {
      mockHasNewOptions.mockReturnValue(true)
      queueOptionsCollectionUploads(
        '1',
        'course',
        {...defaultFileOptions, resolvedNames: []},
        mockOnClose,
      )
      expect(mockQueueUploads).not.toHaveBeenCalled()
      expect(mockOnClose).toHaveBeenCalled()
    })

    it('does nothing if there are zipOptions', () => {
      mockHasNewOptions.mockReturnValue(true)
      queueOptionsCollectionUploads(
        '1',
        'course',
        {
          ...defaultFileOptions,
          zipOptions: [
            {
              name: 'foo.zip',
              file: new File(['foo'], 'foo.zip', {type: 'application/zip'}),
              cannotOverwrite: false,
              expandZip: false,
            },
          ],
        },
        mockOnClose,
      )
      expect(mockQueueUploads).not.toHaveBeenCalled()
      expect(mockOnClose).not.toHaveBeenCalled()
    })

    it('does nothing if there are nameCollisions', () => {
      mockHasNewOptions.mockReturnValue(true)
      queueOptionsCollectionUploads(
        '1',
        'course',
        {
          ...defaultFileOptions,
          nameCollisions: [
            {
              name: 'foo.txt',
              file: new File(['foo'], 'foo.txt', {type: 'text/plain'}),
              cannotOverwrite: true,
              expandZip: false,
            },
          ],
        },
        mockOnClose,
      )
      expect(mockQueueUploads).not.toHaveBeenCalled()
      expect(mockOnClose).not.toHaveBeenCalled()
    })
  })
})
