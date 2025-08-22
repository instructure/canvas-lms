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
import {gql} from 'graphql-tag'
import type {CourseGrade} from '../types'
import {getCurrentUserId, executeGraphQLQuery, createUserQueryConfig} from '../utils/graphql'
import {COURSE_GRADES_WIDGET, QUERY_CONFIG} from '../constants'

interface UsePaginatedCoursesWithGradesOptions {
  limit?: number
}

interface UsePaginatedCoursesWithGradesResult {
  data: CourseGrade[]
  isLoading: boolean
  error: Error | null
  hasNextPage: boolean
  hasPreviousPage: boolean
  fetchNextPage: () => void
  fetchPreviousPage: () => void
  goToPage: (pageNumber: number) => void
  currentPage: number
  totalPages: number
}

interface UserEnrollment {
  course: {
    _id: string
    name: string
    courseCode?: string
  }
  updatedAt?: string
  grades?: {
    currentScore?: number | null
    currentGrade?: string | null
    finalScore?: number | null
    finalGrade?: string | null
    overrideScore?: number | null
    overrideGrade?: string | null
  } | null
}

interface PaginatedGraphQLResponse {
  legacyNode: {
    _id: string
    enrollmentsConnection: {
      nodes: UserEnrollment[]
      pageInfo: {
        hasNextPage: boolean
        hasPreviousPage: boolean
        startCursor: string | null
        endCursor: string | null
      }
    }
  }
}

const USER_COURSES_WITH_GRADES_CONNECTION_QUERY = gql`
  query GetUserCoursesWithGradesConnection($userId: ID!, $first: Int, $after: String) {
    legacyNode(_id: $userId, type: User) {
      ... on User {
        _id
        enrollmentsConnection(first: $first, after: $after, currentOnly: true) {
          nodes {
            course {
              _id
              name
              courseCode
            }
            updatedAt
            grades {
              currentScore
              currentGrade
              finalScore
              finalGrade
              overrideScore
              overrideGrade
            }
          }
          pageInfo {
            hasNextPage
            hasPreviousPage
            startCursor
            endCursor
          }
        }
      }
    }
  }
`

function transformEnrollmentToCourseGrade(enrollment: UserEnrollment): CourseGrade {
  const grades = enrollment.grades

  // Determine the display grade - prioritize override, then final, then current
  let displayGrade: number | null = null
  let displayGradeString: string | null = null

  if (grades?.overrideScore !== null && grades?.overrideScore !== undefined) {
    displayGrade = grades.overrideScore
    displayGradeString = grades.overrideGrade || null
  } else if (grades?.finalScore !== null && grades?.finalScore !== undefined) {
    displayGrade = grades.finalScore
    displayGradeString = grades.finalGrade || null
  } else if (grades?.currentScore !== null && grades?.currentScore !== undefined) {
    displayGrade = grades.currentScore
    displayGradeString = grades.currentGrade || null
  }

  return {
    courseId: enrollment.course._id,
    courseCode: enrollment.course.courseCode || COURSE_GRADES_WIDGET.DEFAULT_COURSE_CODE,
    courseName: enrollment.course.name,
    currentGrade: displayGrade,
    gradingScheme: displayGradeString
      ? COURSE_GRADES_WIDGET.GRADING_SCHEMES.LETTER
      : COURSE_GRADES_WIDGET.GRADING_SCHEMES.PERCENTAGE,
    lastUpdated: new Date(enrollment.updatedAt || new Date().toISOString()),
  }
}

export function usePaginatedCoursesWithGrades(
  options: UsePaginatedCoursesWithGradesOptions = {},
): UsePaginatedCoursesWithGradesResult {
  const {limit = COURSE_GRADES_WIDGET.MAX_GRID_ITEMS} = options
  const [currentPageIndex, setCurrentPageIndex] = useState(0)

  const query = useInfiniteQuery({
    ...createUserQueryConfig(
      ['userCoursesWithGradesPaginated', limit],
      QUERY_CONFIG.STALE_TIME.GRADES,
    ),
    queryFn: async ({
      pageParam,
    }): Promise<{
      data: CourseGrade[]
      hasNextPage: boolean
      hasPreviousPage: boolean
      endCursor: string | null
      startCursor: string | null
    }> => {
      const currentUserId = getCurrentUserId()

      const result = await executeGraphQLQuery<PaginatedGraphQLResponse>(
        USER_COURSES_WITH_GRADES_CONNECTION_QUERY,
        {
          userId: currentUserId,
          first: limit,
          after: pageParam,
        },
      )

      if (!result.legacyNode?.enrollmentsConnection) {
        return {
          data: [],
          hasNextPage: false,
          hasPreviousPage: false,
          endCursor: null,
          startCursor: null,
        }
      }

      const {nodes, pageInfo} = result.legacyNode.enrollmentsConnection

      return {
        data: nodes.map(transformEnrollmentToCourseGrade),
        hasNextPage: pageInfo.hasNextPage,
        hasPreviousPage: pageInfo.hasPreviousPage,
        endCursor: pageInfo.endCursor,
        startCursor: pageInfo.startCursor,
      }
    },
    initialPageParam: undefined as string | undefined,
    getNextPageParam: lastPage => {
      return lastPage.hasNextPage ? lastPage.endCursor : undefined
    },
    getPreviousPageParam: firstPage => {
      return firstPage.hasPreviousPage ? firstPage.startCursor : undefined
    },
  })

  const currentPage = query.data?.pages[currentPageIndex]
  const totalPages = query.data?.pages.length || 1

  const fetchNextPage = () => {
    if (currentPageIndex < totalPages - 1) {
      // Move to next cached page
      setCurrentPageIndex(currentPageIndex + 1)
    } else if (query.hasNextPage) {
      // Fetch new page and move to it
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
      // Page is already cached, navigate directly
      setCurrentPageIndex(targetIndex)
    } else if (targetIndex === totalPages && query.hasNextPage) {
      // Need to fetch the next page
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
  }
}
