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
import {renderHook} from '@testing-library/react-hooks'
import {act, waitFor} from '@testing-library/react'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {MemoryRouter} from 'react-router-dom'
import {usePreviewHandler} from '../usePreviewHandler'
import {FAKE_FILES} from '../../../fixtures/fakeData'

const mockNavigate = vi.fn()
vi.mock('react-router-dom', async () => ({
  ...(await vi.importActual('react-router-dom')),
  useNavigate: () => mockNavigate,
}))

vi.mock('../useGetFile')

const createWrapper = (initialRoute = '/') => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
        staleTime: 0,
      },
    },
  })

  return ({children}: {children: React.ReactNode}) => (
    <MemoryRouter initialEntries={[initialRoute]}>
      <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
    </MemoryRouter>
  )
}

describe('usePreviewHandler', async () => {
  const mockCollection = FAKE_FILES.slice(0, 3)
  const {useGetFile: mockUseGetFile} = await import('../useGetFile')
  const mockedUseGetFile = vi.mocked(mockUseGetFile)

  beforeEach(() => {
    vi.clearAllMocks()
    mockedUseGetFile.mockReturnValue({
      data: undefined,
      isLoading: false,
      error: null,
      isError: false,
      isSuccess: false,
      status: 'idle',
      fetchStatus: 'idle',
      refetch: vi.fn(),
    } as any)
  })

  describe('when no preview parameter in URL', () => {
    it('returns closed modal state', () => {
      const {result} = renderHook(() => usePreviewHandler({collection: mockCollection}), {
        wrapper: createWrapper(),
      })

      const resultPreviewState = result.current.previewState
      expect(resultPreviewState.isModalOpen).toBe(false)
      expect(resultPreviewState.previewFile).toBe(null)
      expect(resultPreviewState.showNavigationButtons).toBe(false)
      expect(resultPreviewState.error).toBe(null)
    })
  })

  describe('when preview parameter matches file in collection', () => {
    it('opens modal with navigation buttons', () => {
      const fileId = mockCollection[0].id.toString()
      const {result} = renderHook(() => usePreviewHandler({collection: mockCollection}), {
        wrapper: createWrapper(`/?preview=${fileId}`),
      })

      const resultPreviewState = result.current.previewState
      expect(resultPreviewState.isModalOpen).toBe(true)
      expect(resultPreviewState.previewFile).toEqual(mockCollection[0])
      expect(resultPreviewState.isFileInCollection).toBe(true)
      expect(resultPreviewState.showNavigationButtons).toBe(true)
      expect(resultPreviewState.error).toBe(null)
    })

    it('hides navigation buttons when collection has only one file', () => {
      const singleFileCollection = [mockCollection[0]]
      const fileId = singleFileCollection[0].id.toString()

      const {result} = renderHook(() => usePreviewHandler({collection: singleFileCollection}), {
        wrapper: createWrapper(`/?preview=${fileId}`),
      })

      const resultPreviewState = result.current.previewState
      expect(resultPreviewState.showNavigationButtons).toBe(false)
    })
  })

  describe('when preview parameter does not match file in collection', () => {
    it('attempts to fetch file and shows it without navigation', async () => {
      const externalFile = {
        ...mockCollection[0],
        id: 999,
        display_name: 'external-file.pdf',
        context_asset_string: 'course_123',
      }

      mockedUseGetFile.mockReturnValue({
        data: externalFile,
        isLoading: false,
        error: null,
        isError: false,
        isSuccess: true,
        status: 'success',
        fetchStatus: 'idle',
        refetch: vi.fn(),
      } as any)

      const {result} = renderHook(
        () =>
          usePreviewHandler({
            collection: mockCollection,
            contextType: 'course',
            contextId: '123',
          }),
        {
          wrapper: createWrapper('/?preview=999'),
        },
      )

      await waitFor(() => {
        const resultPreviewState = result.current.previewState
        expect(resultPreviewState.isModalOpen).toBe(true)
        expect(resultPreviewState.previewFile).toEqual(externalFile)
        expect(resultPreviewState.isFileInCollection).toBe(false)
        expect(resultPreviewState.showNavigationButtons).toBe(false)
        expect(resultPreviewState.error).toBe(null)
      })

      expect(mockedUseGetFile).toHaveBeenCalledWith({
        fileId: '999',
        contextType: 'course',
        contextId: '123',
      })
    })

    it('shows error when file fetch fails', async () => {
      mockedUseGetFile.mockReturnValue({
        data: undefined,
        isLoading: false,
        error: new Error('File not found'),
        isError: true,
        isSuccess: false,
        status: 'error',
        fetchStatus: 'idle',
        refetch: vi.fn(),
      } as any)

      const {result} = renderHook(() => usePreviewHandler({collection: mockCollection}), {
        wrapper: createWrapper('/?preview=999'),
      })

      await waitFor(() => {
        const resultPreviewState = result.current.previewState
        expect(resultPreviewState.isModalOpen).toBe(true)
        expect(resultPreviewState.previewFile).toBe(null)
        expect(resultPreviewState.error).toBe('File not found')
        expect(resultPreviewState.showNavigationButtons).toBe(false)
      })
    })

    it('shows error when file not found and not loading', async () => {
      mockedUseGetFile.mockReturnValue({
        data: undefined,
        isLoading: false,
        error: null,
        isError: false,
        isSuccess: false,
        status: 'success',
        fetchStatus: 'idle',
        refetch: vi.fn(),
      } as any)

      const {result} = renderHook(() => usePreviewHandler({collection: mockCollection}), {
        wrapper: createWrapper('/?preview=999'),
      })

      await waitFor(() => {
        const resultPreviewState = result.current.previewState
        expect(resultPreviewState.isModalOpen).toBe(true)
        expect(resultPreviewState.previewFile).toBe(null)
        expect(resultPreviewState.error).toBe('File not found')
      })
    })
  })

  describe('handleCloseModal', () => {
    it('navigates to pathname without query params', () => {
      const {result} = renderHook(() => usePreviewHandler({collection: mockCollection}), {
        wrapper: createWrapper('/?preview=123'),
      })

      act(() => {
        result.current.previewHandlers.handleCloseModal()
      })

      expect(mockNavigate).toHaveBeenCalledWith('/', {replace: true})
    })

    it('preserves existing query parameters when closing preview', () => {
      const {result} = renderHook(() => usePreviewHandler({collection: mockCollection}), {
        wrapper: createWrapper('/?search_term=homework&folder_id=123&preview=456'),
      })

      act(() => {
        result.current.previewHandlers.handleCloseModal()
      })

      expect(mockNavigate).toHaveBeenCalledWith('?search_term=homework&folder_id=123', {
        replace: true,
      })
    })
  })

  describe('handleOpenPreview', () => {
    it('navigates with preview parameter', () => {
      const {result} = renderHook(() => usePreviewHandler({collection: mockCollection}), {
        wrapper: createWrapper(),
      })

      act(() => {
        result.current.previewHandlers.handleOpenPreview(mockCollection[0])
      })

      expect(mockNavigate).toHaveBeenCalledWith(`?preview=${mockCollection[0].id}`, {replace: true})
    })

    it('preserves existing query parameters', () => {
      const {result} = renderHook(() => usePreviewHandler({collection: mockCollection}), {
        wrapper: createWrapper('/?search=test'),
      })

      act(() => {
        result.current.previewHandlers.handleOpenPreview(mockCollection[0])
      })

      expect(mockNavigate).toHaveBeenCalledWith(`?search=test&preview=${mockCollection[0].id}`, {
        replace: true,
      })
    })

    it('preserves multiple existing query parameters when opening preview', () => {
      const {result} = renderHook(() => usePreviewHandler({collection: mockCollection}), {
        wrapper: createWrapper('/?search_term=homework&folder_id=123'),
      })

      act(() => {
        result.current.previewHandlers.handleOpenPreview(mockCollection[0])
      })

      expect(mockNavigate).toHaveBeenCalledWith(
        `?search_term=homework&folder_id=123&preview=${mockCollection[0].id}`,
        {
          replace: true,
        },
      )
    })
  })

  describe('context validation', () => {
    it('passes context parameters to useGetFile', () => {
      renderHook(
        () =>
          usePreviewHandler({
            collection: mockCollection,
            contextType: 'course',
            contextId: '456',
          }),
        {
          wrapper: createWrapper('/?preview=999'),
        },
      )

      expect(mockedUseGetFile).toHaveBeenCalledWith({
        fileId: '999',
        contextType: 'course',
        contextId: '456',
      })
    })

    it('does not call useGetFile when file is in collection', () => {
      const fileId = mockCollection[0].id.toString()

      renderHook(
        () =>
          usePreviewHandler({
            collection: mockCollection,
            contextType: 'course',
            contextId: '456',
          }),
        {
          wrapper: createWrapper(`/?preview=${fileId}`),
        },
      )

      expect(mockedUseGetFile).toHaveBeenCalledWith({
        fileId: null,
        contextType: 'course',
        contextId: '456',
      })
    })
  })
})
