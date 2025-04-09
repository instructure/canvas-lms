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

import {useEffect, useRef} from 'react'
import {useQueryClient, hashKey} from '@tanstack/react-query'

interface UseBroadcastQueryOptions {
  /**
   * The query key to synchronize across browser tabs.
   * This should be the same query key used in useQuery or similar hooks.
   */
  queryKey: unknown[]
  /**
   * Optional channel name for the BroadcastChannel.
   * Defaults to 'tanstack-query'.
   */
  broadcastChannel?: string
}

/**
 * Synchronizes TanStack Query cache across browser tabs for a specific query key.
 *
 * This hook enables real-time synchronization of query data between different tabs
 * of the same browser using the BroadcastChannel API. When a query is updated in one tab,
 * the changes will be reflected in all other tabs using this hook with the same query key.
 *
 * @example
 * ```tsx
 * function TodoList() {
 *   const todosQuery = useQuery({
 *     queryKey: ['todos'],
 *     queryFn: fetchTodos,
 *   })
 *
 *   useBroadcastQuery({
 *     queryKey: ['todos'],
 *   })
 *
 *   return (
 *     <div>
 *       {todosQuery.data?.map(todo => (
 *         <TodoItem key={todo.id} todo={todo} />
 *       ))}
 *     </div>
 *   )
 * }
 * ```
 *
 * @param options - Configuration options for the broadcast query
 * @returns void
 */
export function useBroadcastQuery({
  queryKey,
  broadcastChannel = 'tanstack-query',
}: UseBroadcastQueryOptions) {
  const queryClient = useQueryClient()
  const transactionRef = useRef(false)
  const channelRef = useRef<BroadcastChannel>()
  const queryKeyHash = hashKey(queryKey)

  useEffect(() => {
    const channel = new BroadcastChannel(broadcastChannel)
    channelRef.current = channel

    const qc = queryClient.getQueryCache()
    const tx = (cb: () => void) => {
      transactionRef.current = true
      cb()
      transactionRef.current = false
    }

    const unsubscribe = qc.subscribe(event => {
      if (transactionRef.current) return
      const {
        query: {queryHash, queryKey: eventQueryKey, state},
      } = event

      if (queryHash !== queryKeyHash) return

      if (event.type === 'updated' && event.action.type === 'success') {
        channel.postMessage({type: 'updated', queryHash, queryKey: eventQueryKey, state})
      }
      if (event.type === 'removed') {
        channel.postMessage({type: 'removed', queryHash, queryKey: eventQueryKey})
      }
    })

    channel.onmessage = event => {
      const action = event.data
      if (!action?.type) return
      if (action.queryHash !== queryKeyHash) return

      tx(() => {
        const {type, queryHash, state} = action
        const query = qc.get(queryHash)
        if (!query) return

        if (type === 'updated') {
          query.setState(state)
        } else if (type === 'removed') {
          qc.remove(query)
        }
      })
    }

    return () => {
      unsubscribe()
      channel.close()
    }
  }, [queryClient, broadcastChannel, queryKeyHash])
}
