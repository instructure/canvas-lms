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
import {useScope as createI18nScope} from '@canvas/i18n'
import {executeQuery} from '@canvas/graphql'
import {gql} from 'graphql-tag'
import type {CourseOption} from '../types'

const I18n = createI18nScope('widget_dashboard')

interface UserEnrollment {
  course: {
    _id: string
    name: string
  }
}

interface GraphQLResponse {
  legacyNode?: {
    _id: string
    enrollments: UserEnrollment[]
  } | null
  errors?: {message: string}[]
}

const USER_COURSES_QUERY = gql`
  query GetUserCourses($userId: ID!) {
    legacyNode(_id: $userId, type: User) {
      ... on User {
        _id
        enrollments {
          course {
            _id
            name
          }
        }
      }
    }
  }
`

export function useUserCourses() {
  const currentUserId = window.ENV?.current_user_id

  return useQuery({
    queryKey: ['userCourses', currentUserId],
    queryFn: async (): Promise<CourseOption[]> => {
      if (!currentUserId) {
        throw new Error('No current user ID found - please ensure you are logged in')
      }

      const result = await executeQuery<GraphQLResponse>(USER_COURSES_QUERY, {
        userId: currentUserId,
      })

      if (result.errors) {
        throw new Error(
          `GraphQL query failed: ${result.errors.map((err: {message: string}) => err.message).join(', ')}`,
        )
      }

      if (!result.legacyNode?.enrollments) {
        return []
      }

      return result.legacyNode.enrollments.map(enrollment => ({
        id: enrollment.course._id,
        name: enrollment.course.name,
      }))
    },
    staleTime: 10 * 60 * 1000, // 10 minutes - courses don't change frequently
    refetchOnWindowFocus: false,
    enabled: !!currentUserId,
  })
}
