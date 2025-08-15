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

import {useQuery} from '@tanstack/react-query'
import {gql} from 'graphql-tag'
import type {CourseWorkSummary} from '../types'
import {getCurrentUserId, executeGraphQLQuery, createUserQueryConfig} from '../utils/graphql'
import {QUERY_CONFIG} from '../constants'

interface SubmissionStatistics {
  submissionsDueCount: number
  missingSubmissionsCount: number
  submissionsSubmittedCount: number
}

interface UserEnrollment {
  course: {
    _id: string
    name: string
    submissionStatistics: SubmissionStatistics | null
  }
}

interface GraphQLResponse {
  legacyNode: {
    _id: string
    enrollments: UserEnrollment[]
  }
}

interface CourseWorkStatisticsParams {
  startDate: Date
  endDate: Date
  courseId?: string
}

const USER_COURSE_STATISTICS_QUERY = gql`
  query GetUserCourseStatistics($userId: ID!, $startDate: ISO8601DateTime!, $endDate: ISO8601DateTime!) {
    legacyNode(_id: $userId, type: User) {
      ... on User {
        _id
        enrollments {
          course {
            _id
            name
            submissionStatistics {
              submissionsDueCount(startDate: $startDate, endDate: $endDate)
              missingSubmissionsCount
              submissionsSubmittedCount
            }
          }
        }
      }
    }
  }
`

async function fetchAllCourseStatistics({
  startDate,
  endDate,
}: Omit<CourseWorkStatisticsParams, 'courseId'>): Promise<UserEnrollment[]> {
  try {
    const currentUserId = getCurrentUserId()

    const result = await executeGraphQLQuery<GraphQLResponse>(USER_COURSE_STATISTICS_QUERY, {
      userId: currentUserId,
      startDate: startDate.toISOString(),
      endDate: endDate.toISOString(),
    })

    if (!result.legacyNode?.enrollments) {
      // User has no enrollments - this is a valid state
      return []
    }

    return result.legacyNode.enrollments
  } catch (error) {
    console.error('Failed to fetch course statistics:', error)
    throw error
  }
}

function calculateSummaryFromEnrollments(
  enrollments: UserEnrollment[],
  courseId?: string,
): CourseWorkSummary {
  // Filter by specific course if courseId is provided
  const filteredEnrollments = courseId
    ? enrollments.filter(enrollment => enrollment.course._id === courseId)
    : enrollments

  // Sum up statistics from all relevant courses
  const summary = filteredEnrollments.reduce(
    (acc, enrollment) => {
      const stats = enrollment.course.submissionStatistics
      if (stats) {
        // All counts are date-filtered
        acc.due += stats.submissionsDueCount
        acc.missing += stats.missingSubmissionsCount
        acc.submitted += stats.submissionsSubmittedCount
      }
      return acc
    },
    {due: 0, missing: 0, submitted: 0},
  )

  return summary
}

export function useCourseWorkStatistics(params: CourseWorkStatisticsParams) {
  // Only include date range in query key, not courseId
  const queryKey = [
    'courseStatistics',
    params.startDate.toISOString(),
    params.endDate.toISOString(),
  ]

  return useQuery({
    ...createUserQueryConfig(queryKey, QUERY_CONFIG.STALE_TIME.STATISTICS),
    queryFn: () => fetchAllCourseStatistics({startDate: params.startDate, endDate: params.endDate}),
    retry: QUERY_CONFIG.RETRY.DISABLED, // Disable retry for tests
    select: (enrollments: UserEnrollment[]) => {
      // Calculate summary based on selected course
      return calculateSummaryFromEnrollments(enrollments, params.courseId)
    },
  })
}
