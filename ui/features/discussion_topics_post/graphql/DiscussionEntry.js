/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {bool, number, shape, string} from 'prop-types'
import gql from 'graphql-tag'
import {User} from './User'

export const DiscussionEntry = {
  fragment: gql`
    fragment DiscussionEntry on DiscussionEntry {
      id
      _id
      createdAt
      updatedAt
      deleted
      message
      ratingCount
      ratingSum
      rating
      read
      subentriesCount
      rootEntryParticipantCounts {
        unreadCount
        repliesCount
      }
      author {
        ...User
      }
      editor {
        ...User
      }
      lastReply {
        createdAt
      }
    }
    ${User.fragment}
  `,

  shape: shape({
    id: string,
    _id: string,
    createdAt: string,
    updatedAt: string,
    deleted: bool,
    message: string,
    ratingCount: number,
    ratingSum: number,
    rating: bool,
    read: bool,
    subentriesCount: number,
    author: User.shape,
    editor: User.shape,
    rootEntryParticipantCounts: {
      unreadCount: number,
      repliesCount: number
    },
    lastReply: shape({
      createdAt: string
    })
  })
}

export const DefaultMocks = {
  DiscussionEntry: () => ({
    _id: '1',
    createdAt: '2021-03-25T13:22:24-06:00',
    updatedAt: '2021-03-25T13:22:24-06:00',
    deleted: false,
    message: 'Howdy Partner, this is a message!',
    ratingCount: 5,
    ratingSum: 5,
    rating: true,
    read: true,
    subentriesCount: 5,
    lastReply: {
      createdAt: '2021-03-25T13:22:24-06:00'
    }
  })
}
