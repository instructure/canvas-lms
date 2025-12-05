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
import {getCurrentUserId, executeGraphQLQuery, createUserQueryConfig} from '../utils/graphql'
import {PROGRESS_OVERVIEW_KEY, QUERY_CONFIG} from '../constants'
import {useWidgetDashboard} from './useWidgetDashboardContext'
import {widgetDashboardPersister} from '../utils/persister'
import {useBroadcastQuery} from '@canvas/query/broadcast'

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

interface GraphQLResponse {
  legacyNode: {
    _id: string
    enrollmentsConnection: {
      nodes: CourseEnrollment[]
    }
  }
}

const USER_PROGRESS_OVERVIEW_QUERY = gql`
  query GetUserProgressOverview($userId: ID!, $observedUserId: ID) {
    legacyNode(_id: $userId, type: User) {
      ... on User {
        _id
        enrollmentsConnection(currentOnly: true) {
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
