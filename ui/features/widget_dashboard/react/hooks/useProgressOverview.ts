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

import {useState, useCallback, useMemo} from 'react'
import {useQuery} from '@tanstack/react-query'
import {gql} from 'graphql-tag'
import {executeGraphQLQuery, createUserQueryConfig} from '../utils/graphql'
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

interface CourseWithStatistics {
  _id: string
  name: string
  courseCode: string
  submissionStatistics: SubmissionStatistics | null
}

interface GraphQLResponse {
  courses: CourseWithStatistics[]
}

const PROGRESS_OVERVIEW_QUERY = gql`
  query GetProgressOverview($courseIds: [ID!]!, $observedUserId: ID) {
    courses(ids: $courseIds) {
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
`

async function fetchProgressOverview(
  courseIds: string[],
  observedUserId?: string | null,
): Promise<CourseProgress[]> {
  if (courseIds.length === 0) {
    return []
  }

  const result = await executeGraphQLQuery<GraphQLResponse>(PROGRESS_OVERVIEW_QUERY, {
    courseIds,
    observedUserId,
  })

  if (!result.courses) {
    return []
  }

  return result.courses
    .filter(course => course.submissionStatistics !== null)
    .map(course => ({
      courseId: course._id,
      courseName: course.name,
      courseCode: course.courseCode,
      submittedAndGradedCount: course.submissionStatistics?.submittedAndGradedCount ?? 0,
      submittedNotGradedCount: course.submissionStatistics?.submittedNotGradedCount ?? 0,
      missingSubmissionsCount: course.submissionStatistics?.missingSubmissionsCount ?? 0,
      submissionsDueCount: course.submissionStatistics?.submissionsDueCount ?? 0,
    }))
}

export function useProgressOverview() {
  const {observedUserId, sharedCourseData} = useWidgetDashboard()

  const courseIds = sharedCourseData.map(course => course.courseId)
  const queryKey = [PROGRESS_OVERVIEW_KEY, observedUserId ?? undefined]

  const query = useQuery({
    ...createUserQueryConfig(queryKey, QUERY_CONFIG.STALE_TIME.STATISTICS),
    queryFn: () => fetchProgressOverview(courseIds, observedUserId),
    retry: QUERY_CONFIG.RETRY.DISABLED,
    persister: widgetDashboardPersister,
    refetchOnMount: false,
    enabled: courseIds.length > 0,
  })

  useBroadcastQuery({
    queryKey: [PROGRESS_OVERVIEW_KEY],
    broadcastChannel: 'widget-dashboard',
  })

  return query
}

export function useProgressOverviewPaginated() {
  const [currentPageIndex, setCurrentPageIndex] = useState<number>(0)
  const {observedUserId, sharedCourseData} = useWidgetDashboard()

  const pageSize = DEFAULT_PAGE_SIZE.PROGRESS_OVERVIEW
  const courseIds = sharedCourseData.map(course => course.courseId)

  const {
    data: allCourseStats,
    isLoading: isQueryLoading,
    error: queryError,
    refetch,
  } = useQuery({
    queryKey: [PROGRESS_OVERVIEW_KEY, observedUserId ?? undefined],
    queryFn: () => fetchProgressOverview(courseIds, observedUserId),
    enabled: courseIds.length > 0,
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
  const isLoading = isQueryLoading && !allCourseStats

  // Client-side pagination
  const paginatedData = useMemo(() => {
    if (!allCourseStats) return []
    const start = currentPageIndex * pageSize
    return allCourseStats.slice(start, start + pageSize)
  }, [allCourseStats, currentPageIndex, pageSize])

  const totalCount = allCourseStats?.length ?? 0
  const totalPages = Math.ceil(totalCount / pageSize)

  const resetAndRefetch = useCallback(() => {
    setCurrentPageIndex(0)
    refetch()
  }, [refetch])

  const goToPage = useCallback(
    (pageNumber: number) => {
      const targetIndex = pageNumber - 1
      if (targetIndex >= 0 && targetIndex < totalPages) {
        setCurrentPageIndex(targetIndex)
      }
    },
    [totalPages],
  )

  const resetPagination = useCallback(() => {
    setCurrentPageIndex(0)
  }, [])

  return {
    data: paginatedData,
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
