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

import {useState, useCallback} from 'react'
import {useLazyQuery} from '@apollo/client'
import type {
  DocumentNode,
  OperationVariables,
  ApolloError,
  LazyQueryHookOptions,
} from '@apollo/client'

/**
 * Hook for fetching all pages of an Apollo GraphQL query triggered by user action (e.g., button click).
 *
 * Uses Apollo's built-in pagination with fetchMore and field policies for automatic cache merging.
 * Requires a field policy to be configured in the Apollo cache for the paginated field.
 *
 * @example
 * ```typescript
 * // 1. Configure field policy in Apollo cache (ui/shared/apollo-v3/index.js):
 * // User: {
 * //   fields: {
 * //     recipientsObservers: {
 * //       keyArgs: ['contextCode', 'recipientIds'],
 * //       merge(existing, incoming, {args}) {
 * //         if (args?.after && existing) {
 * //           return {...incoming, nodes: [...existing.nodes, ...incoming.nodes]}
 * //         }
 * //         return incoming
 * //       }
 * //     }
 * //   }
 * // }
 *
 * // 2. Use the hook:
 * const [fetchAllObservers, { data, loading, error }] = useFetchAllPages(
 *   RECIPIENTS_OBSERVERS_QUERY,
 *   {
 *     getPageInfo: (data) => data?.legacyNode?.recipientsObservers?.pageInfo,
 *   }
 * )
 *
 * // 3. Trigger from button:
 * <Button onClick={() => fetchAllObservers({ variables: {...} })} disabled={loading}>
 *   Include Observers
 * </Button>
 * ```
 */
export function useFetchAllPages<
  TData = any,
  TVariables extends OperationVariables = OperationVariables,
>(
  query: DocumentNode,
  options: {
    /**
     * Function to extract pageInfo from the query result
     * Should return an object with { hasNextPage: boolean, endCursor: string | null }
     */
    getPageInfo: (data: TData) => {hasNextPage: boolean; endCursor: string | null} | undefined
    /**
     * Optional Apollo client options
     */
    apolloOptions?: LazyQueryHookOptions<TData, TVariables>
  },
) {
  const [executeQuery, {data, loading: queryLoading, error: apolloError, fetchMore}] = useLazyQuery<
    TData,
    TVariables
  >(query, options.apolloOptions)

  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<ApolloError | undefined>(undefined)

  const fetchAll = useCallback(
    async (executeOptions?: {variables?: TVariables}) => {
      setLoading(true)
      setError(undefined)

      try {
        // Execute initial query
        const result = await executeQuery({
          ...executeOptions,
          variables: {
            ...executeOptions?.variables,
            after: null,
          } as unknown as TVariables,
        })

        if (result.error) {
          throw result.error
        }

        if (!result.data) {
          throw new Error('No data returned from query')
        }

        let pageInfo = options.getPageInfo(result.data as TData)

        if (!pageInfo) {
          throw new Error('Could not extract pageInfo from query result')
        }

        // Fetch remaining pages using fetchMore
        // Apollo automatically merges the results using the field policy
        while (pageInfo.hasNextPage && fetchMore) {
          const moreResult = await fetchMore({
            variables: {
              after: pageInfo.endCursor,
            } as unknown as Partial<TVariables>,
          })

          if (!moreResult.data) {
            throw new Error('No data returned from fetchMore')
          }

          pageInfo = options.getPageInfo(moreResult.data as TData)

          if (!pageInfo) {
            throw new Error('Could not extract pageInfo from fetchMore result')
          }
        }
      } catch (err) {
        setError(err as ApolloError)
      } finally {
        setLoading(false)
      }
    },
    [executeQuery, fetchMore, options],
  )

  return [fetchAll, {data, loading: loading || queryLoading, error: error || apolloError}] as const
}
