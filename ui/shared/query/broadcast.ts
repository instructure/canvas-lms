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

import {hashKey, useQueryClient} from '@tanstack/react-query'
import {useEffect, useRef} from 'react'

// window.BroadcastChannel =
//   window.BroadcastChannel ||
//   class BroadcastChannel {
//     close() {}

//     postMessage() {}

//     addEventListener() {}

//     removeEventListener() {}
//   }

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

// Keep track of active channels and their subscription counts
const activeChannels = new Map<
  string,
  {
    channel: BroadcastChannel | null
    count: number
  }
>()

type Message =
  | {type: 'updated'; queryHash: string; state: unknown}
  | {type: 'removed'; queryHash: string}

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
  const lastPostTimeRef = useRef<Record<string, number>>({})
  const queryKeyHash = hashKey(queryKey)

  useEffect(() => {
    const tx = (cb: () => void) => {
      transactionRef.current = true
      cb()
      transactionRef.current = false
    }

    let channelEntry = activeChannels.get(broadcastChannel)
    if (!channelEntry) {
      const bc =
        typeof BroadcastChannel !== 'undefined' ? new BroadcastChannel(broadcastChannel) : null
      channelEntry = {channel: bc, count: 0}
      activeChannels.set(broadcastChannel, channelEntry)
    }
    channelEntry.count++
    const channel = channelEntry.channel
    const qc = queryClient.getQueryCache()

    const publish = (type: 'updated' | 'removed', state?: unknown) => {
      const now = Date.now()
      const last = lastPostTimeRef.current[queryKeyHash] || 0
      if (type === 'updated' && now - last < 100) return
      lastPostTimeRef.current[queryKeyHash] = now

      const msg: Message =
        type === 'updated' && state !== undefined
          ? {type: 'updated', queryHash: queryKeyHash, state}
          : {type: 'removed', queryHash: queryKeyHash}

      if (channel) {
        channel.postMessage(msg)
      }
    }

    const unsubscribe = qc.subscribe(event => {
      if (transactionRef.current) return
      const {
        query: {queryHash, state},
      } = event
      if (queryHash !== queryKeyHash) return
      if (event.type === 'updated' && event.action.type === 'success') {
        publish('updated', structuredClone(state))
      }
      if (event.type === 'removed') {
        publish('removed')
      }
    })

    const onMessage = (e: MessageEvent) => {
      const action = e.data as Message
      if (action.queryHash !== queryKeyHash) return
      tx(() => {
        const query = qc.get(action.queryHash)
        if (!query) return
        if (action.type === 'updated') {
          const newState = action.state as typeof query.state
          if (newState.dataUpdatedAt > query.state.dataUpdatedAt) {
            query.setState(newState)
          }
        } else if (action.type === 'removed') {
          qc.remove(query)
        }
      })
    }

    if (channel) {
      channel.addEventListener('message', onMessage)
    }

    return () => {
      unsubscribe()
      if (channel) {
        channel.removeEventListener('message', onMessage)
      }
      const entry = activeChannels.get(broadcastChannel)!
      entry.count--
      if (entry.count === 0) {
        entry.channel?.close()
        activeChannels.delete(broadcastChannel)
      }
    }
  }, [queryClient, broadcastChannel, queryKeyHash])
}
