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
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('discussions_posts')

export const getFullReplyText = (replyCount: number | string, unreadCount: number) => {
  return unreadCount > 0
    ? I18n.t(
        {
          one: '%{replyCount} Reply, %{unreadCount} Unread',
          other: '%{replyCount} Replies, %{unreadCount} Unread',
        },
        {
          count: replyCount,
          replyCount: replyCount,
          unreadCount: unreadCount,
        },
      )
    : I18n.t(
        {one: '%{replyCount} Reply', other: '%{replyCount} Replies'},
        {count: replyCount, replyCount: replyCount},
      )
}
