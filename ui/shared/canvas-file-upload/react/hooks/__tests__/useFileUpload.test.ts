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

import {waitFor} from '@testing-library/react'
import {renderHook} from '@testing-library/react-hooks/dom'
import {vi} from 'vitest'
import {useFileUpload} from '../useFileUpload'
import {ContextFile} from '../../types'

// Mock modules
vi.mock('@canvas/upload-file', () => ({
  uploadFile: vi.fn(),
}))

vi.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: vi.fn(),
}))

// Import mocked functions after mocking
import {uploadFile} from '@canvas/upload-file'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

describe('useFileUpload', () => {
  const mockUploadFile = uploadFile as ReturnType<typeof vi.fn>
  const mockShowFlashAlert = showFlashAlert as ReturnType<typeof vi.fn>

  const mockOnFilesChange = vi.fn()
  const courseId = '123'

  const createMockFile = (name: string, size: number): File => {
    const content = new Array(size).fill('a').join('')
    const file = new File([content], name, {type: 'text/plain'})
    Object.defineProperty(file, 'size', {value: size, writable: false})
    return file
  }

  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('should initialize with empty uploadingFileNames', () => {
    const {result} = renderHook(() =>
      useFileUpload({
        files: [],
        onFilesChange: mockOnFilesChange,
        courseId,
      }),
    )

    expect(result.current.uploadingFileNames.size).toBe(0)
    expect(result.current.isUploading).toBe(false)
  })

  it('should upload valid files successfully', async () => {
    const mockFile = createMockFile('test.txt', 1024)
    const mockUploadedFile: ContextFile = {
      id: '1',
      display_name: 'test.txt',
      url: 'http://example.com/test.txt',
      size: 1024,
      content_type: 'text/plain',
    }

    mockUploadFile.mockResolvedValueOnce(mockUploadedFile as any)

    const {result} = renderHook(() =>
      useFileUpload({
        files: [],
        onFilesChange: mockOnFilesChange,
        courseId,
      }),
    )

    await result.current.handleDrop([mockFile], [])

    await waitFor(() => {
      expect(mockOnFilesChange).toHaveBeenCalledWith([mockUploadedFile])
    })

    expect(mockShowFlashAlert).toHaveBeenCalledWith({
      message: expect.stringContaining('uploaded successfully'),
      type: 'success',
    })
  })

  it('should reject oversized files', async () => {
    const largeFile = createMockFile('large.txt', 10 * 1024 * 1024) // 10 MB
    const maxFileSizeMB = 5

    const {result} = renderHook(() =>
      useFileUpload({
        files: [],
        onFilesChange: mockOnFilesChange,
        courseId,
        maxFileSizeMB,
      }),
    )

    await result.current.handleDrop([largeFile], [])

    expect(mockShowFlashAlert).toHaveBeenCalledWith({
      message: expect.stringContaining('exceeds the 5MB size limit'),
      type: 'error',
    })

    expect(mockUploadFile).not.toHaveBeenCalled()
  })

  it('should skip duplicate files silently', async () => {
    const existingFiles: ContextFile[] = [
      {
        id: '1',
        display_name: 'existing.txt',
        url: 'http://example.com/existing.txt',
        size: 1024,
        content_type: 'text/plain',
      },
    ]

    const duplicateFile = createMockFile('existing.txt', 1024)

    const {result} = renderHook(() =>
      useFileUpload({
        files: existingFiles,
        onFilesChange: mockOnFilesChange,
        courseId,
      }),
    )

    await result.current.handleDrop([duplicateFile], [])

    expect(mockUploadFile).not.toHaveBeenCalled()
    expect(mockOnFilesChange).not.toHaveBeenCalled()
  })

  it('should handle upload errors', async () => {
    const mockFile = createMockFile('test.txt', 1024)
    const error = new Error('Upload failed')

    mockUploadFile.mockRejectedValueOnce(error)

    const {result} = renderHook(() =>
      useFileUpload({
        files: [],
        onFilesChange: mockOnFilesChange,
        courseId,
      }),
    )

    await result.current.handleDrop([mockFile], [])

    await waitFor(() => {
      expect(mockShowFlashAlert).toHaveBeenCalledWith({
        message: expect.stringContaining('Failed to upload'),
        type: 'error',
      })
    })

    expect(mockOnFilesChange).not.toHaveBeenCalled()
  })

  it('should track uploading state during upload', async () => {
    const mockFile = createMockFile('test.txt', 1024)
    let resolveUpload: (value: any) => void

    const uploadPromise = new Promise(resolve => {
      resolveUpload = resolve
    })

    mockUploadFile.mockReturnValueOnce(uploadPromise as any)

    const {result} = renderHook(() =>
      useFileUpload({
        files: [],
        onFilesChange: mockOnFilesChange,
        courseId,
      }),
    )

    result.current.handleDrop([mockFile], [])

    await waitFor(() => {
      expect(result.current.uploadingFileNames.has('test.txt')).toBe(true)
      expect(result.current.isUploading).toBe(true)
    })

    resolveUpload!({
      id: '1',
      display_name: 'test.txt',
      url: 'http://example.com/test.txt',
      size: 1024,
      content_type: 'text/plain',
    })

    await waitFor(() => {
      expect(result.current.uploadingFileNames.has('test.txt')).toBe(false)
      expect(result.current.isUploading).toBe(false)
    })
  })

  it('should upload multiple files concurrently', async () => {
    const file1 = createMockFile('file1.txt', 1024)
    const file2 = createMockFile('file2.txt', 2048)

    const mockUploadedFile1: ContextFile = {
      id: '1',
      display_name: 'file1.txt',
      url: 'http://example.com/file1.txt',
      size: 1024,
      content_type: 'text/plain',
    }

    const mockUploadedFile2: ContextFile = {
      id: '2',
      display_name: 'file2.txt',
      url: 'http://example.com/file2.txt',
      size: 2048,
      content_type: 'text/plain',
    }

    mockUploadFile
      .mockResolvedValueOnce(mockUploadedFile1 as any)
      .mockResolvedValueOnce(mockUploadedFile2 as any)

    const {result} = renderHook(() =>
      useFileUpload({
        files: [],
        onFilesChange: mockOnFilesChange,
        courseId,
      }),
    )

    await result.current.handleDrop([file1, file2], [])

    // Wait for both files to be uploaded
    await waitFor(() => {
      expect(mockUploadFile).toHaveBeenCalledTimes(2)
      expect(mockOnFilesChange.mock.calls.length).toBeGreaterThanOrEqual(2)
    })

    // The last call should have both files
    const lastCall = mockOnFilesChange.mock.calls[mockOnFilesChange.mock.calls.length - 1][0]
    expect(lastCall).toHaveLength(2)
    expect(lastCall).toEqual(expect.arrayContaining([mockUploadedFile1, mockUploadedFile2]))
  })

  it('should enforce max file limit', async () => {
    const file1 = createMockFile('file1.txt', 1024)
    const file2 = createMockFile('file2.txt', 1024)

    const {result} = renderHook(() =>
      useFileUpload({
        files: [],
        onFilesChange: mockOnFilesChange,
        courseId,
        maxFiles: 1,
      }),
    )

    await result.current.handleDrop([file1, file2], [])

    // Should show warning and only upload 1 file
    expect(mockShowFlashAlert).toHaveBeenCalledWith({
      message: expect.stringContaining('Only 1 of 2 files'),
      type: 'warning',
    })

    await waitFor(() => {
      expect(mockUploadFile).toHaveBeenCalledTimes(1)
    })
  })

  it('should show error when file limit is already reached', async () => {
    const existingFile: ContextFile = {
      id: '1',
      display_name: 'existing.txt',
      url: 'http://example.com/existing.txt',
      size: 1024,
      content_type: 'text/plain',
    }

    const newFile = createMockFile('new.txt', 1024)

    const {result} = renderHook(() =>
      useFileUpload({
        files: [existingFile],
        onFilesChange: mockOnFilesChange,
        courseId,
        maxFiles: 1,
      }),
    )

    await result.current.handleDrop([newFile], [])

    // Should show error and not upload
    expect(mockShowFlashAlert).toHaveBeenCalledWith({
      message: expect.stringContaining('reached the maximum of 1 files'),
      type: 'error',
    })

    expect(mockUploadFile).not.toHaveBeenCalled()
  })
})
