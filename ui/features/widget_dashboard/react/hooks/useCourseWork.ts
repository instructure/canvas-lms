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
import {gql} from 'graphql-tag'
import {useState, useCallback, useEffect, useRef} from 'react'
import {getCurrentUserId, executeGraphQLQuery, createUserQueryConfig} from '../utils/graphql'
import {COURSE_WORK_KEY, QUERY_CONFIG} from '../constants'
import {useWidgetDashboard} from './useWidgetDashboardContext'

export interface CourseWorkItem {
  id: string
  title: string
  course: {
    id: string
    name: string
  }
  dueAt: string | null
  points: number | null
  htmlUrl: string
  type: 'assignment' | 'quiz' | 'discussion'
  late: boolean
  missing: boolean
  state: string
}

interface Submission {
  _id: string
  cachedDueDate?: string | null
  submittedAt?: string | null
  late?: boolean
  missing?: boolean
  excused?: boolean
  state?: string
  assignment: Assignment
}

interface Assignment {
  _id: string
  name: string
  dueAt?: string | null
  pointsPossible?: number | null
  htmlUrl: string
  submissionTypes: string[]
  state: string
  published: boolean
  quiz?: {
    _id: string
    title: string
  } | null
  discussion?: {
    _id: string
    title: string
  } | null
  course: {
    _id: string
    name: string
  }
}

interface PageInfo {
  hasNextPage: boolean
  hasPreviousPage: boolean
  endCursor: string | null
  startCursor: string | null
  totalCount: number | null
}

interface GraphQLResponse {
  legacyNode: {
    _id: string
    courseWorkSubmissionsConnection: {
      nodes: Submission[]
      pageInfo: PageInfo
    }
  }
}

const USER_COURSE_WORK_QUERY = gql`
  query GetUserCourseWork($userId: ID!, $first: Int, $after: String, $last: Int, $before: String, $courseFilter: String, $startDate: ISO8601DateTime, $endDate: ISO8601DateTime, $includeOverdue: Boolean, $includeNoDueDate: Boolean, $onlySubmitted: Boolean, $observedUserId: ID) {
    legacyNode(_id: $userId, type: User) {
      ... on User {
        _id
        courseWorkSubmissionsConnection(
          first: $first
          after: $after
          last: $last
          before: $before
          courseFilter: $courseFilter
          startDate: $startDate
          endDate: $endDate
          includeOverdue: $includeOverdue
          includeNoDueDate: $includeNoDueDate
          onlySubmitted: $onlySubmitted
          observedUserId: $observedUserId
        ) {
          nodes {
            _id
            cachedDueDate
            submittedAt
            late
            missing
            excused
            state
            assignment {
              _id
              name
              dueAt
              pointsPossible
              htmlUrl
              submissionTypes
              state
              published
              quiz {
                _id
                title
              }
              discussion {
                _id
                title
              }
              course {
                _id
                name
              }
            }
          }
          pageInfo {
            hasNextPage
            hasPreviousPage
            endCursor
            startCursor
            totalCount
          }
        }
      }
    }
  }
`

function determineItemType(assignment: Assignment): CourseWorkItem['type'] {
  // Check for actual quiz/discussion objects first (more reliable)
  if (assignment.quiz) {
    return 'quiz'
  }
  if (assignment.discussion) {
    return 'discussion'
  }

  // Fallback to submission types
  if (assignment.submissionTypes?.includes('online_quiz')) {
    return 'quiz'
  }
  if (assignment.submissionTypes?.includes('discussion_topic')) {
    return 'discussion'
  }
  return 'assignment'
}

function getItemTitle(assignment: Assignment): string {
  // Use quiz/discussion title if available, otherwise use assignment name
  if (assignment.quiz) {
    return assignment.quiz.title
  }
  if (assignment.discussion) {
    return assignment.discussion.title
  }
  return assignment.name
}

export interface CourseWorkPaginationInfo {
  hasNextPage: boolean
  hasPreviousPage: boolean
  endCursor: string | null
  startCursor: string | null
  totalCount: number | null
}

export interface CourseWorkResult {
  items: CourseWorkItem[]
  pageInfo: CourseWorkPaginationInfo
}

export interface UseCourseWorkOptions {
  pageSize?: number
  courseFilter?: string
  startDate?: string
  endDate?: string
  includeOverdue?: boolean
  includeNoDueDate?: boolean
  onlySubmitted?: boolean
}

type PaginationParams =
  | {
      first: number
      after?: string
    }
  | {
      last: number
      before?: string
    }

/**
 * Calculate a GraphQL cursor for a specific page
 * Cursor represents the starting offset for the page (0-indexed position)
 */
export function calculateCursorForPage(pageIndex: number, pageSize: number): string | undefined {
  if (pageIndex === 0) return undefined
  const offset = pageIndex * pageSize
  return btoa(String(offset))
}

/**
 * Fetch a specific page of course work directly by calculating its cursor
 */
export async function fetchCourseWorkPage(
  pageIndex: number,
  options: UseCourseWorkOptions = {},
  observedUserId?: string | null,
): Promise<CourseWorkResult> {
  const {
    pageSize = 4,
    courseFilter,
    startDate,
    endDate,
    includeOverdue,
    includeNoDueDate,
    onlySubmitted,
  } = options

  const currentUserId = getCurrentUserId()
  const cursor = calculateCursorForPage(pageIndex, pageSize)

  const response = await executeGraphQLQuery<GraphQLResponse>(USER_COURSE_WORK_QUERY, {
    userId: currentUserId,
    first: pageSize,
    after: cursor,
    courseFilter,
    startDate,
    endDate,
    includeOverdue,
    includeNoDueDate,
    onlySubmitted,
    observedUserId,
  })

  if (!response?.legacyNode?.courseWorkSubmissionsConnection) {
    return {
      items: [],
      pageInfo: {
        hasNextPage: false,
        hasPreviousPage: false,
        endCursor: null,
        startCursor: null,
        totalCount: null,
      },
    }
  }

  const {nodes: submissions, pageInfo} = response.legacyNode.courseWorkSubmissionsConnection

  const items: CourseWorkItem[] = submissions.map(submission => {
    const assignment = submission.assignment
    // Prioritize cachedDueDate for due date overrides before using assignment.dueAt
    const effectiveDueDate = submission.cachedDueDate || assignment.dueAt || null

    return {
      id: assignment._id,
      title: getItemTitle(assignment),
      course: {
        id: assignment.course._id,
        name: assignment.course.name,
      },
      dueAt: effectiveDueDate,
      points: assignment.pointsPossible || null,
      htmlUrl: assignment.htmlUrl,
      type: determineItemType(assignment),
      late: submission.late || false,
      missing: submission.missing || false,
      state: submission.state || 'not_submitted',
    }
  })

  return {
    items,
    pageInfo: {...pageInfo},
  }
}

/**
 * Original infinite query hook for sequential pagination
 * Used by widgets that load pages sequentially (e.g., CourseWorkSummaryWidget)
 */
export function useCourseWork(options: UseCourseWorkOptions = {}) {
  const {
    pageSize = 4,
    courseFilter,
    startDate,
    endDate,
    includeOverdue,
    includeNoDueDate,
    onlySubmitted,
  } = options

  const {observedUserId} = useWidgetDashboard()

  return useInfiniteQuery({
    ...createUserQueryConfig(
      [
        COURSE_WORK_KEY,
        pageSize,
        courseFilter,
        startDate,
        endDate,
        includeOverdue?.toString(),
        includeNoDueDate?.toString(),
        onlySubmitted?.toString(),
        observedUserId ?? undefined,
      ],
      QUERY_CONFIG.STALE_TIME.STATISTICS,
    ),
    initialPageParam: null,
    queryFn: async ({
      pageParam,
    }: {
      pageParam: PaginationParams | null
    }): Promise<CourseWorkResult> => {
      const currentUserId = getCurrentUserId()

      // Determine pagination parameters
      const paginationParams = pageParam || {first: pageSize}

      const response = await executeGraphQLQuery<GraphQLResponse>(USER_COURSE_WORK_QUERY, {
        userId: currentUserId,
        ...paginationParams,
        courseFilter,
        startDate,
        endDate,
        includeOverdue,
        includeNoDueDate,
        onlySubmitted,
        observedUserId,
      })

      if (!response?.legacyNode?.courseWorkSubmissionsConnection) {
        return {
          items: [],
          pageInfo: {
            hasNextPage: false,
            hasPreviousPage: false,
            endCursor: null,
            startCursor: null,
            totalCount: null,
          },
        }
      }

      const {nodes: submissions, pageInfo} = response.legacyNode.courseWorkSubmissionsConnection

      // Transform submissions to CourseWorkItems
      const items: CourseWorkItem[] = submissions.map(submission => {
        const assignment = submission.assignment
        // Prioritize cachedDueDate for due date overrides before using assignment.dueAt
        const effectiveDueDate = submission.cachedDueDate || assignment.dueAt || null

        return {
          id: assignment._id,
          title: getItemTitle(assignment),
          course: {
            id: assignment.course._id,
            name: assignment.course.name,
          },
          dueAt: effectiveDueDate,
          points: assignment.pointsPossible || null,
          htmlUrl: assignment.htmlUrl,
          type: determineItemType(assignment),
          late: submission.late || false,
          missing: submission.missing || false,
          state: submission.state || 'not_submitted',
        }
      })

      return {
        items,
        pageInfo: {
          hasNextPage: pageInfo.hasNextPage,
          hasPreviousPage: pageInfo.hasPreviousPage,
          endCursor: pageInfo.endCursor,
          startCursor: pageInfo.startCursor,
          totalCount: pageInfo.totalCount,
        },
      }
    },
    getNextPageParam: (lastPage): PaginationParams | null => {
      if (lastPage.pageInfo.hasNextPage && lastPage.pageInfo.endCursor) {
        return {
          first: pageSize,
          after: lastPage.pageInfo.endCursor,
        }
      }
      return null
    },
    getPreviousPageParam: (firstPage): PaginationParams | null => {
      if (firstPage.pageInfo.hasPreviousPage && firstPage.pageInfo.startCursor) {
        return {
          last: pageSize,
          before: firstPage.pageInfo.startCursor,
        }
      }
      return null
    },
  })
}

interface PageCache {
  [pageIndex: number]: CourseWorkResult
}

/**
 * Enhanced hook for direct page jumping with caching
 * Manages its own page state and provides navigation
 * Used by widgets that need to jump directly to any page (e.g., CourseWorkWidget, CourseWorkCombinedWidget)
 */
export function useCourseWorkPaginated(options: UseCourseWorkOptions = {}) {
  const {observedUserId} = useWidgetDashboard()
  const [currentPageIndex, setCurrentPageIndex] = useState<number>(0)
  const [pageCache, setPageCache] = useState<PageCache>({})
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<Error | null>(null)
  const [totalCount, setTotalCount] = useState<number | null>(null)
  const optionsRef = useRef(options)
  const isFetchingRef = useRef<{[key: number]: boolean}>({})

  useEffect(() => {
    optionsRef.current = options
  }, [options])

  const pageSize = options.pageSize || 4

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
        const result = await fetchCourseWorkPage(pageIndex, optionsRef.current, observedUserId)

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
    if (window.ENV?.current_user_id) {
      fetchPage(currentPageIndex)
    }
  }, [currentPageIndex, fetchPage])

  useEffect(() => {
    setPageCache({})
    setTotalCount(null)
    setCurrentPageIndex(0)
    isFetchingRef.current = {}
  }, [options.courseFilter, options.startDate, options.endDate, observedUserId])

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
