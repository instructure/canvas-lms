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

import {useState, useCallback, useEffect, useRef} from 'react'
import {useInfiniteQuery} from '@tanstack/react-query'
import {createUserQueryConfig} from '../utils/graphql'
import {COURSE_INSTRUCTORS_PAGINATED_KEY, QUERY_CONFIG} from '../constants'
import {fetchPaginatedCourseInstructors} from '../graphql/coursePeople'
import {useWidgetDashboard} from './useWidgetDashboardContext'

export interface CourseInstructorForComponent {
  id: string
  name: string
  sortable_name?: string
  short_name?: string
  avatar_url?: string
  email?: string
  bio?: string | null
  course_name?: string
  course_code?: string
  enrollments: Array<{
    id: string
    user_id: string
    course_id: string
    type: 'TeacherEnrollment' | 'TaEnrollment'
    role: string
    role_id: string
    enrollment_state: string
  }>
}

interface UseCourseInstructorsOptions {
  courseIds?: string[]
  limit?: number
  enabled?: boolean
}

export function useCourseInstructors(options: UseCourseInstructorsOptions = {}) {
  const {courseIds = [], limit = 5, enabled = true} = options

  const {observedUserId} = useWidgetDashboard()

  return useInfiniteQuery({
    ...createUserQueryConfig(
      [COURSE_INSTRUCTORS_PAGINATED_KEY, courseIds.join(','), limit, observedUserId ?? undefined],
      QUERY_CONFIG.STALE_TIME.USERS,
    ),
    queryFn: async ({
      pageParam,
    }): Promise<{
      data: CourseInstructorForComponent[]
      hasNextPage: boolean
      hasPreviousPage: boolean
      endCursor: string | null
      startCursor: string | null
      totalCount: number | null
    }> => {
      return fetchPaginatedCourseInstructors(
        courseIds,
        limit,
        pageParam,
        observedUserId ?? undefined,
      )
    },
    initialPageParam: undefined as string | undefined,
    getNextPageParam: lastPage => {
      return lastPage.hasNextPage ? lastPage.endCursor : undefined
    },
    getPreviousPageParam: firstPage => {
      return firstPage.hasPreviousPage ? firstPage.startCursor : undefined
    },
    enabled: enabled,
  })
}

function calculateCursorForPage(pageIndex: number, pageSize: number): string | undefined {
  if (pageIndex === 0) return undefined
  const offset = pageIndex * pageSize
  return btoa(String(offset))
}

interface InstructorPageInfo {
  hasNextPage: boolean
  hasPreviousPage: boolean
  endCursor: string | null
  startCursor: string | null
  totalCount: number | null
}

interface InstructorResult {
  data: CourseInstructorForComponent[]
  pageInfo: InstructorPageInfo
}

async function fetchInstructorsPage(
  pageIndex: number,
  courseIds: string[],
  limit: number,
  observedUserId?: string,
): Promise<InstructorResult> {
  const cursor = calculateCursorForPage(pageIndex, limit)

  const result = await fetchPaginatedCourseInstructors(courseIds, limit, cursor, observedUserId)

  return {
    data: result.data,
    pageInfo: {
      hasNextPage: result.hasNextPage,
      hasPreviousPage: result.hasPreviousPage,
      endCursor: result.endCursor,
      startCursor: result.startCursor,
      totalCount: result.totalCount,
    },
  }
}

interface PageCache {
  [pageIndex: number]: InstructorResult
}

export function useCourseInstructorsPaginated(options: UseCourseInstructorsOptions = {}) {
  const {courseIds = [], limit = 5} = options
  const [currentPageIndex, setCurrentPageIndex] = useState<number>(0)
  const [pageCache, setPageCache] = useState<PageCache>({})
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<Error | null>(null)
  const [totalCount, setTotalCount] = useState<number | null>(null)
  const optionsRef = useRef(options)
  const isFetchingRef = useRef<{[key: number]: boolean}>({})
  const {observedUserId} = useWidgetDashboard()

  useEffect(() => {
    optionsRef.current = options
  }, [options])

  const pageSize = limit

  const fetchPage = useCallback(
    async (pageIndex: number) => {
      if (pageCache[pageIndex]) {
        return pageCache[pageIndex]
      }

      if (isFetchingRef.current[pageIndex]) {
        return
      }

      isFetchingRef.current[pageIndex] = true
      setIsLoading(true)
      setError(null)

      try {
        const result = await fetchInstructorsPage(
          pageIndex,
          optionsRef.current.courseIds || [],
          optionsRef.current.limit || 5,
          observedUserId ?? undefined,
        )

        setPageCache(prev => ({
          ...prev,
          [pageIndex]: result,
        }))

        if (result.pageInfo.totalCount !== null) {
          setTotalCount(result.pageInfo.totalCount)
        }

        return result
      } catch (err) {
        setError(err as Error)
      } finally {
        setIsLoading(false)
        isFetchingRef.current[pageIndex] = false
      }
    },
    [pageCache, observedUserId],
  )

  useEffect(() => {
    fetchPage(currentPageIndex)
  }, [currentPageIndex, fetchPage])

  useEffect(() => {
    setPageCache({})
    setTotalCount(null)
    setCurrentPageIndex(0)
    isFetchingRef.current = {}
  }, [courseIds.join(','), limit])

  const resetAndRefetch = useCallback(() => {
    setPageCache({})
    setTotalCount(null)
    isFetchingRef.current = {}
    return fetchPage(currentPageIndex)
  }, [fetchPage, currentPageIndex])

  const totalPages =
    totalCount !== null && totalCount !== undefined ? Math.ceil(totalCount / pageSize) : 0

  const goToPage = useCallback((pageNumber: number) => {
    const targetIndex = pageNumber - 1
    if (targetIndex >= 0) {
      setCurrentPageIndex(targetIndex)
    }
  }, [])

  const resetPagination = useCallback(() => {
    setCurrentPageIndex(0)
  }, [])

  const currentPage = pageCache[currentPageIndex]

  return {
    currentPage,
    currentPageIndex,
    totalPages,
    totalCount,
    goToPage,
    resetPagination,
    refetch: resetAndRefetch,
    isLoading,
    error,
    pageSize,
  }
}
