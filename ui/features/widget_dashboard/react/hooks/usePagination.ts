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

import {useState, useCallback} from 'react'

export interface UsePaginationOptions {
  hasNextPage: boolean
  totalPagesLoaded: number
  fetchNextPage: () => Promise<any>
  isFetchingNextPage?: boolean
  isFetchingPreviousPage?: boolean
  totalCount?: number | null
  pageSize?: number
}

export interface UsePaginationReturn {
  currentPageIndex: number
  resetPagination: () => void
  paginationProps: {
    currentPage: number
    totalPages: number
    onPageChange: (pageNumber: number) => void
    isLoading?: boolean
  }
}

export const usePagination = ({
  hasNextPage,
  totalPagesLoaded,
  fetchNextPage,
  isFetchingNextPage,
  isFetchingPreviousPage,
  totalCount,
  pageSize,
}: UsePaginationOptions): UsePaginationReturn => {
  const [currentPageIndex, setCurrentPageIndex] = useState<number>(0)

  // Calculate total pages from totalCount if available and pageSize is provided
  const totalPages =
    totalCount !== undefined && totalCount !== null && pageSize && pageSize > 0
      ? Math.ceil(totalCount / pageSize)
      : hasNextPage
        ? totalPagesLoaded + 1
        : totalPagesLoaded
  const currentPage = currentPageIndex + 1

  const goToPage = useCallback(
    async (pageNumber: number) => {
      const targetIndex = pageNumber - 1

      // Validate page number
      if (targetIndex < 0) return
      if (pageNumber < 1) return

      // If we have totalCount and pageSize, validate against total pages
      if (totalCount !== undefined && totalCount !== null && pageSize && pageSize > 0) {
        const maxPages = Math.ceil(totalCount / pageSize)
        if (pageNumber > maxPages) return
      }

      // For direct page jumping with totalCount, just update the index immediately
      // The data fetching hook will react to this change
      if (totalCount !== undefined && totalCount !== null && pageSize && pageSize > 0) {
        setCurrentPageIndex(targetIndex)
      } else if (targetIndex < totalPagesLoaded) {
        // Page already loaded, just navigate to it
        setCurrentPageIndex(targetIndex)
      } else if (hasNextPage) {
        // Fallback: fetch pages sequentially (required for cursor-based pagination without calculated cursors)
        const pagesToFetch = targetIndex - totalPagesLoaded + 1

        for (let i = 0; i < pagesToFetch; i++) {
          await fetchNextPage()
        }

        setCurrentPageIndex(targetIndex)
      }
    },
    [totalPagesLoaded, hasNextPage, fetchNextPage, totalCount, pageSize],
  )

  const resetPagination = useCallback(() => {
    setCurrentPageIndex(0)
  }, [])

  const isLoading = !!(isFetchingNextPage || isFetchingPreviousPage)

  const paginationProps = {
    currentPage,
    totalPages,
    onPageChange: goToPage,
    isLoading,
  }

  return {
    currentPageIndex,
    resetPagination,
    paginationProps,
  }
}
