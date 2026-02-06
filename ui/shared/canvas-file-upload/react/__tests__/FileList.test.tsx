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
import {ContextFile} from '../types'

describe('FileList', () => {
  const mockFiles: ContextFile[] = [
    {
      id: '1',
      display_name: 'test-file.pdf',
      url: 'http://example.com/file1',
      size: 1024 * 1024, // 1 MB
      content_type: 'application/pdf',
    },
    {
      id: '2',
      display_name: 'document.docx',
      url: 'http://example.com/file2',
      size: 2048 * 1024, // 2 MB
      content_type: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    },
  ]

  const mockOnRemoveFile = vi.fn()

  beforeEach(() => {
    mockOnRemoveFile.mockClear()
  })

  it('should render uploaded files', () => {
    render(
      <FileList files={mockFiles} uploadingFileNames={new Set()} onRemoveFile={mockOnRemoveFile} />,
    )

    expect(screen.getByText('test-file.pdf')).toBeInTheDocument()
    expect(screen.getByText('document.docx')).toBeInTheDocument()
  })

  it('should display file sizes and content types', () => {
    render(
      <FileList files={mockFiles} uploadingFileNames={new Set()} onRemoveFile={mockOnRemoveFile} />,
    )

    expect(screen.getByText(/1 MB/)).toBeInTheDocument()
    expect(screen.getByText(/2 MB/)).toBeInTheDocument()
  })

  it('should render uploading files with spinner', () => {
    const uploadingFileNames = new Set(['uploading-file.txt'])
    render(
      <FileList
        files={[]}
        uploadingFileNames={uploadingFileNames}
        onRemoveFile={mockOnRemoveFile}
      />,
    )

    expect(screen.getByText('uploading-file.txt')).toBeInTheDocument()
    expect(screen.getByTitle('Uploading')).toBeInTheDocument()
  })

  it('should show remove buttons for uploaded files', () => {
    render(
      <FileList files={mockFiles} uploadingFileNames={new Set()} onRemoveFile={mockOnRemoveFile} />,
    )

    const removeButton1 = screen.getByTestId('remove-file-1')
    const removeButton2 = screen.getByTestId('remove-file-2')
    expect(removeButton1).toBeInTheDocument()
    expect(removeButton2).toBeInTheDocument()
  })

  it('should call onRemoveFile when remove button is clicked', async () => {
    const user = userEvent.setup()
    render(
      <FileList files={mockFiles} uploadingFileNames={new Set()} onRemoveFile={mockOnRemoveFile} />,
    )

    const removeButton = screen.getByTestId('remove-file-1')
    await user.click(removeButton)

    expect(mockOnRemoveFile).toHaveBeenCalledWith('1')
  })

  it('should render both uploading and uploaded files', () => {
    const uploadingFileNames = new Set(['new-file.txt'])
    render(
      <FileList
        files={mockFiles}
        uploadingFileNames={uploadingFileNames}
        onRemoveFile={mockOnRemoveFile}
      />,
    )

    expect(screen.getByText('new-file.txt')).toBeInTheDocument()
    expect(screen.getByText('test-file.pdf')).toBeInTheDocument()
    expect(screen.getByText('document.docx')).toBeInTheDocument()
  })

  it('should render header with "File Name" label', () => {
    render(
      <FileList files={mockFiles} uploadingFileNames={new Set()} onRemoveFile={mockOnRemoveFile} />,
    )

    expect(screen.getByText('File Name')).toBeInTheDocument()
  })
})
