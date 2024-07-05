/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import gql from 'graphql-tag'
import {arrayOf, number, shape, string} from 'prop-types'

export const ActivityStreamSummary = {
  fragment: gql`
    fragment ActivityStreamSummary on ActivityStream {
      summary {
        count
        notificationCategory
        type
        unreadCount
      }
    }
  `,
  shape: shape({
    summary: arrayOf(
      shape({
        count: number,
        notificationCategory: string,
        type: string,
        unreadCount: number,
      })
    ),
  }),
  mock: ({
    summary = [
      {
        count: 2,
        notificationCategory: null,
        type: 'Announcement',
        unreadCount: 0,
      },
      {
        count: 0,
        notificationCategory: null,
        type: 'DiscussionTopic',
        unreadCount: 0,
      },
      {
        count: 3,
        notificationCategory: 'Due Date',
        type: 'Message',
        unreadCount: 0,
      },
    ],
  } = {}) => ({
    summary,
    __typename: 'ActivityStreamType',
  }),
}
