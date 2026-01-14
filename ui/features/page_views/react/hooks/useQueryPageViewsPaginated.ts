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

import {useState, useEffect} from 'react'
import {useQuery, keepPreviousData} from '@tanstack/react-query'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {
  type APIPageView,
  type PageView,
  formatURL,
  formatInteractionTime,
  formatParticipated,
  formatUserAgent,
} from '../utils'

const CACHE_STALE_TIME = 10 * 60 * 1000 // 10 minutes

interface UseQueryPageViewsPaginatedOptions {
  userId: string
  startDate?: Date
  endDate?: Date
  pageSize: number
}

export function useQueryPageViewsPaginated(options: UseQueryPageViewsPaginatedOptions) {
  const [currentPage, setCurrentPage] = useState(1)
  const [pageBookmarks, setPageBookmarks] = useState<Record<number, string>>({})
  const [maxDiscoveredPage, setMaxDiscoveredPage] = useState(1)
  const [hasReachedEnd, setHasReachedEnd] = useState(false)

  const query = useQuery({
    queryKey: [
      'page_views',
      options.userId,
      currentPage,
      options.startDate,
      options.endDate,
      options.pageSize,
    ],
    queryFn: async () => {
      // Build API request
      const bookmark = pageBookmarks[currentPage]
      const params = {
        page: bookmark || '1',
        per_page: options.pageSize.toString(),
        ...(options.startDate && {
          start_time: options.startDate.toISOString(),
          end_time: options.endDate?.toISOString(),
        }),
      }

      if (options.startDate && !options.endDate) {
        throw new RangeError('endDate must be set if startDate is set')
      }

      // Fetch data
      const path = `/api/v1/users/${options.userId}/page_views`
      const {json, link} = await doFetchApi<Array<APIPageView>>({path, params})

      if (typeof json === 'undefined') return {views: []}

      // Transform API data
      const views: Array<PageView> = json.map(v => ({
        id: v.id,
        url: formatURL(v),
        createdAt: new Date(v.created_at),
        participated: formatParticipated(v),
        interactionSeconds: formatInteractionTime(v),
        rawUserAgentString: v.user_agent,
        userAgent: formatUserAgent(v),
      }))

      // Extract next bookmark
      const nextBookmark = link?.next
        ? new URL(link.next.url).searchParams.get('page') || undefined
        : undefined

      // Store next page bookmark and update pagination state
      if (nextBookmark) {
        const nextPageNumber = currentPage + 1
        setPageBookmarks(prev => ({...prev, [nextPageNumber]: nextBookmark}))
        setMaxDiscoveredPage(prev => Math.max(prev, nextPageNumber))
      }

      return {views, nextBookmark}
    },
    staleTime: CACHE_STALE_TIME,
    placeholderData: keepPreviousData, // Smooth transitions between pages
  })

  // handle empty page if user navigates beyond available data
  useEffect(() => {
    if (query.isSuccess && query.data?.views.length === 0 && currentPage > 1) {
      setCurrentPage(currentPage - 1)
      setMaxDiscoveredPage(currentPage - 1)
      setHasReachedEnd(true)
    }
  }, [query.isSuccess, query.data?.views.length, currentPage])

  return {
    // Data and loading states
    views: query.data?.views || [],
    isFetching: query.isFetching,
    isSuccess: query.isSuccess,
    error: query.error,

    // Pagination state and controls
    currentPage,
    totalPages: hasReachedEnd ? maxDiscoveredPage : Math.max(maxDiscoveredPage, currentPage + 1),
    hasReachedEnd,
    setCurrentPage,
  }
}
