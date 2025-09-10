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

export function useCourseInstructors(options: UseCourseInstructorsOptions = {}) {
  const {courseIds = [], limit = 5, enabled = true} = options

  return useInfiniteQuery({
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
}
