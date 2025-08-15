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
import {executeQuery} from '@canvas/graphql'
import {gql} from 'graphql-tag'
import type {Announcement} from '../types'

interface UseAnnouncementsOptions {
  limit?: number
}

interface CourseAnnouncement {
  _id: string
  title: string
  message: string
  createdAt: string
  contextName: string
  contextId: string
  isAnnouncement: boolean
  author: {
    _id: string
    name: string
    avatarUrl: string
  } | null
  participant: {
    id: string
    read: boolean
  } | null
}

interface UserEnrollment {
  course: {
    _id: string
    name: string
    courseCode: string
    discussionsConnection: {
      nodes: CourseAnnouncement[]
    }
  }
}

interface GraphQLResponse {
  legacyNode?: {
    _id: string
    enrollments: UserEnrollment[]
  } | null
  errors?: {message: string}[]
}

const USER_ANNOUNCEMENTS_QUERY = gql`
  query GetUserAnnouncements($userId: ID!, $first: Int!) {
    legacyNode(_id: $userId, type: User) {
      ... on User {
        _id
        enrollments {
          course {
            _id
            name
            courseCode
            discussionsConnection(first: $first, filter: { isAnnouncement: true }) {
              nodes {
                _id
                title
                message
                createdAt
                contextName
                contextId
                isAnnouncement
                author {
                  _id
                  name
                  avatarUrl
                }
                participant {
                  id
                  read
                }
              }
            }
          }
        }
      }
    }
  }
`

export function useAnnouncements(options: UseAnnouncementsOptions = {}) {
  const {limit = 10} = options
  const currentUserId = window.ENV?.current_user_id

  return useQuery({
    queryKey: ['announcements', currentUserId, limit],
    queryFn: async (): Promise<Announcement[]> => {
      if (!currentUserId) {
        throw new Error('No current user ID found - please ensure you are logged in')
      }

      const result = await executeQuery<GraphQLResponse>(USER_ANNOUNCEMENTS_QUERY, {
        userId: currentUserId,
        first: limit,
      })

      if (result.errors) {
        throw new Error(
          `GraphQL query failed: ${result.errors.map((err: {message: string}) => err.message).join(', ')}`,
        )
      }

      if (!result.legacyNode?.enrollments) {
        return []
      }

      // Flatten announcements from all courses - GraphQL API handles all permission filtering
      const allAnnouncements: Announcement[] = result.legacyNode.enrollments
        .flatMap(enrollment =>
          enrollment.course.discussionsConnection.nodes.map(announcement => ({
            id: announcement._id,
            title: announcement.title,
            message: announcement.message,
            posted_at: announcement.createdAt,
            html_url: `/courses/${enrollment.course._id}/discussion_topics/${announcement._id}`,
            context_code: `course_${announcement.contextId}`,
            course: {
              id: enrollment.course._id,
              name: enrollment.course.name,
              courseCode: enrollment.course.courseCode,
            },
            author: announcement.author,
            isRead: announcement.participant?.read ?? false, // Check actual read state from participant
          })),
        )
        .sort((a, b) => new Date(b.posted_at).getTime() - new Date(a.posted_at).getTime())
        .slice(0, limit)

      return allAnnouncements
    },
    staleTime: 5 * 60 * 1000, // 5 minutes
    refetchOnWindowFocus: false,
    retry: false,
    enabled: !!currentUserId,
  })
}
