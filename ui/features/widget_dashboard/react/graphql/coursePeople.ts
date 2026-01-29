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

import {gql} from '@apollo/client'
import {executeGraphQLQuery} from '../utils/graphql'
import type {CourseInstructorForComponent} from '../hooks/useCourseInstructors'

export const COURSE_INSTRUCTORS_PAGINATED_QUERY = gql`
  query GetCourseInstructorsPaginated($courseIds: [ID!]!, $first: Int, $after: String, $observedUserId: ID, $enrollmentTypes: [String!]) {
    courseInstructorsConnection(courseIds: $courseIds, first: $first, after: $after, observedUserId: $observedUserId, enrollmentTypes: $enrollmentTypes) {
      nodes {
        user {
          _id
          name
          sortableName
          shortName
          avatarUrl
          email
        }
        enrollments {
          course {
            _id
            name
            courseCode
          }
          type
          role {
            _id
            name
          }
          enrollmentState
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
`

export interface CourseInstructorsPaginatedResponse {
  courseInstructorsConnection: {
    nodes: Array<{
      user: {
        _id: string
        name: string
        sortableName?: string
        shortName?: string
        avatarUrl?: string
        email?: string
      }
      enrollments: Array<{
        course: {
          _id: string
          name: string
          courseCode?: string
        }
        type: 'TeacherEnrollment' | 'TaEnrollment'
        role: {
          _id: string
          name: string
        }
        enrollmentState: string
      }>
    }>
    pageInfo: {
      hasNextPage: boolean
      hasPreviousPage: boolean
      startCursor: string | null
      endCursor: string | null
      totalCount: number | null
    }
  }
}

export const fetchPaginatedCourseInstructors = async (
  courseIds: string[],
  limit: number = 5,
  after?: string,
  observedUserId?: string,
  enrollmentTypes?: string[],
): Promise<{
  data: CourseInstructorForComponent[]
  hasNextPage: boolean
  hasPreviousPage: boolean
  endCursor: string | null
  startCursor: string | null
  totalCount: number | null
}> => {
  const response = await executeGraphQLQuery<CourseInstructorsPaginatedResponse>(
    COURSE_INSTRUCTORS_PAGINATED_QUERY,
    {
      courseIds,
      first: limit,
      after,
      observedUserId,
      enrollmentTypes,
    },
  )

  if (!response?.courseInstructorsConnection) {
    console.error('Invalid response structure:', response)
    return {
      data: [],
      hasNextPage: false,
      hasPreviousPage: false,
      endCursor: null,
      startCursor: null,
      totalCount: null,
    }
  }

  const {nodes, pageInfo} = response.courseInstructorsConnection

  const instructors: CourseInstructorForComponent[] = nodes
    .filter(node => node.user?._id && node.enrollments.length > 0)
    .map(node => {
      const firstEnrollment = node.enrollments[0]
      return {
        id: node.user._id,
        name: node.user.name,
        sortable_name: node.user.sortableName,
        short_name: node.user.shortName,
        avatar_url: node.user.avatarUrl,
        email: node.user.email,
        bio: null,
        course_name: firstEnrollment.course.name,
        course_code: firstEnrollment.course.courseCode,
        enrollments: node.enrollments.map(enrollment => ({
          id: `${node.user._id}-${enrollment.course._id}`,
          user_id: node.user._id,
          course_id: enrollment.course._id,
          course_name: enrollment.course.name,
          course_code: enrollment.course.courseCode,
          type: enrollment.type,
          role: enrollment.role.name,
          role_id: enrollment.role._id,
          enrollment_state: enrollment.enrollmentState,
        })),
      }
    })

  return {
    data: instructors,
    hasNextPage: pageInfo.hasNextPage,
    hasPreviousPage: pageInfo.hasPreviousPage,
    endCursor: pageInfo.endCursor,
    startCursor: pageInfo.startCursor,
    totalCount: pageInfo.totalCount,
  }
}
