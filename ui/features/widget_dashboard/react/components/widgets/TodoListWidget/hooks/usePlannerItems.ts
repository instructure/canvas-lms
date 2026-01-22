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

import {useState, useCallback, useMemo, useEffect, useRef} from 'react'
import {useQuery} from '@tanstack/react-query'
import {fetchPlannerItems, type FetchPlannerItemsParams} from '../api'
import type {PlannerItem} from '../types'
import {widgetDashboardPersister} from '../../../../utils/persister'

export const PLANNER_ITEMS_QUERY_KEY = 'plannerItems'

interface UsePlannerItemsOptions {
  perPage?: number
  startDate?: string
  endDate?: string
  order?: 'asc' | 'desc'
  filter?:
    | 'new_activity'
    | 'ungraded_todo_items'
    | 'all_ungraded_todo_items'
    | 'incomplete_items'
    | 'complete_items'
}

interface UsePlannerItemsResult {
  currentPage: PlannerItem[]
  currentPageIndex: number
  totalPages: number
  goToPage: (page: number) => void
  resetPagination: () => void
  isLoading: boolean
  error: Error | null
  refetch: () => void
}

export function usePlannerItems(options: UsePlannerItemsOptions = {}): UsePlannerItemsResult {
  const {perPage = 5, startDate, endDate, order = 'asc', filter} = options
  const [currentPageIndex, setCurrentPageIndex] = useState(0)
  const [allPages, setAllPages] = useState<PlannerItem[][]>([])
  const [nextUrls, setNextUrls] = useState<(string | null)[]>([])
  const [isLoadingMore, setIsLoadingMore] = useState(false)
  const loadingPageRef = useRef<number | null>(null)

  const queryParams: FetchPlannerItemsParams = useMemo(() => {
    const params: FetchPlannerItemsParams = {
      per_page: perPage,
      order,
    }

    if (startDate) params.start_date = startDate
    if (endDate) params.end_date = endDate
    if (filter) params.filter = filter

    return params
  }, [perPage, startDate, endDate, order, filter])

  const {
    data,
    isLoading,
    error,
    refetch: refetchInitial,
  } = useQuery({
    queryKey: [PLANNER_ITEMS_QUERY_KEY, queryParams],
    queryFn: () => fetchPlannerItems(queryParams),
    staleTime: 5 * 60 * 1000,
    retry: 2,
    persister: widgetDashboardPersister,
    refetchOnMount: false,
  })

  useEffect(() => {
    if (data) {
      setAllPages([data.items])
      setNextUrls([data.nextUrl])
    }
  }, [data])

  useEffect(() => {
    const targetPage = currentPageIndex
    const previousPageIndex = targetPage - 1

    // Check if we need to load this page
    if (
      targetPage >= allPages.length &&
      previousPageIndex >= 0 &&
      previousPageIndex < nextUrls.length &&
      nextUrls[previousPageIndex]
    ) {
      const nextUrl = nextUrls[previousPageIndex]

      if (!isLoadingMore && loadingPageRef.current !== targetPage) {
        loadingPageRef.current = targetPage
        setIsLoadingMore(true)

        fetchPlannerItems(queryParams, nextUrl)
          .then(response => {
            setAllPages(prev => {
              const newPages = [...prev]
              newPages[targetPage] = response.items
              return newPages
            })
            setNextUrls(prev => {
              const newUrls = [...prev]
              newUrls[targetPage] = response.nextUrl
              return newUrls
            })
          })
          .catch(() => {
            // Silently fail pagination - error will be caught by main query
          })
          .finally(() => {
            setIsLoadingMore(false)
            loadingPageRef.current = null
          })
      }
    }
  }, [currentPageIndex, allPages.length, nextUrls, isLoadingMore, queryParams])

  const goToPage = useCallback((page: number) => {
    setCurrentPageIndex(page - 1)
  }, [])

  const resetPagination = useCallback(() => {
    setCurrentPageIndex(0)
  }, [])

  const refetch = useCallback(() => {
    setAllPages([])
    setNextUrls([])
    setCurrentPageIndex(0)
    loadingPageRef.current = null
    refetchInitial()
  }, [refetchInitial])

  const currentPage = allPages[currentPageIndex] || []
  const hasMorePages = currentPageIndex < nextUrls.length && !!nextUrls[currentPageIndex]
  const totalPages = allPages.length + (hasMorePages ? 1 : 0)

  return {
    currentPage,
    currentPageIndex,
    totalPages,
    goToPage,
    resetPagination,
    isLoading: isLoading || isLoadingMore,
    error: error as Error | null,
    refetch,
  }
}
