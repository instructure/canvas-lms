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
import {useQuery as nativeUseQuery, hashQueryKey, QueryClient} from '@tanstack/react-query'
import type {UseQueryOptions, QueryKey} from '@tanstack/react-query'
import {PersistQueryClientProvider} from '@tanstack/react-query-persist-client'
import {createSyncStoragePersister} from '@tanstack/query-sync-storage-persister'
import wasPageReloaded from '@canvas/util/wasPageReloaded'

const CACHE_KEY = 'REACT_QUERY_OFFLINE_CACHE'

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false,
      refetchOnMount: false,
      refetchOnReconnect: false,
      retry: false,
      staleTime: 1000 * 60 * 60 * 24, // 1 day,
      cacheTime: 1000 * 60 * 60 * 24,
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

interface CustomUseQueryOptions<TData, TError> extends UseQueryOptions<TData, TError> {
  fetchAtLeastOnce?: boolean
  queryKey?: QueryKey
}

export function useQuery<TData = unknown, TError = unknown>(
  options: CustomUseQueryOptions<TData, TError>
) {
  const ensureFetch = options.fetchAtLeastOnce || wasPageReloaded
  const wasAlreadyFetched = queriesFetched.has(hashQueryKey(options.queryKey || []))

  queriesFetched.add(hashQueryKey(options.queryKey || []))

  const refetchOnMount = ensureFetch && !wasAlreadyFetched ? 'always' : options.refetchOnMount

  const mergedOptions: CustomUseQueryOptions<TData, TError> = {
    refetchOnMount,
    ...options,
  }

  return nativeUseQuery<TData, TError>(mergedOptions)
}
