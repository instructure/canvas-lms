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
import {waitFor} from '@testing-library/react'
import fetchMock from 'fetch-mock'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {useGetFile} from '../useGetFile'
import {NotFoundError} from '../../../utils/apiUtils'

const createWrapper = () => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
        staleTime: 0,
      },
    },
  })

  return ({children}: {children: React.ReactNode}) => (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  )
}

describe('useGetFile', () => {
  const mockFile = {
    id: 123,
    display_name: 'test-file.pdf',
    context_asset_string: 'course_456',
    url: 'http://test.com/files/123',
    size: 1024,
    'content-type': 'application/pdf',
    filename: 'test-file.pdf',
    folder_id: '789',
  }

  beforeEach(() => {
    fetchMock.reset()
  })

  afterEach(() => {
    fetchMock.reset()
  })

  describe('when fileId is provided', () => {
    it('fetches file successfully', async () => {
      fetchMock.get(
        'path:/api/v1/files/123',
        {
          body: mockFile,
          status: 200,
        },
        {overwriteRoutes: true},
      )

      const {result} = renderHook(() => useGetFile({fileId: '123'}), {
        wrapper: createWrapper(),
      })

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true)
      })

      expect(result.current.data).toEqual(mockFile)
      expect(fetchMock.lastUrl()).toContain('/api/v1/files/123')
      expect(fetchMock.lastUrl()).toContain('include[]=user')
      expect(fetchMock.lastUrl()).toContain('include[]=usage_rights')
      expect(fetchMock.lastUrl()).toContain('include[]=enhanced_preview_url')
      expect(fetchMock.lastUrl()).toContain('include[]=context_asset_string')
    })

    it('validates context and accepts file from correct context', async () => {
      fetchMock.get(
        'path:/api/v1/files/123',
        {
          body: mockFile,
          status: 200,
        },
        {overwriteRoutes: true},
      )

      const {result} = renderHook(
        () =>
          useGetFile({
            fileId: '123',
            contextType: 'course',
            contextId: '456',
          }),
        {
          wrapper: createWrapper(),
        },
      )

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true)
      })

      expect(result.current.data).toEqual(mockFile)
    })

    it('validates context and rejects file from wrong context', async () => {
      fetchMock.get(
        'path:/api/v1/files/123',
        {
          body: mockFile,
          status: 200,
        },
        {overwriteRoutes: true},
      )

      const {result} = renderHook(
        () =>
          useGetFile({
            fileId: '123',
            contextType: 'course',
            contextId: '999', // Different context
          }),
        {
          wrapper: createWrapper(),
        },
      )

      await waitFor(() => {
        expect(result.current.isError).toBe(true)
      })

      expect(result.current.error).toBeInstanceOf(NotFoundError)
      expect((result.current.error as NotFoundError).message).toBe(
        'File not found in current context',
      )
    })

    it('handles API errors correctly', async () => {
      fetchMock.get(
        'path:/api/v1/files/123',
        {
          status: 404,
        },
        {overwriteRoutes: true},
      )

      const {result} = renderHook(() => useGetFile({fileId: '123'}), {
        wrapper: createWrapper(),
      })

      await waitFor(() => {
        expect(result.current.isError).toBe(true)
      })

      expect(result.current.error).toBeDefined()
    })

    it('handles empty response', async () => {
      fetchMock.get(
        'path:/api/v1/files/123',
        {
          body: null,
          status: 200,
        },
        {overwriteRoutes: true},
      )

      const {result} = renderHook(() => useGetFile({fileId: '123'}), {
        wrapper: createWrapper(),
      })

      await waitFor(() => {
        expect(result.current.isError).toBe(true)
      })

      expect(result.current.error).toBeInstanceOf(NotFoundError)
      expect((result.current.error as NotFoundError).message).toBe('File not found')
    })
  })

  describe('when fileId is null', () => {
    it('does not make API call', () => {
      const {result} = renderHook(() => useGetFile({fileId: null}), {
        wrapper: createWrapper(),
      })

      expect(result.current.data).toBeUndefined()
      expect(result.current.isLoading).toBe(false)
      expect(fetchMock.called()).toBe(false)
    })
  })

  describe('when fileId is an empty string', () => {
    it('does not make API call', () => {
      const {result} = renderHook(() => useGetFile({fileId: ''}), {
        wrapper: createWrapper(),
      })

      expect(result.current.data).toBeUndefined()
      expect(result.current.isLoading).toBe(false)
      expect(fetchMock.called()).toBe(false)
    })
  })
})
