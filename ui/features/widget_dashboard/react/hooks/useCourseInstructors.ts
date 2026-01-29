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

import {useState, useCallback, useEffect} from 'react'
import {useInfiniteQuery, useQuery, useQueryClient, keepPreviousData} from '@tanstack/react-query'
import {createUserQueryConfig} from '../utils/graphql'
import {COURSE_INSTRUCTORS_PAGINATED_KEY, QUERY_CONFIG} from '../constants'
import {fetchPaginatedCourseInstructors} from '../graphql/coursePeople'
import {useWidgetDashboard} from './useWidgetDashboardContext'
import {widgetDashboardPersister} from '../utils/persister'
import {useBroadcastQuery} from '@canvas/query/broadcast'

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
  enrollmentTypes?: string[]
}

export function useCourseInstructors(options: UseCourseInstructorsOptions = {}) {
  const {courseIds = [], limit = 5, enabled = true, enrollmentTypes} = options

  const {observedUserId} = useWidgetDashboard()

  return useInfiniteQuery({
    ...createUserQueryConfig(
      [
        COURSE_INSTRUCTORS_PAGINATED_KEY,
        courseIds.join(','),
        limit,
        observedUserId ?? undefined,
        enrollmentTypes?.join(','),
      ],
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
        enrollmentTypes,
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
  enrollmentTypes?: string[],
): Promise<InstructorResult> {
  const cursor = calculateCursorForPage(pageIndex, limit)

  const result = await fetchPaginatedCourseInstructors(
    courseIds,
    limit,
    cursor,
    observedUserId,
    enrollmentTypes,
  )

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

export function useCourseInstructorsPaginated(options: UseCourseInstructorsOptions = {}) {
  const {courseIds = [], limit = 5, enrollmentTypes} = options
  const queryClient = useQueryClient()
  const [currentPageIndex, setCurrentPageIndex] = useState<number>(0)
  const {observedUserId} = useWidgetDashboard()
  const pageSize = limit

  // Generate unique query key for current page
  const queryKey = [
    COURSE_INSTRUCTORS_PAGINATED_KEY,
    'page',
    currentPageIndex,
    courseIds.join(','),
    limit,
    observedUserId ?? undefined,
    enrollmentTypes?.join(','),
  ]

  // Use TanStack Query for this specific page (uses client from context)
  const {
    data: currentPage,
    isLoading,
    isFetching,
    error,
    refetch: refetchCurrentPage,
  } = useQuery({
    queryKey,
    queryFn: () =>
      fetchInstructorsPage(
        currentPageIndex,
        courseIds,
        limit,
        observedUserId ?? undefined,
        enrollmentTypes,
      ),
    staleTime: QUERY_CONFIG.STALE_TIME.USERS * 60 * 1000, // Convert minutes to ms
    persister: widgetDashboardPersister,
    refetchOnMount: false,
    placeholderData: keepPreviousData,
  })

  // Broadcast instructor updates across tabs
  useBroadcastQuery({
    queryKey: [COURSE_INSTRUCTORS_PAGINATED_KEY],
    broadcastChannel: 'widget-dashboard',
  })

  // Reset to page 0 when course filters or enrollment types change
  const courseIdString = courseIds.join(',')
  const enrollmentTypesString = enrollmentTypes?.join(',')
  useEffect(() => {
    setCurrentPageIndex(0)
  }, [courseIdString, limit, enrollmentTypesString])

  const totalCount = currentPage?.pageInfo.totalCount ?? null
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

  const refetch = useCallback(async () => {
    // Invalidate all course instructors queries to force refetch
    await queryClient.invalidateQueries({
      queryKey: [COURSE_INSTRUCTORS_PAGINATED_KEY],
    })
    return refetchCurrentPage()
  }, [queryClient, refetchCurrentPage])

  const isPaginationLoading = isFetching && !!currentPage

  return {
    currentPage,
    currentPageIndex,
    totalPages,
    totalCount,
    goToPage,
    resetPagination,
    refetch,
    isLoading,
    isPaginationLoading,
    error: error as Error | null,
    pageSize,
  }
}
