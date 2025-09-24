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

import {useInfiniteQuery} from '@tanstack/react-query'
import {useState} from 'react'
import {createUserQueryConfig} from '../utils/graphql'
import {QUERY_CONFIG} from '../constants'
import {fetchPaginatedCourseInstructors} from '../graphql/coursePeople'

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

interface UseCourseInstructorsResult {
  data: CourseInstructorForComponent[]
  isLoading: boolean
  error: Error | null
  hasNextPage: boolean
  hasPreviousPage: boolean
  fetchNextPage: () => void
  fetchPreviousPage: () => void
  goToPage: (pageNumber: number) => void
  currentPage: number
  totalPages: number
  refetch: () => void
}

export function useCourseInstructors(
  options: UseCourseInstructorsOptions = {},
): UseCourseInstructorsResult {
  const {courseIds = [], limit = 5, enabled = true} = options
  const [currentPageIndex, setCurrentPageIndex] = useState(0)

  const query = useInfiniteQuery({
    ...createUserQueryConfig(
      ['courseInstructorsPaginated', courseIds.join(','), limit],
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
    }> => {
      return fetchPaginatedCourseInstructors(courseIds, limit, pageParam)
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

  const currentPage = query.data?.pages[currentPageIndex]
  const totalPages = query.data?.pages.length || 1

  const fetchNextPage = () => {
    if (currentPageIndex < totalPages - 1) {
      setCurrentPageIndex(currentPageIndex + 1)
    } else if (query.hasNextPage) {
      query.fetchNextPage().then(() => {
        setCurrentPageIndex(currentPageIndex + 1)
      })
    }
  }

  const fetchPreviousPage = () => {
    if (currentPageIndex > 0) {
      setCurrentPageIndex(currentPageIndex - 1)
    }
  }

  const goToPage = (pageNumber: number) => {
    const targetIndex = pageNumber - 1

    if (targetIndex < 0) return

    if (targetIndex < totalPages) {
      setCurrentPageIndex(targetIndex)
    } else if (targetIndex === totalPages && query.hasNextPage) {
      query.fetchNextPage().then(() => {
        setCurrentPageIndex(targetIndex)
      })
    }
  }

  return {
    data: currentPage?.data ?? [],
    isLoading: query.isLoading,
    error: query.error,
    hasNextPage: currentPageIndex < totalPages - 1 || query.hasNextPage,
    hasPreviousPage: currentPageIndex > 0,
    fetchNextPage,
    fetchPreviousPage,
    goToPage,
    currentPage: currentPageIndex + 1,
    totalPages: query.hasNextPage ? totalPages + 1 : totalPages,
    refetch: query.refetch,
  }
}
