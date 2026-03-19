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

import {useState, useCallback, useEffect, useRef} from 'react'
import {useInfiniteQuery, useQuery, useQueryClient, keepPreviousData} from '@tanstack/react-query'
import {executeQuery} from '@canvas/graphql'
import {gql} from 'graphql-tag'
import type {Announcement} from '../types'
import {ANNOUNCEMENTS_PAGINATED_KEY} from '../constants'
import {useWidgetDashboard} from './useWidgetDashboardContext'
import {widgetDashboardPersister} from '../utils/persister'
import {useBroadcastQuery} from '@canvas/query/broadcast'

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
        totalCount: number | null
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
            totalCount
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

function calculateCursorForPage(pageIndex: number, pageSize: number): string | undefined {
  if (pageIndex === 0) return undefined
  const offset = pageIndex * pageSize
  return btoa(String(offset))
}

interface AnnouncementPageInfo {
  hasNextPage: boolean
  hasPreviousPage: boolean
  endCursor: string | null
  startCursor: string | null
  totalCount: number | null
}

interface AnnouncementResult {
  announcements: Announcement[]
  pageInfo: AnnouncementPageInfo
}

async function fetchAnnouncementsPage(
  pageIndex: number,
  options: UseAnnouncementsOptions = {},
  observedUserId?: string | null,
): Promise<AnnouncementResult> {
  const {limit = 3, filter = 'all'} = options

  const currentUserId = window.ENV?.current_user_id
  if (!currentUserId) {
    return {
      announcements: [],
      pageInfo: {
        hasNextPage: false,
        hasPreviousPage: false,
        endCursor: null,
        startCursor: null,
        totalCount: null,
      },
    }
  }

  const cursor = calculateCursorForPage(pageIndex, limit)

  const result = await executeQuery<GraphQLResponse>(USER_ANNOUNCEMENTS_QUERY, {
    userId: currentUserId,
    first: limit,
    after: cursor,
    readState: filter,
    observedUserId,
  })

  if (result.errors) {
    throw new Error(
      `GraphQL query failed: ${result.errors.map((err: {message: string}) => err.message).join(', ')}`,
    )
  }

  if (!result.legacyNode?.discussionParticipantsConnection) {
    return {
      announcements: [],
      pageInfo: {
        hasNextPage: false,
        hasPreviousPage: false,
        endCursor: null,
        startCursor: null,
        totalCount: null,
      },
    }
  }

  const connection = result.legacyNode.discussionParticipantsConnection

  const announcements: Announcement[] = connection.nodes.map(participant => ({
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

  return {
    announcements,
    pageInfo: connection.pageInfo,
  }
}

interface PageCache {
  [pageIndex: number]: AnnouncementResult
}

export function useAnnouncementsPaginated(options: UseAnnouncementsOptions = {}) {
  const [currentPageIndex, setCurrentPageIndex] = useState<number>(0)
  const [pageCache, setPageCache] = useState<PageCache>({})
  const [totalCount, setTotalCount] = useState<number | null>(null)
  const optionsRef = useRef(options)
  const isFetchingRef = useRef<{[key: number]: boolean}>({})
  const {observedUserId} = useWidgetDashboard()
  const currentUserId = window.ENV?.current_user_id

  useEffect(() => {
    optionsRef.current = options
  }, [options])

  const {
    data: queryData,
    isLoading: isQueryLoading,
    isFetching,
    error: queryError,
    refetch,
  } = useQuery({
    queryKey: [
      ANNOUNCEMENTS_PAGINATED_KEY,
      currentUserId,
      options.limit,
      options.filter,
      observedUserId,
      currentPageIndex,
    ],
    queryFn: async () => {
      const result = await fetchAnnouncementsPage(currentPageIndex, options, observedUserId)
      return result
    },
    enabled: !!currentUserId,
    staleTime: 5 * 60 * 1000,
    persister: widgetDashboardPersister,
    refetchOnMount: false,
    placeholderData: keepPreviousData,
  })

  // Broadcast announcement updates across tabs
  useBroadcastQuery({
    queryKey: [ANNOUNCEMENTS_PAGINATED_KEY],
    broadcastChannel: 'widget-dashboard',
  })

  const error = queryError as Error | null
  const isLoading = isFetching && !queryData
  const isPaginationLoading = isFetching && !!queryData

  useEffect(() => {
    if (queryData?.pageInfo.totalCount !== null && queryData?.pageInfo.totalCount !== undefined) {
      setTotalCount(queryData.pageInfo.totalCount)
    }
  }, [queryData])

  useEffect(() => {
    if (queryData) {
      setPageCache(prev => ({
        ...prev,
        [currentPageIndex]: queryData,
      }))
    }
  }, [queryData, currentPageIndex])

  useEffect(() => {
    setPageCache({})
    setCurrentPageIndex(0)
  }, [options.filter])

  const resetAndRefetch = useCallback(() => {
    setPageCache({})
    setTotalCount(null)
    setCurrentPageIndex(0)
    refetch()
  }, [refetch])

  const pageSize = options.limit || 3
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

  const currentPage = pageCache[currentPageIndex] || queryData

  return {
    currentPage,
    currentPageIndex,
    totalPages,
    totalCount,
    goToPage,
    resetPagination,
    refetch: resetAndRefetch,
    isLoading,
    isPaginationLoading,
    error,
    pageSize,
  }
}
