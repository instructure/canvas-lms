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

import {graphql} from 'msw'

const imageUrl = 'data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=='

export const handlers = [
  graphql.query('GetDiscussionSubentriesQuery', (req, res, ctx) => {
    return res(
      ctx.data({
        legacyNode: {
          _id: '49',
          id: '49',
          createdAt: '2021-04-05T13:40:50-06:00',
          updatedAt: '2021-04-05T13:40:50-06:00',
          deleted: false,
          message: '<p>This is the parent reply</p>',
          ratingCount: null,
          ratingSum: null,
          rating: false,
          read: true,
          subentriesCount: 1,
          rootEntryParticipantCounts: {
            unreadCount: 1,
            repliesCount: 1,
            __typename: 'RootEntryParticipantCount'
          },
          author: {
            _id: '1',
            id: 'VXNlci0x',
            avatarUrl: imageUrl,
            name: 'Matthew Lemon',
            __typename: 'User'
          },
          editor: null,
          lastReply: {
            createdAt: '2021-04-05T13:41:42-06:00',
            __typename: 'DiscussionEntry'
          },
          discussionSubentriesConnection: {
            nodes: [
              {
                _id: '50',
                id: '50',
                createdAt: '2021-04-05T13:41:01-06:00',
                updatedAt: '2021-04-05T13:41:01-06:00',
                deleted: false,
                message: '<p>This is the child reply</p>',
                ratingCount: 1,
                ratingSum: 0,
                rating: 'false',
                read: true,
                subentriesCount: 0,
                rootEntryParticipantCounts: null,
                author: {
                  _id: '1',
                  id: 'VXNlci0x',
                  avatarUrl: imageUrl,
                  name: 'Matthew Lemon',
                  __typename: 'User'
                },
                editor: null,
                lastReply: null,
                permissions: {
                  attach: true,
                  create: true,
                  delete: true,
                  rate: true,
                  read: true,
                  reply: true,
                  update: true,
                  __typename: 'DiscussionEntryPermissions'
                },
                __typename: 'DiscussionEntry'
              }
            ],
            pageInfo: {
              endCursor: 'MQ',
              hasNextPage: false,
              hasPreviousPage: false,
              startCursor: 'MQ',
              __typename: 'PageInfo'
            },
            __typename: 'DiscussionSubentriesConnection'
          },
          permissions: {
            attach: true,
            create: true,
            delete: true,
            rate: true,
            read: true,
            reply: true,
            update: true,
            __typename: 'DiscussionEntryPermissions'
          },
          __typename: 'DiscussionEntry'
        }
      })
    )
  }),
  graphql.mutation('UpdateDiscussionEntryParticipant', (req, res, ctx) => {
    return res(
      ctx.data({
        updateDiscussionEntryParticipant: {
          discussionEntry: {
            id: req.body.variables.discussionEntryId,
            read: req.body.variables.read,
            rating: false,
            __typename: 'DiscussionEntry'
          },
          __typename: 'UpdateDiscussionEntryParticipantPayload'
        }
      })
    )
  })
]
