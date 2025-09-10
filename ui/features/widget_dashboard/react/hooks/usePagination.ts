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
}: UsePaginationOptions): UsePaginationReturn => {
  const [currentPageIndex, setCurrentPageIndex] = useState<number>(0)

  const totalPages = hasNextPage ? totalPagesLoaded + 1 : totalPagesLoaded
  const currentPage = currentPageIndex + 1

  const goToPage = useCallback(
    (pageNumber: number) => {
      const targetIndex = pageNumber - 1

      if (targetIndex < 0) return

      if (targetIndex < totalPagesLoaded) {
        setCurrentPageIndex(targetIndex)
      } else if (targetIndex === totalPagesLoaded && hasNextPage) {
        fetchNextPage().then(() => {
          setCurrentPageIndex(targetIndex)
        })
      }
    },
    [totalPagesLoaded, hasNextPage, fetchNextPage],
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
