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

import type {QueryKey} from '@tanstack/react-query'

const urls = {
  content_shares: '/api/v1/users/self/content_shares/unread_count',
  conversations: '/api/v1/conversations/unread_count',
  release_notes: '/api/v1/release_notes/unread_count',
}

const unreadCountTypes = Object.keys(urls) as (keyof typeof urls)[]

type UnreadCountType = (typeof unreadCountTypes)[number]

// e.g. ['unread_count', 'conversations']
export function getUnreadCount({queryKey}: {queryKey: QueryKey}): Promise<number> {
  const unreadCountType = queryKey[1] as UnreadCountType

  if (!unreadCountTypes.includes(unreadCountType)) {
    throw new Error('Invalid unread count key')
  }

  return (
    fetch(urls[unreadCountType])
      .then(res => res.json())
      // conversations count returns as string :-(
      .then((data: {unread_count: number | string}) => {
        // ensure number type
        const fetchedUnreadCount =
          typeof data.unread_count === 'number'
            ? data.unread_count
            : parseInt(data.unread_count, 10)

        if (Number.isNaN(fetchedUnreadCount)) {
          throw new Error(`Invalid unread count for ${unreadCountType}`)
        }

        return fetchedUnreadCount
      })
  )
}
