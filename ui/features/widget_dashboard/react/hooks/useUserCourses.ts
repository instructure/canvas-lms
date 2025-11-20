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
import type {GlobalEnv} from '@canvas/global/env/GlobalEnv.d'

declare const ENV: GlobalEnv & {
  SHARED_COURSE_DATA?: Array<{
    courseId: string
    gradingScheme: 'percentage' | Array<[string, number]>
  }>
}

interface UsePaginatedCoursesWithGradesOptions {
  limit?: number
  orderBy?: 'name' | 'code' | 'id' | 'updated'
  order?: 'asc' | 'desc'
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
    gradingStandard?: {
      data?: Array<{
        letterGrade: string
        baseValue: number
      }> | null
    } | null
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
              gradingStandard {
                data {
                  letterGrade
                  baseValue
                }
              }
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

  let gradingScheme: 'percentage' | Array<[string, number]>

  if (displayGradeString && enrollment.course.gradingStandard?.data) {
    gradingScheme = enrollment.course.gradingStandard.data.map(item => [
      item.letterGrade,
      item.baseValue,
    ])
  } else if (displayGradeString) {
    throw new Error(
      `Letter grading scheme detected for course ${enrollment.course.name} but no grading standard data available`,
    )
  } else {
    gradingScheme = 'percentage'
  }

  return {
    courseId: enrollment.course._id,
    courseCode: enrollment.course.courseCode || COURSE_GRADES_WIDGET.DEFAULT_COURSE_CODE,
    courseName: enrollment.course.name,
    currentGrade: displayGrade,
    gradingScheme,
    lastUpdated: enrollment.updatedAt ? new Date(enrollment.updatedAt) : null,
  }
}

export function usePaginatedCoursesWithGrades(
  options: UsePaginatedCoursesWithGradesOptions = {},
): UsePaginatedCoursesWithGradesResult {
  const {limit = COURSE_GRADES_WIDGET.MAX_GRID_ITEMS, orderBy, order = 'asc'} = options
  const [currentPageIndex, setCurrentPageIndex] = useState(0)

  const query = useInfiniteQuery({
    ...createUserQueryConfig(
      ['userCoursesWithGradesPaginated', limit, orderBy, order],
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
      let courseGrades = nodes.map(transformEnrollmentToCourseGrade)

      // Apply sorting if specified
      if (orderBy) {
        courseGrades = courseGrades.sort((a, b) => {
          let aValue: string | number | Date
          let bValue: string | number | Date

          switch (orderBy) {
            case 'name':
              aValue = a.courseName.toLowerCase()
              bValue = b.courseName.toLowerCase()
              break
            case 'code':
              aValue = a.courseCode.toLowerCase()
              bValue = b.courseCode.toLowerCase()
              break
            case 'id':
              aValue = a.courseId
              bValue = b.courseId
              break
            case 'updated':
              aValue = a.lastUpdated || new Date(0)
              bValue = b.lastUpdated || new Date(0)
              break
            default:
              return 0
          }

          if (aValue < bValue) return order === 'asc' ? -1 : 1
          if (aValue > bValue) return order === 'asc' ? 1 : -1
          return 0
        })
      }

      return {
        data: courseGrades,
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
