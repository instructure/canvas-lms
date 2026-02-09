/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

// Mock modules
vi.mock('@canvas/axios', () => ({
  default: {
    get: vi.fn(),
  },
}))

vi.mock('link-header-parsing/parseLinkHeader', () => ({
  default: vi.fn(),
}))

// Import mocked functions after mocking
import axios from '@canvas/axios'
import parseLinkHeader from 'link-header-parsing/parseLinkHeader'
import {useCanvasFileBrowser} from '../useCanvasFileBrowser'

const mockAxiosGet = axios.get as ReturnType<typeof vi.fn>
const mockParseLinkHeader = parseLinkHeader as ReturnType<typeof vi.fn>

describe('useCanvasFileBrowser', () => {
  const mockRootFolder = {
    id: '123',
    name: 'course files',
    parent_folder_id: null,
    created_at: '2024-01-01',
  }

  const mockSubfolders = [
    {
      id: '124',
      name: 'assignments',
      parent_folder_id: '123',
      created_at: '2024-01-02',
    },
    {
      id: '125',
      name: 'resources',
      parent_folder_id: '123',
      created_at: '2024-01-03',
    },
  ]

  const mockFiles = [
    {
      id: 'file-1',
      display_name: 'syllabus.pdf',
      filename: 'syllabus.pdf',
      folder_id: '123',
      created_at: '2024-01-01',
      locked: false,
    },
    {
      id: 'file-2',
      display_name: 'schedule.pdf',
      filename: 'schedule.pdf',
      folder_id: '123',
      created_at: '2024-01-02',
      locked: false,
    },
  ]

  beforeEach(() => {
    vi.clearAllMocks()
    mockParseLinkHeader.mockReturnValue({})
    document.body.innerHTML = ''
  })

  describe('initialization', () => {
    it('should initialize with empty state', () => {
      mockAxiosGet.mockResolvedValue({data: mockRootFolder, headers: {}})

      const {result} = renderHook(() => useCanvasFileBrowser({courseID: '1'}))

      expect(result.current.loadedFolders).toEqual({})
      expect(result.current.loadedFiles).toEqual({})
      expect(result.current.error).toBeNull()
      expect(result.current.isLoading).toBe(true)
      expect(result.current.selectedFolderID).toBeNull()
    })
  })

  describe('loading root folder', () => {
    it('should load course root folder on mount', async () => {
      mockAxiosGet.mockResolvedValueOnce({
        data: mockRootFolder,
        headers: {},
      })
      mockAxiosGet.mockResolvedValueOnce({data: [], headers: {}})
      mockAxiosGet.mockResolvedValueOnce({data: [], headers: {}})

      const {result} = renderHook(() => useCanvasFileBrowser({courseID: '1'}))

      await waitFor(() => {
        expect(result.current.selectedFolderID).toBe('123')
        expect(result.current.loadedFolders['123']).toBeDefined()
      })

      expect(mockAxiosGet).toHaveBeenCalledWith('/api/v1/courses/1/folders/root', {
        headers: {Accept: 'application/json+canvas-string-ids'},
      })
    })

    it('should set isLoading true during root folder load', async () => {
      let resolveRootFolder: (value: any) => void
      const rootFolderPromise = new Promise(resolve => {
        resolveRootFolder = resolve
      })

      mockAxiosGet.mockReturnValueOnce(rootFolderPromise as any)

      const {result} = renderHook(() => useCanvasFileBrowser({courseID: '1'}))

      expect(result.current.isLoading).toBe(true)

      resolveRootFolder!({data: mockRootFolder, headers: {}})
      mockAxiosGet.mockResolvedValue({data: [], headers: {}})

      await waitFor(() => {
        expect(result.current.isLoading).toBe(false)
      })
    })

    it('should load root folder files and subfolders automatically', async () => {
      mockAxiosGet.mockResolvedValueOnce({
        data: mockRootFolder,
        headers: {},
      })
      mockAxiosGet.mockResolvedValueOnce({data: mockFiles, headers: {}})
      mockAxiosGet.mockResolvedValueOnce({data: mockSubfolders, headers: {}})

      const {result} = renderHook(() => useCanvasFileBrowser({courseID: '1'}))

      await waitFor(() => {
        expect(result.current.selectedFolderID).toBe('123')
      })

      await waitFor(() => {
        expect(mockAxiosGet).toHaveBeenCalledWith(
          '/api/v1/folders/123/files?include=user',
          undefined,
        )
        expect(mockAxiosGet).toHaveBeenCalledWith(
          '/api/v1/folders/123/folders?include=user',
          undefined,
        )
      })
    })
  })

  describe('loading folder contents', () => {
    it('should mark folder contents as loaded', async () => {
      mockAxiosGet.mockResolvedValueOnce({
        data: mockRootFolder,
        headers: {},
      })
      mockAxiosGet.mockResolvedValueOnce({data: mockFiles, headers: {}})
      mockAxiosGet.mockResolvedValueOnce({data: mockSubfolders, headers: {}})

      const {result} = renderHook(() => useCanvasFileBrowser({courseID: '1'}))

      await waitFor(() => {
        expect(result.current.selectedFolderID).toBe('123')
      })

      const initialCallCount = mockAxiosGet.mock.calls.length

      await waitFor(() => {
        expect(result.current.isLoading).toBe(false)
      })

      result.current.handleUpdateSelectedFolder('123')

      await waitFor(() => {
        expect(mockAxiosGet.mock.calls).toHaveLength(initialCallCount)
      })
    })

    it('should handle pagination with link headers', async () => {
      mockAxiosGet.mockResolvedValueOnce({
        data: mockRootFolder,
        headers: {},
      })

      const firstPageFiles = [mockFiles[0]]
      const secondPageFiles = [mockFiles[1]]

      // First page of files with link header
      mockAxiosGet.mockResolvedValueOnce({
        data: firstPageFiles,
        headers: {link: '<https://example.com/page2>; rel="next"'},
      })

      mockParseLinkHeader.mockReturnValueOnce({
        next: 'https://example.com/page2',
      })

      // Also need to mock the folders call (which happens in parallel)
      mockAxiosGet.mockResolvedValueOnce({data: [], headers: {}})
      mockParseLinkHeader.mockReturnValueOnce({})

      // Second page of files (pagination)
      mockAxiosGet.mockResolvedValueOnce({
        data: secondPageFiles,
        headers: {},
      })

      mockParseLinkHeader.mockReturnValueOnce({})

      const {result} = renderHook(() => useCanvasFileBrowser({courseID: '1'}))

      await waitFor(() => {
        expect(result.current.selectedFolderID).toBe('123')
      })

      await waitFor(() => {
        expect(Object.keys(result.current.loadedFiles)).toHaveLength(2)
      })
    })
  })

  describe('handleUpdateSelectedFolder', () => {
    it('should load files and folders when selecting new folder', async () => {
      mockAxiosGet.mockResolvedValueOnce({
        data: mockRootFolder,
        headers: {},
      })
      mockAxiosGet.mockResolvedValueOnce({data: [], headers: {}})
      mockAxiosGet.mockResolvedValueOnce({data: mockSubfolders, headers: {}})

      const {result} = renderHook(() => useCanvasFileBrowser({courseID: '1'}))

      await waitFor(() => {
        expect(result.current.selectedFolderID).toBe('123')
      })

      await waitFor(() => {
        expect(result.current.loadedFolders['124']).toBeDefined()
      })

      mockAxiosGet.mockResolvedValueOnce({data: [], headers: {}})
      mockAxiosGet.mockResolvedValueOnce({data: [], headers: {}})

      result.current.handleUpdateSelectedFolder('124')

      await waitFor(() => {
        expect(mockAxiosGet).toHaveBeenCalledWith(
          '/api/v1/folders/124/files?include=user',
          undefined,
        )
        expect(mockAxiosGet).toHaveBeenCalledWith(
          '/api/v1/folders/124/folders?include=user',
          undefined,
        )
      })
    })

    it('should not reload already-loaded folder contents', async () => {
      mockAxiosGet.mockResolvedValueOnce({
        data: mockRootFolder,
        headers: {},
      })
      mockAxiosGet.mockResolvedValueOnce({data: mockFiles, headers: {}})
      mockAxiosGet.mockResolvedValueOnce({data: mockSubfolders, headers: {}})

      const {result} = renderHook(() => useCanvasFileBrowser({courseID: '1'}))

      await waitFor(() => {
        expect(result.current.selectedFolderID).toBe('123')
      })

      await waitFor(() => {
        expect(result.current.isLoading).toBe(false)
      })

      const callCountBefore = mockAxiosGet.mock.calls.length

      result.current.handleUpdateSelectedFolder('123')

      await waitFor(() => {
        expect(mockAxiosGet.mock.calls).toHaveLength(callCountBefore)
      })
    })

    it('should update selectedFolderID', async () => {
      mockAxiosGet.mockResolvedValueOnce({
        data: mockRootFolder,
        headers: {},
      })
      mockAxiosGet.mockResolvedValueOnce({data: [], headers: {}})
      mockAxiosGet.mockResolvedValueOnce({data: mockSubfolders, headers: {}})

      const {result} = renderHook(() => useCanvasFileBrowser({courseID: '1'}))

      await waitFor(() => {
        expect(result.current.selectedFolderID).toBe('123')
      })

      await waitFor(() => {
        expect(result.current.loadedFolders['124']).toBeDefined()
      })

      mockAxiosGet.mockResolvedValueOnce({data: [], headers: {}})
      mockAxiosGet.mockResolvedValueOnce({data: [], headers: {}})

      result.current.handleUpdateSelectedFolder('124')

      await waitFor(() => {
        expect(result.current.selectedFolderID).toBe('124')
      })
    })
  })

  describe('error handling', () => {
    it('should set error state when root folder load fails', async () => {
      const error = new Error('Failed to load root folder')
      mockAxiosGet.mockRejectedValueOnce(error)

      const {result} = renderHook(() => useCanvasFileBrowser({courseID: '1'}))

      await waitFor(() => {
        expect(result.current.error).toEqual(error)
      })
    })

    it('should set error state when folder contents load fails', async () => {
      mockAxiosGet.mockResolvedValueOnce({
        data: mockRootFolder,
        headers: {},
      })

      const error = new Error('Failed to load folder contents')
      mockAxiosGet.mockRejectedValueOnce(error)

      const {result} = renderHook(() => useCanvasFileBrowser({courseID: '1'}))

      await waitFor(() => {
        expect(result.current.selectedFolderID).toBe('123')
      })

      await waitFor(() => {
        expect(result.current.error).toEqual(error)
      })
    })

    it('should decrement pendingAPIRequests on error', async () => {
      const error = new Error('API error')
      mockAxiosGet.mockRejectedValueOnce(error)

      const {result} = renderHook(() => useCanvasFileBrowser({courseID: '1'}))

      await waitFor(() => {
        expect(result.current.error).toEqual(error)
        expect(result.current.isLoading).toBe(false)
      })
    })
  })

  describe('derived state', () => {
    it('should calculate isLoading from pendingAPIRequests', async () => {
      let resolveFiles: (value: any) => void
      let resolveFolders: (value: any) => void

      const filesPromise = new Promise(resolve => {
        resolveFiles = resolve
      })
      const foldersPromise = new Promise(resolve => {
        resolveFolders = resolve
      })

      mockAxiosGet.mockResolvedValueOnce({
        data: mockRootFolder,
        headers: {},
      })
      mockAxiosGet.mockReturnValueOnce(filesPromise as any)
      mockAxiosGet.mockReturnValueOnce(foldersPromise as any)

      const {result} = renderHook(() => useCanvasFileBrowser({courseID: '1'}))

      await waitFor(() => {
        expect(result.current.selectedFolderID).toBe('123')
      })

      expect(result.current.isLoading).toBe(true)

      resolveFiles!({data: mockFiles, headers: {}})

      await waitFor(() => {
        expect(result.current.isLoading).toBe(true)
      })

      resolveFolders!({data: mockSubfolders, headers: {}})

      await waitFor(() => {
        expect(result.current.isLoading).toBe(false)
      })
    })
  })
})
