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
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {useUserTags} from '../useUserTags'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

const server = setupServer()

// Track the last request URL for verifying API calls
let lastRequestUrl: string | null = null
let lastRequestParams: URLSearchParams | null = null
let requestCount = 0

describe('useUserTags', () => {
  let queryClient: QueryClient

  beforeAll(() => server.listen())
  afterAll(() => server.close())

  beforeEach(() => {
    queryClient = new QueryClient({
      defaultOptions: {
        queries: {
          retry: false,
        },
      },
    })
    lastRequestUrl = null
    lastRequestParams = null
    requestCount = 0
  })

  afterEach(() => {
    server.resetHandlers()
  })

  const wrapper = ({children}: {children: React.ReactNode}) => (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  )

  it('fetches user tags correctly', async () => {
    const mockData = [
      {
        id: 1,
        name: 'Group 1',
        group_category_name: 'Category 1',
        is_single_tag: false,
      },
      {
        id: 2,
        name: 'Group 2',
        group_category_name: 'Category 2',
        is_single_tag: true,
      },
    ]

    server.use(
      http.get('/api/v1/courses/:courseId/groups', ({request}) => {
        const url = new URL(request.url)
        lastRequestUrl = url.pathname
        lastRequestParams = url.searchParams
        requestCount++
        return HttpResponse.json(mockData)
      }),
    )

    const {result} = renderHook(() => useUserTags(123, 456), {wrapper})

    expect(result.current.isLoading).toBe(true)
    expect(result.current.data).toBeUndefined()
    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
    })
    expect(result.current.error).toBeNull()
    expect(result.current.data).toEqual([
      {
        id: 1,
        name: 'Group 1',
        groupCategoryName: 'Category 1',
        isSingleTag: false,
      },
      {
        id: 2,
        name: 'Group 2',
        groupCategoryName: 'Category 2',
        isSingleTag: true,
      },
    ])
    expect(lastRequestUrl).toBe('/api/v1/courses/123/groups')
    expect(lastRequestParams?.get('collaboration_state')).toBe('non_collaborative')
    expect(lastRequestParams?.get('user_id')).toBe('456')
    expect(lastRequestParams?.get('per_page')).toBe('40')
  })

  it('handles API errors correctly', async () => {
    server.use(
      http.get('/api/v1/courses/:courseId/groups', () => {
        return HttpResponse.json({error: 'Server error'}, {status: 500})
      }),
    )

    const {result} = renderHook(() => useUserTags(123, 456), {wrapper})

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
    })
    expect(result.current.data).toBeUndefined()
    expect(result.current.error).toBeTruthy()
  })

  it('handles empty JSON response', async () => {
    server.use(
      http.get('/api/v1/courses/:courseId/groups', () => {
        return HttpResponse.json(null)
      }),
    )

    const {result} = renderHook(() => useUserTags(123, 456), {wrapper})

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false)
    })
    expect(result.current.data).toBeUndefined()
    expect(result.current.error).toBeTruthy()
    expect(result.current.error?.message).toBe('Failed to fetch user tags')
  })

  it('does not fetch when courseId is missing', async () => {
    server.use(
      http.get('/api/v1/courses/:courseId/groups', () => {
        requestCount++
        return HttpResponse.json([])
      }),
    )

    renderHook(() => useUserTags(0, 456), {wrapper})

    // Give it a moment to potentially make a request
    await new Promise(resolve => setTimeout(resolve, 50))
    expect(requestCount).toBe(0)
  })

  it('does not fetch when userId is missing', async () => {
    server.use(
      http.get('/api/v1/courses/:courseId/groups', () => {
        requestCount++
        return HttpResponse.json([])
      }),
    )

    renderHook(() => useUserTags(123, 0), {wrapper})

    // Give it a moment to potentially make a request
    await new Promise(resolve => setTimeout(resolve, 50))
    expect(requestCount).toBe(0)
  })

  it('respects custom perPage parameter', async () => {
    server.use(
      http.get('/api/v1/courses/:courseId/groups', ({request}) => {
        const url = new URL(request.url)
        lastRequestParams = url.searchParams
        requestCount++
        return HttpResponse.json([])
      }),
    )

    renderHook(() => useUserTags(123, 456, 20), {wrapper})

    await waitFor(() => {
      expect(requestCount).toBe(1)
    })
    expect(lastRequestParams?.get('per_page')).toBe('20')
  })
})
