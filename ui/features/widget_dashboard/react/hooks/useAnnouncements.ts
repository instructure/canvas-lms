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
import {executeQuery} from '@canvas/graphql'
import {gql} from 'graphql-tag'
import type {Announcement} from '../types'
import {ANNOUNCEMENTS_PAGINATED_KEY} from '../constants'
import {useWidgetDashboard} from './useWidgetDashboardContext'

interface UseAnnouncementsOptions {
  limit?: number
  filter?: 'unread' | 'read' | 'all'
}

interface DiscussionParticipant {
  id: string
  read: boolean
  discussionTopic: {
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
  }
}

interface GraphQLResponse {
  legacyNode?: {
    _id: string
    discussionParticipantsConnection: {
      nodes: DiscussionParticipant[]
      pageInfo: {
        hasNextPage: boolean
        hasPreviousPage: boolean
        startCursor: string | null
        endCursor: string | null
      }
    }
  } | null
  errors?: {message: string}[]
}

const USER_ANNOUNCEMENTS_QUERY = gql`
  query GetUserAnnouncements($userId: ID!, $first: Int!, $after: String, $readState: String, $observedUserId: ID) {
    legacyNode(_id: $userId, type: User) {
      ... on User {
        _id
        discussionParticipantsConnection(first: $first, after: $after, filter: { isAnnouncement: true, readState: $readState }, observedUserId: $observedUserId) {
          nodes {
            id
            read
            discussionTopic {
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
            }
          }
          pageInfo {
            hasNextPage
            hasPreviousPage
            startCursor
            endCursor
          }
        }
      }
    }
  }
`

export function usePaginatedAnnouncements(options: UseAnnouncementsOptions = {}) {
  const {limit = 10, filter = 'all'} = options
  const currentUserId = window.ENV?.current_user_id
  const {observedUserId} = useWidgetDashboard()

  return useInfiniteQuery({
    queryKey: [ANNOUNCEMENTS_PAGINATED_KEY, currentUserId, limit, filter, observedUserId],
    queryFn: async ({pageParam}): Promise<{announcements: Announcement[]; pageInfo: any}> => {
      if (!currentUserId) {
        throw new Error('No current user ID found - please ensure you are logged in')
      }

      const result = await executeQuery<GraphQLResponse>(USER_ANNOUNCEMENTS_QUERY, {
        userId: currentUserId,
        first: limit,
        after: pageParam,
        readState: filter,
        observedUserId,
      })

      if (result.errors) {
        throw new Error(
          `GraphQL query failed: ${result.errors.map((err: {message: string}) => err.message).join(', ')}`,
        )
      }

      if (!result.legacyNode?.discussionParticipantsConnection) {
        return {announcements: [], pageInfo: null}
      }

      const connection = result.legacyNode.discussionParticipantsConnection

      const allAnnouncements: Announcement[] = connection.nodes.map(participant => ({
        id: participant.discussionTopic._id,
        title: participant.discussionTopic.title,
        message: participant.discussionTopic.message,
        posted_at: participant.discussionTopic.createdAt,
        html_url: `/courses/${participant.discussionTopic.contextId}/discussion_topics/${participant.discussionTopic._id}`,
        context_code: `course_${participant.discussionTopic.contextId}`,
        course: {
          id: participant.discussionTopic.contextId,
          name: participant.discussionTopic.contextName,
        },
        author: participant.discussionTopic.author,
        isRead: participant.read,
      }))

      return {announcements: allAnnouncements, pageInfo: connection.pageInfo}
    },
    initialPageParam: undefined,
    getNextPageParam: lastPage =>
      lastPage.pageInfo?.hasNextPage ? lastPage.pageInfo.endCursor : undefined,
    getPreviousPageParam: firstPage =>
      firstPage.pageInfo?.hasPreviousPage ? firstPage.pageInfo.startCursor : undefined,
    staleTime: 5 * 60 * 1000,
    refetchOnWindowFocus: false,
    retry: false,
    enabled: !!currentUserId,
  })
}
