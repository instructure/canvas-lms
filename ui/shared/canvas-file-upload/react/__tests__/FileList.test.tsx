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
import userEvent from '@testing-library/user-event'
import {vi} from 'vitest'
import FileList from '../FileList'
import type {ContextFile} from '../types'

const mockFiles: ContextFile[] = [
  {
    id: '1',
    display_name: 'test-file.pdf',
    url: 'http://example.com/file1',
    size: 1024 * 1024,
    content_type: 'application/pdf',
  },
  {
    id: '2',
    display_name: 'document.docx',
    url: 'http://example.com/file2',
    size: 2048 * 1024,
    content_type: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  },
]

const defaultProps = {
  files: [],
  uploadingFileNames: new Set<string>(),
  failedFileNames: new Set<string>(),
  onRemoveFile: vi.fn(),
  onClearFailedFile: vi.fn(),
}

describe('FileList', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  describe('uploaded files', () => {
    it('renders uploaded file names', () => {
      render(<FileList {...defaultProps} files={mockFiles} />)
      expect(screen.getByText('test-file.pdf')).toBeInTheDocument()
      expect(screen.getByText('document.docx')).toBeInTheDocument()
    })

    it('renders remove buttons for each uploaded file', () => {
      render(<FileList {...defaultProps} files={mockFiles} />)
      expect(screen.getByTestId('remove-file-1')).toBeInTheDocument()
      expect(screen.getByTestId('remove-file-2')).toBeInTheDocument()
    })

    it('calls onRemoveFile with the correct id when remove is clicked', async () => {
      const user = userEvent.setup()
      render(<FileList {...defaultProps} files={mockFiles} />)
      await user.click(screen.getByTestId('remove-file-1'))
      expect(defaultProps.onRemoveFile).toHaveBeenCalledWith('1')
    })

    it('renders download buttons for uploaded files', () => {
      render(<FileList {...defaultProps} files={mockFiles} />)
      expect(screen.getByTestId('download-file-1')).toBeInTheDocument()
      expect(screen.getByTestId('download-file-2')).toBeInTheDocument()
    })
  })

  describe('uploading files', () => {
    it('renders uploading file names with "uploading" text', () => {
      render(<FileList {...defaultProps} uploadingFileNames={new Set(['uploading-file.txt'])} />)
      expect(screen.getByText('uploading-file.txt uploading')).toBeInTheDocument()
    })

    it('renders a spinner for uploading files', () => {
      render(<FileList {...defaultProps} uploadingFileNames={new Set(['uploading-file.txt'])} />)
      expect(screen.getByTitle('Uploading')).toBeInTheDocument()
    })
  })

  describe('failed files', () => {
    it('renders failed file names with "failed" text', () => {
      render(<FileList {...defaultProps} failedFileNames={new Set(['broken.pdf'])} />)
      expect(screen.getByText('broken.pdf failed')).toBeInTheDocument()
    })

    it('renders a dismiss button for failed files', () => {
      render(<FileList {...defaultProps} failedFileNames={new Set(['broken.pdf'])} />)
      expect(screen.getByTestId('dismiss-failed-broken.pdf')).toBeInTheDocument()
    })

    it('calls onClearFailedFile when dismiss is clicked', async () => {
      const user = userEvent.setup()
      render(<FileList {...defaultProps} failedFileNames={new Set(['broken.pdf'])} />)
      await user.click(screen.getByTestId('dismiss-failed-broken.pdf'))
      expect(defaultProps.onClearFailedFile).toHaveBeenCalledWith('broken.pdf')
    })
  })

  describe('mixed states', () => {
    it('renders uploading, failed, and uploaded files together', () => {
      render(
        <FileList
          {...defaultProps}
          files={mockFiles}
          uploadingFileNames={new Set(['new-file.txt'])}
          failedFileNames={new Set(['broken.pdf'])}
        />,
      )
      expect(screen.getByText('new-file.txt uploading')).toBeInTheDocument()
      expect(screen.getByText('broken.pdf failed')).toBeInTheDocument()
      expect(screen.getByText('test-file.pdf')).toBeInTheDocument()
      expect(screen.getByText('document.docx')).toBeInTheDocument()
    })
  })

  describe('read-only mode (callbacks omitted)', () => {
    it('does not render remove buttons when onRemoveFile is not provided', () => {
      render(
        <FileList files={mockFiles} uploadingFileNames={new Set()} failedFileNames={new Set()} />,
      )
      expect(screen.queryByTestId('remove-file-1')).not.toBeInTheDocument()
      expect(screen.queryByTestId('remove-file-2')).not.toBeInTheDocument()
    })

    it('does not render dismiss buttons when onClearFailedFile is not provided', () => {
      render(
        <FileList
          files={[]}
          uploadingFileNames={new Set()}
          failedFileNames={new Set(['broken.pdf'])}
        />,
      )
      expect(screen.queryByTestId('dismiss-failed-broken.pdf')).not.toBeInTheDocument()
    })

    it('still renders the failed file name when onClearFailedFile is not provided', () => {
      render(
        <FileList
          files={[]}
          uploadingFileNames={new Set()}
          failedFileNames={new Set(['broken.pdf'])}
        />,
      )
      expect(screen.getByText('broken.pdf failed')).toBeInTheDocument()
    })
  })
})
