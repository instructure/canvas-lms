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

import doFetchApi from '@canvas/do-fetch-api-effect'

import type {QueryFunctionContext} from '@tanstack/react-query'

const URL_MAP: Record<string, string> = {
  content_shares: '/api/v1/users/self/content_shares/unread_count',
  conversations: '/api/v1/conversations/unread_count',
  release_notes: '/api/v1/release_notes/unread_count',
}

const unreadCountTypes = Object.keys(URL_MAP)

// queryKey is e.g. ['unread_count', 'conversations'], the discriminator is at index 1
// The discriminator i.e. the unreadCountType is always a string, we'll just coerce it
// to be so because it's typed as `unknown` in Tanstack's QueryFunctionContext
export async function getUnreadCount({queryKey, signal}: QueryFunctionContext): Promise<number> {
  const unreadCountType = queryKey[1] as string
  const fetchOpts = {signal}

  if (!unreadCountTypes.includes(unreadCountType))
    throw new Error(`Bad unreadCount type ${unreadCountType}`)

  const path = URL_MAP[unreadCountType]
  // conversations count returns as string 😞    vvvvvvvvvvvvvvv
  const {json} = await doFetchApi<{unread_count: number | string}>({path, fetchOpts})
  if (json) {
    const fetched = json.unread_count
    // Make sure we're getting a number or a string that can be coerced to a number
    const val = typeof fetched === 'number' ? fetched : parseInt(fetched, 10)

    if (!Number.isNaN(val)) return val
  }
  throw new Error(`Error while fetching unread count for ${unreadCountType}`)
}
