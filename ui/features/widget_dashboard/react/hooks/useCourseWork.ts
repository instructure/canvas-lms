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
import {getCurrentUserId, executeGraphQLQuery, createUserQueryConfig} from '../utils/graphql'
import {QUERY_CONFIG} from '../constants'
import {startOfToday} from '../utils/dateUtils'

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
  query GetUserCourseWork($userId: ID!, $first: Int, $after: String, $last: Int, $before: String, $courseFilter: String, $startDate: ISO8601DateTime, $endDate: ISO8601DateTime, $includeOverdue: Boolean, $includeNoDueDate: Boolean, $onlySubmitted: Boolean) {
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
}

export interface CourseWorkResult {
  items: CourseWorkItem[]
  pageInfo: CourseWorkPaginationInfo
}

interface UseCourseWorkOptions {
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

  return useInfiniteQuery({
    ...createUserQueryConfig(
      [
        'courseWork',
        pageSize,
        courseFilter,
        startDate,
        endDate,
        includeOverdue?.toString(),
        includeNoDueDate?.toString(),
        onlySubmitted?.toString(),
      ],
      QUERY_CONFIG.STALE_TIME.STATISTICS,
    ),
    initialPageParam: null,
    queryFn: async ({
      pageParam,
    }: {pageParam: PaginationParams | null}): Promise<CourseWorkResult> => {
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
      })

      if (!response?.legacyNode?.courseWorkSubmissionsConnection) {
        return {
          items: [],
          pageInfo: {
            hasNextPage: false,
            hasPreviousPage: false,
            endCursor: null,
            startCursor: null,
          },
        }
      }

      const {nodes: submissions, pageInfo} = response.legacyNode.courseWorkSubmissionsConnection

      // Transform submissions to CourseWorkItems
      const items: CourseWorkItem[] = submissions.map(submission => {
        const assignment = submission.assignment
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
        }
      })

      return {
        items,
        pageInfo: {
          hasNextPage: pageInfo.hasNextPage,
          hasPreviousPage: pageInfo.hasPreviousPage,
          endCursor: pageInfo.endCursor,
          startCursor: pageInfo.startCursor,
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
