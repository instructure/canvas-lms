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
import {useScope as createI18nScope} from '@canvas/i18n'
import {getCurrentUserId, executeGraphQLQuery, createUserQueryConfig} from '../utils/graphql'
import {INBOX_MESSAGES_KEY, QUERY_CONFIG} from '../constants'
import {widgetDashboardPersister} from '../utils/persister'
import {useBroadcastQuery} from '@canvas/query/broadcast'
import type {InboxMessage} from '../types'

const I18n = createI18nScope('widget_dashboard')

export type InboxFilter = 'all' | 'unread'

interface UseInboxMessagesOptions {
  limit?: number
  filter?: InboxFilter
}

interface ConversationParticipantNode {
  conversation: {
    _id: string
    subject: string | null
    updatedAt: string
    conversationMessagesConnection: {
      nodes: Array<{
        _id: string
        body: string
        createdAt: string
        author: {
          _id: string
          name: string
          avatarUrl: string | null
        } | null
      }>
    }
    conversationParticipantsConnection: {
      nodes: Array<{
        user: {
          _id: string
          name: string
          avatarUrl: string | null
        } | null
      }>
    }
  }
  workflowState: string
}

interface GraphQLResponse {
  legacyNode?: {
    _id: string
    conversationsConnection: {
      nodes: ConversationParticipantNode[]
    }
  } | null
  errors?: {message: string}[]
}

const USER_CONVERSATIONS_QUERY = gql`
  query GetUserConversations($userId: ID!, $first: Int!, $scope: String) {
    legacyNode(_id: $userId, type: User) {
      ... on User {
        _id
        conversationsConnection(first: $first, scope: $scope) {
          nodes {
            conversation {
              _id
              subject
              updatedAt
              conversationMessagesConnection(first: 1) {
                nodes {
                  _id
                  body
                  createdAt
                  author {
                    _id
                    name
                    avatarUrl
                  }
                }
              }
              conversationParticipantsConnection {
                nodes {
                  user {
                    _id
                    name
                    avatarUrl
                  }
                }
              }
            }
            workflowState
          }
        }
      }
    }
  }
`

function stripHtmlTags(html: string): string {
  return html.replace(/<[^>]*>/g, '')
}

function truncateText(text: string, maxLength: number = 80): string {
  const stripped = stripHtmlTags(text)
  if (!stripped || stripped.length <= maxLength) return stripped
  return stripped.slice(0, maxLength).trim() + '...'
}

async function fetchInboxMessages(limit: number, filter: InboxFilter): Promise<InboxMessage[]> {
  try {
    const currentUserId = getCurrentUserId()
    const scope = filter === 'all' ? undefined : filter

    const result = await executeGraphQLQuery<GraphQLResponse>(USER_CONVERSATIONS_QUERY, {
      userId: currentUserId,
      first: limit,
      scope,
    })

    if (!result.legacyNode?.conversationsConnection) {
      return []
    }

    const conversations = result.legacyNode.conversationsConnection.nodes

    const messages: InboxMessage[] = conversations.map(participantNode => {
      const conversation = participantNode.conversation
      const lastMessage = conversation.conversationMessagesConnection.nodes[0]

      const otherParticipants = conversation.conversationParticipantsConnection.nodes
        .map(node => node.user)
        .filter(user => user !== null && user._id !== currentUserId)

      const sender = lastMessage?.author || otherParticipants[0]

      return {
        id: conversation._id,
        subject: conversation.subject || I18n.t('(No subject)'),
        lastMessageAt: lastMessage?.createdAt || conversation.updatedAt,
        messagePreview: lastMessage?.body ? truncateText(lastMessage.body, 80) : '',
        workflowState: participantNode.workflowState === 'unread' ? 'unread' : 'read',
        conversationUrl: `/conversations/${conversation._id}`,
        participants: sender
          ? [
              {
                id: sender._id,
                name: sender.name,
                avatarUrl: sender.avatarUrl || undefined,
              },
            ]
          : [],
      }
    })

    return messages
  } catch (error) {
    console.error('Failed to fetch inbox messages:', error)
    throw error
  }
}

export function useInboxMessages(options: UseInboxMessagesOptions = {}) {
  const {limit = 5, filter = 'unread'} = options

  const queryKey = [INBOX_MESSAGES_KEY, limit, filter]

  const query = useQuery({
    ...createUserQueryConfig(queryKey, QUERY_CONFIG.STALE_TIME.STATISTICS),
    queryFn: () => fetchInboxMessages(limit, filter),
    retry: QUERY_CONFIG.RETRY.DISABLED,
    persister: widgetDashboardPersister,
    refetchOnMount: false,
  })

  useBroadcastQuery({
    queryKey: [INBOX_MESSAGES_KEY],
    broadcastChannel: 'widget-dashboard',
  })

  return query
}
