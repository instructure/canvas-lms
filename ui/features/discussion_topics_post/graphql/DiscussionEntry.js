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
import {DiscussionEntryPermissions} from './DiscussionEntryPermissions'
import gql from 'graphql-tag'
import {PageInfo} from './PageInfo'
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
      replyPreview
      forcedReadState
      subentriesCount
      rootEntryParticipantCounts {
        unreadCount
        repliesCount
      }
      lastReply {
        createdAt
      }
      permissions {
        ...DiscussionEntryPermissions
      }
      rootEntry {
        id
        rootEntryParticipantCounts {
          unreadCount
          repliesCount
        }
      }
      discussionTopic {
        entryCounts {
          unreadCount
          repliesCount
        }
      }
      parent {
        id
      }
    }
    ${DiscussionEntryPermissions.fragment}
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
    replyPreview: string,
    forcedReadState: bool,
    subentriesCount: number,
    author: User.shape,
    editor: User.shape,
    rootEntryParticipantCounts: shape({
      unreadCount: number,
      repliesCount: number
    }),
    lastReply: shape({
      createdAt: string
    }),
    permissions: DiscussionEntryPermissions.shape,
    rootEntry: shape({
      id: string,
      rootEntryParticipantCounts: shape({
        unreadCount: number,
        repliesCount: number
      })
    }),
    discussionTopic: shape({
      entryCounts: shape({
        unreadCount: number,
        repliesCount: number
      })
    }),
    parent: shape({id: string})
  }),

  mock: ({
    id = '3',
    _id = '3',
    createdAt = '2021-02-08T13:35:56-07:00',
    updatedAt = '2021-04-13T10:00:20-06:00',
    deleted = false,
    message = '<p>This is the parent reply</p>',
    ratingCount = null,
    ratingSum = null,
    rating = false,
    read = true,
    replyPreview = '',
    forcedReadState = false,
    subentriesCount = 2,
    author = User.mock(),
    editor = User.mock(),
    rootEntryParticipantCounts = {
      unreadCount: 1,
      repliesCount: 1,
      __typename: 'DiscussionEntryCounts'
    },
    lastReply = {
      createdAt: '2021-04-05T13:41:42-06:00',
      __typename: 'DiscussionEntry'
    },
    permissions = DiscussionEntryPermissions.mock(),
    discussionSubentriesConnection = {
      nodes: [],
      pageInfo: PageInfo.mock(),
      __typename: 'DiscussionSubentriesConnection'
    },
    rootEntry = null,
    discussionTopic = {
      entryCounts: {
        unreadCount: 2,
        repliesCount: 56,
        __typename: 'DiscussionEntryCounts'
      },
      __typename: 'Discussion'
    },
    parent = {
      id: '77',
      __typename: 'DiscussionEntry'
    }
  } = {}) => ({
    id,
    _id,
    createdAt,
    updatedAt,
    deleted,
    message,
    ratingCount,
    ratingSum,
    rating,
    read,
    replyPreview,
    forcedReadState,
    subentriesCount,
    author,
    editor,
    rootEntryParticipantCounts,
    lastReply,
    permissions,
    discussionSubentriesConnection,
    rootEntry,
    discussionTopic,
    parent,
    __typename: 'DiscussionEntry'
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
