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
  submissionsConnection: {
    nodes: {
      _id?: string
      cachedDueDate?: string | null
      submittedAt?: string | null
      late?: boolean
      missing?: boolean
      excused?: boolean
      state?: string
    }[]
  }
}

interface Course {
  _id: string
  name: string
  assignmentsConnection: {
    nodes: Assignment[]
  }
}

interface UserEnrollment {
  course: Course
}

interface GraphQLResponse {
  legacyNode: {
    _id: string
    enrollments: UserEnrollment[]
  }
}

const USER_COURSE_WORK_QUERY = gql`
  query GetUserCourseWork($userId: ID!) {
    legacyNode(_id: $userId, type: User) {
      ... on User {
        _id
        enrollments {
          course {
            _id
            name
            assignmentsConnection(
              first: 50
            ) {
              nodes {
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
                submissionsConnection(
                  first: 1
                  filter: { userId: $userId }
                ) {
                  nodes {
                    _id
                    cachedDueDate
                    submittedAt
                    late
                    missing
                    excused
                    state
                  }
                }
              }
            }
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

export function useCourseWork() {
  return useQuery({
    ...createUserQueryConfig(['courseWork'], QUERY_CONFIG.STALE_TIME.STATISTICS),
    queryFn: async (): Promise<CourseWorkItem[]> => {
      const currentUserId = getCurrentUserId()

      const response = await executeGraphQLQuery<GraphQLResponse>(USER_COURSE_WORK_QUERY, {
        userId: currentUserId,
      })

      if (!response?.legacyNode?.enrollments) {
        return []
      }

      const allItems: CourseWorkItem[] = []

      response.legacyNode.enrollments.forEach(enrollment => {
        const course = enrollment.course

        course.assignmentsConnection.nodes
          .filter(assignment => {
            const submission = assignment.submissionsConnection?.nodes?.[0]
            const due = submission?.cachedDueDate ? new Date(submission.cachedDueDate) : null
            const today = startOfToday()

            return (
              assignment.published &&
              !(submission?.submittedAt || submission?.excused) &&
              (!due || due >= today)
            )
          })
          .forEach(assignment => {
            const submission = assignment.submissionsConnection.nodes[0]
            const cachedDueDate = submission?.cachedDueDate
            const effectiveDueDate = cachedDueDate || assignment.dueAt || null

            allItems.push({
              id: assignment._id,
              title: getItemTitle(assignment),
              course: {
                id: course._id,
                name: course.name,
              },
              dueAt: effectiveDueDate,
              points: assignment.pointsPossible || null,
              htmlUrl: assignment.htmlUrl,
              type: determineItemType(assignment),
            })
          })
      })

      // Sort by due date (soonest first, null dates last)
      return allItems.sort((a, b) => {
        if (a.dueAt === null && b.dueAt === null) return 0
        if (a.dueAt === null) return 1
        if (b.dueAt === null) return -1
        return new Date(a.dueAt).getTime() - new Date(b.dueAt).getTime()
      })
    },
  })
}
