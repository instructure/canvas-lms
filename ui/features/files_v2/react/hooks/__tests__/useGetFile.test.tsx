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
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {useGetFile} from '../useGetFile'
import {NotFoundError} from '../../../utils/apiUtils'

const server = setupServer()

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

  let lastRequestUrl: string | undefined

  beforeAll(() => server.listen())
  afterAll(() => server.close())
  afterEach(() => {
    server.resetHandlers()
    lastRequestUrl = undefined
  })

  describe('when fileId is provided', () => {
    it('fetches file successfully', async () => {
      server.use(
        http.get('/api/v1/files/123', ({request}) => {
          lastRequestUrl = request.url
          return HttpResponse.json(mockFile)
        }),
      )

      const {result} = renderHook(() => useGetFile({fileId: '123'}), {
        wrapper: createWrapper(),
      })

      await waitFor(() => {
        expect(result.current.isSuccess).toBe(true)
      })

      expect(result.current.data).toEqual(mockFile)
      expect(lastRequestUrl).toContain('/api/v1/files/123')
      expect(lastRequestUrl).toContain('include[]=user')
      expect(lastRequestUrl).toContain('include[]=usage_rights')
      expect(lastRequestUrl).toContain('include[]=enhanced_preview_url')
      expect(lastRequestUrl).toContain('include[]=context_asset_string')
    })

    it('validates context and accepts file from correct context', async () => {
      server.use(
        http.get('/api/v1/files/123', () => {
          return HttpResponse.json(mockFile)
        }),
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
      server.use(
        http.get('/api/v1/files/123', () => {
          return HttpResponse.json(mockFile)
        }),
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
      server.use(
        http.get('/api/v1/files/123', () => {
          return new HttpResponse(null, {status: 404})
        }),
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
      server.use(
        http.get('/api/v1/files/123', () => {
          return HttpResponse.json(null)
        }),
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
      let requestMade = false
      server.use(
        http.get('/api/v1/files/*', () => {
          requestMade = true
          return HttpResponse.json({})
        }),
      )

      const {result} = renderHook(() => useGetFile({fileId: null}), {
        wrapper: createWrapper(),
      })

      expect(result.current.data).toBeUndefined()
      expect(result.current.isLoading).toBe(false)
      expect(requestMade).toBe(false)
    })
  })

  describe('when fileId is an empty string', () => {
    it('does not make API call', () => {
      let requestMade = false
      server.use(
        http.get('/api/v1/files/*', () => {
          requestMade = true
          return HttpResponse.json({})
        }),
      )

      const {result} = renderHook(() => useGetFile({fileId: ''}), {
        wrapper: createWrapper(),
      })

      expect(result.current.data).toBeUndefined()
      expect(result.current.isLoading).toBe(false)
      expect(requestMade).toBe(false)
    })
  })
})
