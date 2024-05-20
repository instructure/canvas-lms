/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {useQuery, QueryClient, type QueryKey} from '@tanstack/react-query'

export function useReception({
  queryKey,
  hashedKey,
  queryClient,
  channel,
  enabled,
}: {
  queryKey?: QueryKey
  hashedKey: string
  queryClient: QueryClient
  channel: BroadcastChannel
  enabled?: boolean
}) {
  useEffect(() => {
    if (!enabled || !queryKey) return
    function handleChannelMessage(event: MessageEvent<{hashedKey: string; data: unknown}>) {
      if (queryKey && event.data.hashedKey === hashedKey) {
        queryClient.setQueryData(queryKey, event.data.data)
      }
    }

    channel.addEventListener('message', handleChannelMessage)

    return () => channel.removeEventListener('message', handleChannelMessage)
  }, [queryKey, hashedKey, enabled, channel, queryClient])
}

export function useBroadcastWhenFetched({
  queryResult,
  enabled,
  hashedKey,
  channel,
}: {
  hashedKey: string
  queryResult: ReturnType<typeof useQuery>
  channel: BroadcastChannel
  enabled?: boolean
}) {
  const {isSuccess, isFetching} = queryResult
  const [wasFetching, setWasFetching] = useState(isFetching)

  useEffect(() => {
    // If it was fetching and now it's not, and the fetch was successful
    if (wasFetching && !isFetching && isSuccess && enabled) {
      channel.postMessage({
        hashedKey,
        data: queryResult.data,
      })
    }
    setWasFetching(isFetching)
  }, [wasFetching, isFetching, isSuccess, enabled, hashedKey, channel, queryResult.data])
}
