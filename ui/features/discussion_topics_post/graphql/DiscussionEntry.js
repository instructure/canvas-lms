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

import {AnonymousUser} from './AnonymousUser'
import {bool, number, shape, string} from 'prop-types'
import {DiscussionEntryPermissions} from './DiscussionEntryPermissions'
import {DiscussionEntryVersion} from './DiscussionEntryVersion'
import gql from 'graphql-tag'
import {Attachment} from './Attachment'
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
      subentriesCount
      editor {
        ...User
      }
      author {
        ...User
      }
      attachment {
        ...Attachment
      }
      entryParticipant {
        rating
        read
        forcedReadState
        reportType
      }
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
      rootEntryId
      parentId
      quotedEntry {
        _id
        createdAt
        previewMessage
        author {
          shortName
          id
        }
        anonymousAuthor {
          shortName
          id
        }
        editor {
          shortName
          id
        }
        deleted
      }
      discussionEntryVersionsConnection {
        nodes {
          ...DiscussionEntryVersion
        }
      }
      reportTypeCounts {
        inappropriateCount
        offensiveCount
        otherCount
        total
      }
      depth
    }
    ${User.fragment}
    ${Attachment.fragment}
    ${DiscussionEntryPermissions.fragment}
    ${DiscussionEntryVersion.fragment}
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
    subentriesCount: number,
    attachment: Attachment.shape,
    author: User.shape,
    anonymousAuthor: AnonymousUser.shape,
    editor: User.shape,
    entryParticipant: shape({
      rating: bool,
      read: bool,
      forcedReadState: bool,
      reportType: string,
    }),
    rootEntryParticipantCounts: shape({
      unreadCount: number,
      repliesCount: number,
    }),
    lastReply: shape({
      createdAt: string,
    }),
    permissions: DiscussionEntryPermissions.shape,
    rootEntryId: string,
    parentId: string,
    quotedEntry: shape({
      createdAt: string,
      previewMessage: string,
      author: shape({
        shortName: string,
        id: string,
      }),
      anonymousAuthor: shape({
        shortName: string,
        id: string,
      }),
      editor: shape({
        shortName: string,
      }),
      deleted: bool,
    }),
    discussionEntryVersionsConnection: DiscussionEntryVersion.shape,
    reportTypeCounts: shape({
      inappropriateCount: number,
      offensiveCount: number,
      otherCount: number,
      total: number,
    }),
    depth: number,
  }),

  mock: ({
    id = 'DiscussionEntry-default-mock',
    _id = 'DiscussionEntry-default-mock',
    createdAt = '2021-02-08T13:35:56-07:00',
    updatedAt = '2021-04-13T10:00:20-06:00',
    deleted = false,
    message = '<p>This is the parent reply</p>',
    ratingCount = null,
    ratingSum = null,
    subentriesCount = 2,
    attachment = Attachment.mock(),
    author = User.mock(),
    anonymousAuthor = null,
    editor = User.mock(),
    entryParticipant = {
      rating: false,
      read: true,
      forcedReadState: false,
      reportType: null,
      __typename: 'EntryParticipant',
    },
    rootEntryParticipantCounts = {
      unreadCount: 0,
      repliesCount: 1,
      __typename: 'DiscussionEntryCounts',
    },
    lastReply = {
      createdAt: '2021-04-05T13:41:42-06:00',
      __typename: 'DiscussionEntry',
    },
    permissions = DiscussionEntryPermissions.mock(),
    discussionSubentriesConnection = {
      nodes: [],
      pageInfo: PageInfo.mock(),
      __typename: 'DiscussionSubentriesConnection',
    },
    rootEntryId = null,
    parentId = null,
    quotedEntry = null,
    discussionEntryVersionsConnection = {
      nodes: [
        DiscussionEntryVersion.mock({
          message: '<p>This is the parent reply</p>',
        }),
      ],
      __typename: 'DiscussionEntryVersionConnection',
    },
    reportTypeCounts = {
      inappropriateCount: 0,
      offensiveCount: 0,
      otherCount: 0,
      total: 0,
      __typename: 'DiscussionEntryReportTypeCounts',
    },
    depth = 1,
  } = {}) => ({
    id,
    _id,
    createdAt,
    updatedAt,
    deleted,
    message,
    ratingCount,
    ratingSum,
    subentriesCount,
    attachment,
    author,
    anonymousAuthor,
    editor,
    entryParticipant,
    rootEntryParticipantCounts,
    lastReply,
    permissions,
    discussionSubentriesConnection,
    rootEntryId,
    parentId,
    quotedEntry,
    discussionEntryVersionsConnection,
    reportTypeCounts,
    depth,
    __typename: 'DiscussionEntry',
  }),
}
