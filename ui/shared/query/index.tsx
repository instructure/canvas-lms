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

import React from 'react'
import {
  useMutation as baseUseMutation,
  useQuery as baseUseQuery,
  hashQueryKey,
  QueryClient,
} from '@tanstack/react-query'
import type {
  UseQueryOptions,
  QueryKey,
  QueryFunction,
  UseMutationOptions,
} from '@tanstack/react-query'
import {PersistQueryClientProvider} from '@tanstack/react-query-persist-client'
import {createSyncStoragePersister} from '@tanstack/query-sync-storage-persister'
import wasPageReloaded from '@canvas/util/wasPageReloaded'
import {useBroadcastWhenFetched, useReception} from './utils'

const CACHE_KEY = 'QUERY_CACHE'
const CHANNEL_KEY = 'QUERY_CHANNEL'

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false,
      refetchOnMount: false,
      refetchOnReconnect: false,
      retry: false,
      staleTime: 1000 * 60 * 60 * 24, // 1 day,
      cacheTime: 1000 * 60 * 60 * 24 * 2, // 2 days,
    },
  },
})

export const persister = createSyncStoragePersister({
  key: CACHE_KEY,
  storage: sessionStorage,
})

export function QueryProvider({children}: {children: React.ReactNode}) {
  return (
    <PersistQueryClientProvider client={queryClient} persistOptions={{persister}}>
      {children}
    </PersistQueryClientProvider>
  )
}

const queriesFetched = new Set<string>()

window.BroadcastChannel =
  window.BroadcastChannel ||
  class BroadcastChannel {
    close() {}

    postMessage() {}

    addEventListener() {}

    removeEventListener() {}
  }

const broadcastChannel = new BroadcastChannel(CHANNEL_KEY)

interface CustomUseQueryOptions<
  TQueryFnData = unknown,
  TError = unknown,
  TData = TQueryFnData,
  TQueryKey extends QueryKey = QueryKey
> extends UseQueryOptions<TQueryFnData, TError, TData, TQueryKey> {
  fetchAtLeastOnce?: boolean
  broadcast?: boolean
}

export function useQuery<
  TQueryFnData = unknown,
  TError = unknown,
  TData = TQueryFnData,
  TQueryKey extends QueryKey = QueryKey
>(options: CustomUseQueryOptions<TQueryFnData, TError, TData, TQueryKey>) {
  const ensureFetch = options.fetchAtLeastOnce || wasPageReloaded
  const hashedKey = hashQueryKey(options.queryKey || [])
  const wasAlreadyFetched = queriesFetched.has(hashedKey)
  queriesFetched.add(hashQueryKey(options.queryKey || []))

  const refetchOnMount = ensureFetch && !wasAlreadyFetched ? 'always' : options.refetchOnMount

  // Handle incoming broadcasts
  useReception({
    hashedKey,
    queryKey: options.queryKey,
    queryClient,
    channel: broadcastChannel,
    enabled: options.broadcast,
  })

  const mergedOptions: CustomUseQueryOptions<TQueryFnData, TError, TData, TQueryKey> = {
    ...options,
    refetchOnMount,
  }
  const queryResult = baseUseQuery<TQueryFnData, TError, TData, TQueryKey>(mergedOptions)

  useBroadcastWhenFetched({
    hashedKey,
    queryResult,
    channel: broadcastChannel,
    enabled: options.broadcast,
  })

  return queryResult
}

export function useMutation(options: UseMutationOptions) {
  return baseUseMutation(options)
}

export function prefetchQuery(queryKey: QueryKey, queryFn: QueryFunction) {
  const hashedKey = hashQueryKey(queryKey || [])
  const wasAlreadyFetched = queriesFetched.has(hashedKey)

  if (
    !wasAlreadyFetched &&
    !queryClient.getQueryData(queryKey) &&
    !queryClient.isFetching(queryKey)
  ) {
    queriesFetched.add(hashQueryKey(queryKey || []))
    queryClient.prefetchQuery({
      queryKey,
      queryFn,
    })
  }
}
