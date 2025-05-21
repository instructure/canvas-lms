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

import {useEffect} from 'react'
import {QueryClient, useInfiniteQuery} from '@tanstack/react-query'
import type {QueryKey, UseInfiniteQueryOptions} from '@tanstack/react-query'
import wasPageReloaded from '@canvas/util/wasPageReloaded'
import {v4} from 'uuid'
import {experimental_createPersister} from '@tanstack/query-persist-client-core'

const ONE_DAY = 1000 * 60 * 60 * 24

if (wasPageReloaded || localStorage.cacheBuster === undefined) {
  localStorage.cacheBuster = v4()
}

export const sessionStoragePersister = experimental_createPersister({
  storage: window.sessionStorage,
  maxAge: ONE_DAY,
  buster: localStorage.cacheBuster,
})

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false,
      refetchOnReconnect: false,
      retry: false,
      staleTime: 0,
      gcTime: ONE_DAY * 2,
    },
  },
})

/**
 * @deprecated This hook is an anti-pattern and will be removed in a future release.
 * It fetches all pages of data at once, which can lead to performance issues with large datasets.
 *
 * Instead, use `useInfiniteQuery` directly with pagination controls that load data as needed
 *
 * @see https://tanstack.com/query/latest/docs/react/guides/infinite-queries
 */
export function useAllPages<
  TQueryFnData = unknown,
  TError = unknown,
  TData = TQueryFnData,
  TQueryKey extends QueryKey = QueryKey,
>(options: UseInfiniteQueryOptions<TQueryFnData, TError, TData, TQueryFnData, TQueryKey>) {
  if (process.env.NODE_ENV === 'development') {
    console.warn('useAllPages is not recommended and may be deprecated')
  }
  const queryResult = useInfiniteQuery<TQueryFnData, TError, TData, TQueryKey>(options)

  useEffect(() => {
    if (queryResult.hasNextPage && !queryResult.isFetchingNextPage) {
      queryResult.fetchNextPage({
        cancelRefetch: false,
      })
    }
    // it's already exhaustive
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [queryResult.hasNextPage, queryResult.isFetchingNextPage, queryResult.fetchNextPage])

  return queryResult
}
