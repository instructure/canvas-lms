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
import {waitFor} from '@testing-library/react'
import {renderHook, act} from '@testing-library/react-hooks'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {useQueryPageViewsPaginated} from '../useQueryPageViewsPaginated'
import {type APIPageView} from '../../utils'
import doFetchApiModule from '@canvas/do-fetch-api-effect'

// Mock doFetchApi
vi.mock('@canvas/do-fetch-api-effect', () => ({
  __esModule: true,
  default: vi.fn(),
}))
const doFetchApi = vi.mocked(doFetchApiModule)

function createWrapper() {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
      },
    },
  })

  return ({children}: {children: React.ReactNode}) => (
    <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>
  )
}

// Helper function to create mock API page views
function createMockPageViews(userId: string, pageNumber: number, count: number): APIPageView[] {
  return Array.from({length: count}, (_, index) => ({
    id: `${userId}-${pageNumber}-${index}`,
    url: `http://example.com/page${index + 1}`,
    created_at: new Date().toISOString(),
    participated: Math.random() > 0.5,
    interaction_seconds: Math.floor(Math.random() * 300),
    user_agent: 'Mozilla/5.0 Test Browser',
    app_name: 'TestApp',
    http_method: 'GET',
  }))
}

beforeEach(() => {
  vi.clearAllMocks()
})

describe('useQueryPageViewsPaginated', () => {
  const defaultOptions = {
    userId: '123',
    pageSize: 10,
  }

  it('should initialize with correct default state', async () => {
    // Mock API response for page 1
    const mockViews = createMockPageViews('123', 1, 10)
    const nextPageBookmark = btoa('bookmark:2')
    doFetchApi.mockResolvedValue({
      json: mockViews,
      link: {
        next: {
          url: `http://localhost/api/v1/users/123/page_views?page=${nextPageBookmark}&per_page=10`,
          rel: 'next',
        },
      },
      response: {} as Response,
      text: JSON.stringify(mockViews),
    })

    const {result} = renderHook(() => useQueryPageViewsPaginated(defaultOptions), {
      wrapper: createWrapper(),
    })

    // Check initial state
    expect(result.current.currentPage).toBe(1)
    expect(result.current.totalPages).toBe(2) // Should be at least 2 (current + potential next)
    expect(result.current.hasReachedEnd).toBe(false)
    expect(result.current.isFetching).toBe(true) // Should be loading initially

    // Wait for data to load
    await waitFor(() => {
      expect(result.current.isSuccess).toBe(true)
    })

    expect(result.current.views).toHaveLength(10)
    expect(result.current.isFetching).toBe(false)
  })

  it('should handle page changes correctly', async () => {
    // Set up mocks for page 1 and page 2
    const page1Views = createMockPageViews('124', 1, 10)
    const page2Views = createMockPageViews('124', 2, 10)

    // Mock first call (page 1)
    vi.mocked(doFetchApi).mockResolvedValueOnce({
      json: page1Views,
      link: {
        next: {
          url: `http://localhost/api/v1/users/124/page_views?page=${btoa('bookmark:2')}&per_page=10`,
          rel: 'next',
        },
      },
      response: {} as Response,
      text: JSON.stringify(page1Views),
    })

    // Mock second call (page 2)
    vi.mocked(doFetchApi).mockResolvedValueOnce({
      json: page2Views,
      link: {
        next: {
          url: `http://localhost/api/v1/users/124/page_views?page=${btoa('bookmark:3')}&per_page=10`,
          rel: 'next',
        },
      },
      response: {} as Response,
      text: JSON.stringify(page2Views),
    })

    const {result} = renderHook(
      () =>
        useQueryPageViewsPaginated({
          userId: '124',
          pageSize: 10,
        }),
      {
        wrapper: createWrapper(),
      },
    )

    // Wait for initial load
    await waitFor(() => {
      expect(result.current.isSuccess).toBe(true)
    })

    expect(result.current.currentPage).toBe(1)
    expect(result.current.views).toHaveLength(10)

    // Change to page 2
    act(() => {
      result.current.setCurrentPage(2)
    })

    expect(result.current.currentPage).toBe(2)

    // Wait for page 2 data
    await waitFor(() => {
      expect(result.current.views).toHaveLength(10)
      expect(result.current.views[0].id).toContain('124-2-') // Should have page 2 data
    })

    expect(vi.mocked(doFetchApi).mock.calls).toHaveLength(2) // Should have made 2 API calls
  })

  it('should update totalPages as pages are discovered', async () => {
    const page1Views = createMockPageViews('125', 1, 10)
    const page2Views = createMockPageViews('125', 2, 10)

    // Mock page 1 with next page
    vi.mocked(doFetchApi).mockResolvedValueOnce({
      json: page1Views,
      link: {
        next: {
          url: `http://localhost/api/v1/users/125/page_views?page=${btoa('bookmark:2')}&per_page=10`,
          rel: 'next',
        },
      },
      response: {} as Response,
      text: JSON.stringify(page1Views),
    })

    // Mock page 2 with next page
    vi.mocked(doFetchApi).mockResolvedValueOnce({
      json: page2Views,
      link: {
        next: {
          url: `http://localhost/api/v1/users/125/page_views?page=${btoa('bookmark:3')}&per_page=10`,
          rel: 'next',
        },
      },
      response: {} as Response,
      text: JSON.stringify(page2Views),
    })

    const {result} = renderHook(
      () =>
        useQueryPageViewsPaginated({
          userId: '125',
          pageSize: 10,
        }),
      {
        wrapper: createWrapper(),
      },
    )

    // Wait for initial load
    await waitFor(() => {
      expect(result.current.isSuccess).toBe(true)
    })

    expect(result.current.totalPages).toBe(2) // Should show next page is available

    // Go to page 2
    act(() => {
      result.current.setCurrentPage(2)
    })

    await waitFor(() => {
      expect(result.current.views[0].id).toContain('125-2-')
    })

    expect(result.current.totalPages).toBe(3) // Should now show page 3 is available
  })

  it('should handle empty pages by reverting to previous page', async () => {
    const page1Views = createMockPageViews('126', 1, 10)
    const page2Views = createMockPageViews('126', 2, 10)

    // Mock page 1 with next page
    vi.mocked(doFetchApi).mockResolvedValueOnce({
      json: page1Views,
      link: {
        next: {
          url: `http://localhost/api/v1/users/126/page_views?page=${btoa('bookmark:2')}&per_page=10`,
          rel: 'next',
        },
      },
      response: {} as Response,
      text: JSON.stringify(page1Views),
    })

    // Mock page 2 with next page
    vi.mocked(doFetchApi).mockResolvedValueOnce({
      json: page2Views,
      link: {
        next: {
          url: `http://localhost/api/v1/users/126/page_views?page=${btoa('bookmark:3')}&per_page=10`,
          rel: 'next',
        },
      },
      response: {} as Response,
      text: JSON.stringify(page2Views),
    })

    // Mock page 3 as empty
    vi.mocked(doFetchApi).mockResolvedValueOnce({
      json: [],
      link: undefined,
      response: {} as Response,
      text: '[]',
    })

    const {result} = renderHook(
      () =>
        useQueryPageViewsPaginated({
          userId: '126',
          pageSize: 10,
        }),
      {
        wrapper: createWrapper(),
      },
    )

    // Wait for initial load
    await waitFor(() => {
      expect(result.current.isSuccess).toBe(true)
    })

    // Go to page 2
    act(() => {
      result.current.setCurrentPage(2)
    })

    await waitFor(() => {
      expect(result.current.currentPage).toBe(2)
    })

    // Try to go to page 3 (which should be empty)
    act(() => {
      result.current.setCurrentPage(3)
    })

    // Wait for the fetch to complete first, then check for the revert
    await waitFor(() => {
      expect(result.current.isFetching).toBe(false)
    })

    // Should revert back to page 2
    await waitFor(() => {
      expect(result.current.currentPage).toBe(2)
      expect(result.current.hasReachedEnd).toBe(true)
      expect(result.current.totalPages).toBe(2) // Should not show more pages
    })

    expect(vi.mocked(doFetchApi).mock.calls).toHaveLength(3) // Should have made 3 API calls (1, 2, 3)
  })

  it('should handle completely empty response', async () => {
    // Mock empty response
    vi.mocked(doFetchApi).mockResolvedValue({
      json: [],
      link: undefined,
      response: {} as Response,
      text: '[]',
    })

    const {result} = renderHook(
      () =>
        useQueryPageViewsPaginated({
          userId: '130',
          pageSize: 10,
        }),
      {
        wrapper: createWrapper(),
      },
    )

    await waitFor(() => {
      expect(result.current.isSuccess).toBe(true)
    })

    expect(result.current.views).toHaveLength(0)
    expect(result.current.currentPage).toBe(1)
    expect(result.current.totalPages).toBe(2) // Even empty first page shows potential next page
    expect(result.current.hasReachedEnd).toBe(false) // Empty first page doesn't trigger hasReachedEnd
  })

  it('should handle date range parameters', async () => {
    const mockViews = createMockPageViews('127', 1, 5)

    vi.mocked(doFetchApi).mockImplementation((options) => {
      // Verify that the date parameters are passed correctly
      expect(options.params?.start_time).toBe('2023-01-01T00:00:00.000Z')
      expect(options.params?.end_time).toBe('2023-01-31T23:59:59.999Z')

      return Promise.resolve({
        json: mockViews,
        link: undefined,
        response: {} as Response,
        text: JSON.stringify(mockViews),
      })
    })

    const startDate = new Date('2023-01-01T00:00:00.000Z')
    const endDate = new Date('2023-01-31T23:59:59.999Z')

    const {result} = renderHook(
      () =>
        useQueryPageViewsPaginated({
          userId: '127',
          startDate,
          endDate,
          pageSize: 5,
        }),
      {
        wrapper: createWrapper(),
      },
    )

    await waitFor(() => {
      expect(result.current.isSuccess).toBe(true)
    })

    expect(result.current.views).toHaveLength(5)
  })

  it('should throw error when startDate is provided without endDate', async () => {
    const startDate = new Date('2023-01-01T00:00:00.000Z')

    const {result} = renderHook(
      () =>
        useQueryPageViewsPaginated({
          userId: '128',
          startDate, // Missing endDate
          pageSize: 5,
        }),
      {
        wrapper: createWrapper(),
      },
    )

    await waitFor(() => {
      expect(result.current.error).toBeDefined()
      expect(result.current.error?.message).toContain('endDate must be set if startDate is set')
    })
  })

  it('should maintain page bookmarks correctly', async () => {
    const page1Views = createMockPageViews('129', 1, 5)
    const page2Views = createMockPageViews('129', 2, 5)

    // Mock page 1 with next page
    vi.mocked(doFetchApi).mockResolvedValueOnce({
      json: page1Views,
      link: {
        next: {
          url: `http://localhost/api/v1/users/129/page_views?page=${btoa('bookmark:2')}&per_page=5`,
          rel: 'next',
        },
      },
      response: {} as Response,
      text: JSON.stringify(page1Views),
    })

    // Mock page 2 with next page
    vi.mocked(doFetchApi).mockResolvedValueOnce({
      json: page2Views,
      link: {
        next: {
          url: `http://localhost/api/v1/users/129/page_views?page=${btoa('bookmark:3')}&per_page=5`,
          rel: 'next',
        },
      },
      response: {} as Response,
      text: JSON.stringify(page2Views),
    })

    const {result} = renderHook(
      () =>
        useQueryPageViewsPaginated({
          userId: '129',
          pageSize: 5,
        }),
      {
        wrapper: createWrapper(),
      },
    )

    // Wait for initial load
    await waitFor(() => {
      expect(result.current.isSuccess).toBe(true)
    })

    // Go to page 2
    act(() => {
      result.current.setCurrentPage(2)
    })

    await waitFor(() => {
      expect(result.current.currentPage).toBe(2)
    })

    // Go back to page 1
    act(() => {
      result.current.setCurrentPage(1)
    })

    await waitFor(() => {
      expect(result.current.currentPage).toBe(1)
    })

    // Should still remember page 3 is available
    expect(result.current.totalPages).toBe(3)

    // Going back to page 2 should use cached bookmark
    act(() => {
      result.current.setCurrentPage(2)
    })

    await waitFor(() => {
      expect(result.current.currentPage).toBe(2)
    })

    // Should have made the right number of API calls (not excessive)
    expect(vi.mocked(doFetchApi).mock.calls.length).toBeLessThanOrEqual(4) // 1, 2, back to 1 (cached), back to 2 (cached or new)
  })
})
