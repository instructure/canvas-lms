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

import {renderHook, act} from '@testing-library/react-hooks'
import {usePagination} from '../usePagination'

describe('usePagination', () => {
  const mockFetchNextPage = jest.fn()

  beforeEach(() => {
    mockFetchNextPage.mockClear()
    mockFetchNextPage.mockResolvedValue(undefined)
  })

  it('should calculate total pages when hasNextPage is true', () => {
    const {result} = renderHook(() =>
      usePagination({
        hasNextPage: true,
        totalPagesLoaded: 3,
        fetchNextPage: mockFetchNextPage,
      }),
    )

    expect(result.current.paginationProps.totalPages).toBe(4)
  })

  it('should show loading state when isFetchingNextPage is true', () => {
    const {result} = renderHook(() =>
      usePagination({
        hasNextPage: false,
        totalPagesLoaded: 3,
        fetchNextPage: mockFetchNextPage,
        isFetchingNextPage: true,
      }),
    )

    expect(result.current.paginationProps.isLoading).toBe(true)
  })

  it('should show loading state when isFetchingPreviousPage is true', () => {
    const {result} = renderHook(() =>
      usePagination({
        hasNextPage: false,
        totalPagesLoaded: 3,
        fetchNextPage: mockFetchNextPage,
        isFetchingPreviousPage: true,
      }),
    )

    expect(result.current.paginationProps.isLoading).toBe(true)
  })

  describe('page navigation', () => {
    it('should navigate to a page within loaded pages', () => {
      const {result} = renderHook(() =>
        usePagination({
          hasNextPage: false,
          totalPagesLoaded: 3,
          fetchNextPage: mockFetchNextPage,
        }),
      )

      act(() => {
        result.current.paginationProps.onPageChange(2)
      })

      expect(result.current.currentPageIndex).toBe(1)
      expect(result.current.paginationProps.currentPage).toBe(2)
      expect(mockFetchNextPage).not.toHaveBeenCalled()
    })

    it('should fetch next page when navigating to unloaded page', async () => {
      const {result} = renderHook(() =>
        usePagination({
          hasNextPage: true,
          totalPagesLoaded: 3,
          fetchNextPage: mockFetchNextPage,
        }),
      )

      await act(async () => {
        result.current.paginationProps.onPageChange(4)
      })

      expect(mockFetchNextPage).toHaveBeenCalledTimes(1)
      expect(result.current.currentPageIndex).toBe(3)
    })

    it('should not fetch when navigating beyond available pages', () => {
      const {result} = renderHook(() =>
        usePagination({
          hasNextPage: false,
          totalPagesLoaded: 3,
          fetchNextPage: mockFetchNextPage,
        }),
      )

      act(() => {
        result.current.paginationProps.onPageChange(5)
      })

      expect(mockFetchNextPage).not.toHaveBeenCalled()
      expect(result.current.currentPageIndex).toBe(0)
    })
  })

  describe('resetPagination', () => {
    it('should reset to first page', () => {
      const {result} = renderHook(() =>
        usePagination({
          hasNextPage: false,
          totalPagesLoaded: 3,
          fetchNextPage: mockFetchNextPage,
        }),
      )

      act(() => {
        result.current.paginationProps.onPageChange(3)
      })

      expect(result.current.currentPageIndex).toBe(2)

      act(() => {
        result.current.resetPagination()
      })

      expect(result.current.currentPageIndex).toBe(0)
      expect(result.current.paginationProps.currentPage).toBe(1)
    })

    it('should handle zero total pages', () => {
      const {result} = renderHook(() =>
        usePagination({
          hasNextPage: false,
          totalPagesLoaded: 0,
          fetchNextPage: mockFetchNextPage,
        }),
      )

      expect(result.current.paginationProps.totalPages).toBe(0)
      expect(result.current.paginationProps.currentPage).toBe(1)
    })

    it('should handle single page scenario', () => {
      const {result} = renderHook(() =>
        usePagination({
          hasNextPage: false,
          totalPagesLoaded: 1,
          fetchNextPage: mockFetchNextPage,
        }),
      )

      expect(result.current.paginationProps.totalPages).toBe(1)

      act(() => {
        result.current.paginationProps.onPageChange(2)
      })

      expect(result.current.currentPageIndex).toBe(0)
      expect(mockFetchNextPage).not.toHaveBeenCalled()
    })
  })

  describe('pagination props', () => {
    it('should provide correct pagination props structure', () => {
      const {result} = renderHook(() =>
        usePagination({
          hasNextPage: true,
          totalPagesLoaded: 2,
          fetchNextPage: mockFetchNextPage,
          isFetchingNextPage: true,
        }),
      )

      const {paginationProps} = result.current

      expect(paginationProps).toHaveProperty('currentPage', 1)
      expect(paginationProps).toHaveProperty('totalPages', 3)
      expect(paginationProps).toHaveProperty('onPageChange')
      expect(paginationProps).toHaveProperty('isLoading', true)
      expect(typeof paginationProps.onPageChange).toBe('function')
    })
  })

  describe('totalCount-based pagination', () => {
    it('should calculate total pages from totalCount when available', () => {
      const {result} = renderHook(() =>
        usePagination({
          hasNextPage: true,
          totalPagesLoaded: 2,
          fetchNextPage: mockFetchNextPage,
          totalCount: 50,
          pageSize: 10,
        }),
      )

      expect(result.current.paginationProps.totalPages).toBe(5)
    })

    it('should handle totalCount with non-exact division', () => {
      const {result} = renderHook(() =>
        usePagination({
          hasNextPage: true,
          totalPagesLoaded: 1,
          fetchNextPage: mockFetchNextPage,
          totalCount: 23,
          pageSize: 10,
        }),
      )

      expect(result.current.paginationProps.totalPages).toBe(3)
    })

    it('should fallback to legacy calculation when totalCount is null', () => {
      const {result} = renderHook(() =>
        usePagination({
          hasNextPage: true,
          totalPagesLoaded: 3,
          fetchNextPage: mockFetchNextPage,
          totalCount: null,
          pageSize: 10,
        }),
      )

      expect(result.current.paginationProps.totalPages).toBe(4)
    })

    it('should fallback to legacy calculation when pageSize is not provided', () => {
      const {result} = renderHook(() =>
        usePagination({
          hasNextPage: true,
          totalPagesLoaded: 3,
          fetchNextPage: mockFetchNextPage,
          totalCount: 50,
        }),
      )

      expect(result.current.paginationProps.totalPages).toBe(4)
    })

    it('should immediately update currentPageIndex when totalCount and pageSize are provided', async () => {
      const {result} = renderHook(() =>
        usePagination({
          hasNextPage: true,
          totalPagesLoaded: 2,
          fetchNextPage: mockFetchNextPage,
          totalCount: 50,
          pageSize: 10,
        }),
      )

      await act(async () => {
        result.current.paginationProps.onPageChange(5)
      })

      // Should immediately update currentPageIndex without calling fetch functions
      // The data fetching hook will react to this change
      expect(mockFetchNextPage).not.toHaveBeenCalled()
      expect(result.current.currentPageIndex).toBe(4)
    })

    it('should fallback to sequential fetching when totalCount is not provided', async () => {
      const {result} = renderHook(() =>
        usePagination({
          hasNextPage: true,
          totalPagesLoaded: 2,
          fetchNextPage: mockFetchNextPage,
        }),
      )

      await act(async () => {
        result.current.paginationProps.onPageChange(5)
      })

      // Should fetch 3 pages sequentially (pages 3, 4, and 5)
      expect(mockFetchNextPage).toHaveBeenCalledTimes(3)
      expect(result.current.currentPageIndex).toBe(4)
    })

    it('should handle totalCount of 0', () => {
      const {result} = renderHook(() =>
        usePagination({
          hasNextPage: false,
          totalPagesLoaded: 0,
          fetchNextPage: mockFetchNextPage,
          totalCount: 0,
          pageSize: 10,
        }),
      )

      expect(result.current.paginationProps.totalPages).toBe(0)
    })

    it('should handle small totalCount (less than pageSize)', () => {
      const {result} = renderHook(() =>
        usePagination({
          hasNextPage: false,
          totalPagesLoaded: 1,
          fetchNextPage: mockFetchNextPage,
          totalCount: 5,
          pageSize: 10,
        }),
      )

      expect(result.current.paginationProps.totalPages).toBe(1)
    })
  })
})
