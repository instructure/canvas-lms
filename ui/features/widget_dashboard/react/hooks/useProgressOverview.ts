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
import {useQuery} from '@tanstack/react-query'
import {gql} from 'graphql-tag'
import {getCurrentUserId, executeGraphQLQuery, createUserQueryConfig} from '../utils/graphql'
import {PROGRESS_OVERVIEW_KEY, QUERY_CONFIG} from '../constants'
import {useWidgetDashboard} from './useWidgetDashboardContext'
import {widgetDashboardPersister} from '../utils/persister'
import {useBroadcastQuery} from '@canvas/query/broadcast'
import {DEFAULT_PAGE_SIZE} from '../constants/pagination'

export interface CourseProgress {
  courseId: string
  courseName: string
  courseCode: string
  submittedAndGradedCount: number
  submittedNotGradedCount: number
  missingSubmissionsCount: number
  submissionsDueCount: number
}

interface SubmissionStatistics {
  submittedAndGradedCount: number
  submittedNotGradedCount: number
  missingSubmissionsCount: number
  submissionsDueCount: number
}

interface CourseEnrollment {
  course: {
    _id: string
    name: string
    courseCode: string
    submissionStatistics: SubmissionStatistics | null
  }
}

interface PageInfo {
  hasNextPage: boolean
  hasPreviousPage: boolean
  startCursor: string | null
  endCursor: string | null
  totalCount: number | null
}

interface GraphQLResponse {
  legacyNode: {
    _id: string
    enrollmentsConnection: {
      nodes: CourseEnrollment[]
      pageInfo: PageInfo
    }
  }
}

const USER_PROGRESS_OVERVIEW_QUERY = gql`
  query GetUserProgressOverview($userId: ID!, $observedUserId: ID, $first: Int, $after: String) {
    legacyNode(_id: $userId, type: User) {
      ... on User {
        _id
        enrollmentsConnection(currentOnly: true, first: $first, after: $after) {
          nodes {
            course {
              _id
              name
              courseCode
              submissionStatistics(observedUserId: $observedUserId) {
                submittedAndGradedCount
                submittedNotGradedCount
                missingSubmissionsCount
                submissionsDueCount
              }
            }
          }
          pageInfo {
            hasNextPage
            hasPreviousPage
            startCursor
            endCursor
            totalCount
          }
        }
      }
    }
  }
`

async function fetchProgressOverview(observedUserId?: string | null): Promise<CourseProgress[]> {
  try {
    const currentUserId = getCurrentUserId()

    const result = await executeGraphQLQuery<GraphQLResponse>(USER_PROGRESS_OVERVIEW_QUERY, {
      userId: currentUserId,
      observedUserId,
    })

    if (!result.legacyNode?.enrollmentsConnection?.nodes) {
      return []
    }

    return result.legacyNode.enrollmentsConnection.nodes
      .filter(enrollment => enrollment.course.submissionStatistics !== null)
      .map(enrollment => ({
        courseId: enrollment.course._id,
        courseName: enrollment.course.name,
        courseCode: enrollment.course.courseCode,
        submittedAndGradedCount:
          enrollment.course.submissionStatistics?.submittedAndGradedCount ?? 0,
        submittedNotGradedCount:
          enrollment.course.submissionStatistics?.submittedNotGradedCount ?? 0,
        missingSubmissionsCount:
          enrollment.course.submissionStatistics?.missingSubmissionsCount ?? 0,
        submissionsDueCount: enrollment.course.submissionStatistics?.submissionsDueCount ?? 0,
      }))
  } catch (error) {
    console.error('Failed to fetch progress overview:', error)
    throw error
  }
}

export function useProgressOverview() {
  const {observedUserId} = useWidgetDashboard()

  const queryKey = [PROGRESS_OVERVIEW_KEY, observedUserId ?? undefined]

  const query = useQuery({
    ...createUserQueryConfig(queryKey, QUERY_CONFIG.STALE_TIME.STATISTICS),
    queryFn: () => fetchProgressOverview(observedUserId),
    retry: QUERY_CONFIG.RETRY.DISABLED,
    persister: widgetDashboardPersister,
    refetchOnMount: false,
  })

  useBroadcastQuery({
    queryKey: [PROGRESS_OVERVIEW_KEY],
    broadcastChannel: 'widget-dashboard',
  })

  return query
}

function calculateCursorForPage(pageIndex: number, pageSize: number): string | undefined {
  if (pageIndex === 0) return undefined
  const offset = pageIndex * pageSize
  return btoa(String(offset))
}

interface ProgressOverviewPageInfo {
  hasNextPage: boolean
  hasPreviousPage: boolean
  endCursor: string | null
  startCursor: string | null
  totalCount: number | null
}

interface ProgressOverviewResult {
  courses: CourseProgress[]
  pageInfo: ProgressOverviewPageInfo
}

async function fetchProgressOverviewPage(
  pageIndex: number,
  pageSize: number,
  observedUserId?: string | null,
): Promise<ProgressOverviewResult> {
  const currentUserId = getCurrentUserId()
  if (!currentUserId) {
    return {
      courses: [],
      pageInfo: {
        hasNextPage: false,
        hasPreviousPage: false,
        endCursor: null,
        startCursor: null,
        totalCount: null,
      },
    }
  }

  const cursor = calculateCursorForPage(pageIndex, pageSize)

  const result = await executeGraphQLQuery<GraphQLResponse>(USER_PROGRESS_OVERVIEW_QUERY, {
    userId: currentUserId,
    first: pageSize,
    after: cursor,
    observedUserId,
  })

  if (!result.legacyNode?.enrollmentsConnection) {
    return {
      courses: [],
      pageInfo: {
        hasNextPage: false,
        hasPreviousPage: false,
        endCursor: null,
        startCursor: null,
        totalCount: null,
      },
    }
  }

  const connection = result.legacyNode.enrollmentsConnection

  const courses = connection.nodes
    .filter(enrollment => enrollment.course.submissionStatistics !== null)
    .map(enrollment => ({
      courseId: enrollment.course._id,
      courseName: enrollment.course.name,
      courseCode: enrollment.course.courseCode,
      submittedAndGradedCount: enrollment.course.submissionStatistics?.submittedAndGradedCount ?? 0,
      submittedNotGradedCount: enrollment.course.submissionStatistics?.submittedNotGradedCount ?? 0,
      missingSubmissionsCount: enrollment.course.submissionStatistics?.missingSubmissionsCount ?? 0,
      submissionsDueCount: enrollment.course.submissionStatistics?.submissionsDueCount ?? 0,
    }))

  return {
    courses,
    pageInfo: connection.pageInfo,
  }
}

export function useProgressOverviewPaginated() {
  const [currentPageIndex, setCurrentPageIndex] = useState<number>(0)
  const [totalCount, setTotalCount] = useState<number | null>(null)
  const {observedUserId} = useWidgetDashboard()
  const currentUserId = getCurrentUserId()

  const pageSize = DEFAULT_PAGE_SIZE.PROGRESS_OVERVIEW

  const {
    data: queryData,
    isLoading: isQueryLoading,
    error: queryError,
    refetch,
  } = useQuery({
    queryKey: [PROGRESS_OVERVIEW_KEY, observedUserId ?? undefined, currentPageIndex],
    queryFn: async () => {
      const result = await fetchProgressOverviewPage(currentPageIndex, pageSize, observedUserId)
      return result
    },
    enabled: !!currentUserId,
    staleTime: QUERY_CONFIG.STALE_TIME.STATISTICS,
    persister: widgetDashboardPersister,
    refetchOnMount: false,
    retry: QUERY_CONFIG.RETRY.DISABLED,
  })

  useBroadcastQuery({
    queryKey: [PROGRESS_OVERVIEW_KEY],
    broadcastChannel: 'widget-dashboard',
  })

  const error = queryError as Error | null
  const isLoading = isQueryLoading && !queryData

  useEffect(() => {
    if (queryData?.pageInfo.totalCount !== null && queryData?.pageInfo.totalCount !== undefined) {
      setTotalCount(queryData.pageInfo.totalCount)
    }
  }, [queryData])

  const resetAndRefetch = useCallback(() => {
    setTotalCount(null)
    setCurrentPageIndex(0)
    refetch()
  }, [refetch])

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

  return {
    data: queryData?.courses,
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
