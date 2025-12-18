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

import {useQuery, useQueryClient} from '@tanstack/react-query'
import {gql} from 'graphql-tag'
import {useState, useCallback, useMemo, useEffect} from 'react'
import {getCurrentUserId, executeGraphQLQuery} from '../utils/graphql'
import {QUERY_CONFIG} from '../constants'
import {useWidgetDashboard} from './useWidgetDashboardContext'
import {widgetDashboardPersister} from '../utils/persister'
import {useBroadcastQuery} from '@canvas/query/broadcast'
import type {RecentGradeSubmission} from '../types'

const RECENT_GRADES_KEY = 'recent-grades'

interface Submission {
  _id: string
  score: number | null
  grade: string | null
  submittedAt: string | null
  gradedAt: string | null
  state: string
  assignment: {
    _id: string
    name: string
    htmlUrl: string
    pointsPossible: number | null
    submissionTypes: string[]
    quiz: {_id: string; title: string} | null
    discussion: {_id: string; title: string} | null
    course: {
      _id: string
      name: string
      courseCode?: string
    }
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

const RECENT_GRADES_QUERY = gql`
  query GetRecentGrades(
    $userId: ID!
    $first: Int
    $after: String
    $courseFilter: String
    $observedUserId: ID
    $orderBy: CourseWorkSubmissionsOrderField
  ) {
    legacyNode(_id: $userId, type: User) {
      ... on User {
        _id
        courseWorkSubmissionsConnection(
          first: $first
          after: $after
          onlySubmitted: true
          courseFilter: $courseFilter
          observedUserId: $observedUserId
          orderBy: $orderBy
        ) {
          nodes {
            _id
            score
            grade
            submittedAt
            gradedAt
            state
            assignment {
              _id
              name
              htmlUrl
              pointsPossible
              submissionTypes
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
                courseCode
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

export interface RecentGradesPaginationInfo {
  hasNextPage: boolean
  hasPreviousPage: boolean
  endCursor: string | null
  startCursor: string | null
  totalCount: number | null
}

export interface RecentGradesResult {
  submissions: RecentGradeSubmission[]
  pageInfo: RecentGradesPaginationInfo
}

export interface UseRecentGradesOptions {
  pageSize?: number
  courseFilter?: string
}

export function calculateCursorForPage(pageIndex: number, pageSize: number): string | undefined {
  if (pageIndex === 0) return undefined
  const offset = pageIndex * pageSize
  return btoa(String(offset))
}

export async function fetchRecentGradesPage(
  pageIndex: number,
  options: UseRecentGradesOptions = {},
  observedUserId?: string | null,
): Promise<RecentGradesResult> {
  const {pageSize = 5, courseFilter} = options

  const currentUserId = getCurrentUserId()
  const cursor = calculateCursorForPage(pageIndex, pageSize)

  const response = await executeGraphQLQuery<GraphQLResponse>(RECENT_GRADES_QUERY, {
    userId: currentUserId,
    first: pageSize,
    after: cursor,
    courseFilter,
    observedUserId,
    orderBy: 'graded_at',
  })

  if (!response?.legacyNode?.courseWorkSubmissionsConnection) {
    return {
      submissions: [],
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

  const gradeSubmissions: RecentGradeSubmission[] = submissions.map(submission => ({
    _id: submission._id,
    submittedAt: submission.submittedAt,
    gradedAt: submission.gradedAt,
    score: submission.score,
    grade: submission.grade,
    state: submission.state,
    assignment: {
      _id: submission.assignment._id,
      name: submission.assignment.name,
      htmlUrl: submission.assignment.htmlUrl,
      pointsPossible: submission.assignment.pointsPossible,
      submissionTypes: submission.assignment.submissionTypes,
      quiz: submission.assignment.quiz,
      discussion: submission.assignment.discussion,
      course: {
        _id: submission.assignment.course._id,
        name: submission.assignment.course.name,
        courseCode: submission.assignment.course.courseCode,
      },
    },
  }))

  return {
    submissions: gradeSubmissions,
    pageInfo: {...pageInfo},
  }
}

export function useRecentGrades(options: UseRecentGradesOptions = {}) {
  const {observedUserId} = useWidgetDashboard()
  const queryClient = useQueryClient()
  const pageSize = options.pageSize || 5

  const filterKey = useMemo(
    () =>
      JSON.stringify({
        courseFilter: options.courseFilter,
        observedUserId,
      }),
    [options.courseFilter, observedUserId],
  )

  const [currentPageIndex, setCurrentPageIndex] = useState<number>(0)

  useEffect(() => {
    setCurrentPageIndex(0)
  }, [filterKey])

  const queryKey = [
    RECENT_GRADES_KEY,
    'page',
    currentPageIndex,
    pageSize,
    options.courseFilter,
    observedUserId ?? undefined,
  ]

  const {
    data: currentPage,
    isLoading,
    error,
    refetch: refetchCurrentPage,
  } = useQuery({
    queryKey,
    queryFn: () => fetchRecentGradesPage(currentPageIndex, options, observedUserId),
    enabled: !!window.ENV?.current_user_id,
    staleTime: QUERY_CONFIG.STALE_TIME.STATISTICS * 60 * 1000,
    persister: widgetDashboardPersister,
    refetchOnMount: false,
  })

  useBroadcastQuery({
    queryKey: [RECENT_GRADES_KEY],
    broadcastChannel: 'widget-dashboard',
  })

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
    await queryClient.invalidateQueries({
      queryKey: [RECENT_GRADES_KEY],
    })
    return refetchCurrentPage()
  }, [queryClient, refetchCurrentPage])

  return {
    currentPage,
    currentPageIndex,
    totalPages,
    totalCount,
    goToPage,
    resetPagination,
    refetch,
    isLoading,
    error: error as Error | null,
    pageSize,
  }
}
