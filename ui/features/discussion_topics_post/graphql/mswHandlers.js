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

// helper function that filters out undefined values in objects before assigning
const mswAssign = (target, ...objects) => {
  return Object.assign(
    target,
    ...objects.map(object => {
      return Object.entries(object)
        .filter(([_k, v]) => v !== undefined)
        .reduce((obj, [k, v]) => ((obj[k] = v), obj), {}) // eslint-disable-line no-sequences
    })
  )
}
const defaultEntry = {
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
        permissions: {
          attach: true,
          create: true,
          delete: true,
          rate: true,
          read: true,
          reply: true,
          update: true,
          viewRating: true,
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
    viewRating: true,
    __typename: 'DiscussionEntryPermissions'
  },
  __typename: 'DiscussionEntry'
}

const defaultTopic = {
  allowRating: true,
  assignment: null,
  author: {
    avatarUrl: imageUrl,
    id: 'VXNlci0x',
    name: 'Matthew Lemon',
    _id: '1',
    __typename: 'User'
  },
  canUnpublish: false,
  courseSections: [
    {
      createdAt: '2020-12-01T12:37:07-07:00',
      id: 'Q291cnNlU2VjdGlvbi0z',
      name: 'Dope Section',
      updatedAt: '2020-12-01T12:37:07-07:00',
      _id: '3',
      __typename: 'Section'
    }
  ],
  createdAt: '2020-11-23T11:40:44-07:00',
  delayedPostAt: null,
  discussionType: 'side_comment',
  editor: {
    avatarUrl: imageUrl,
    id: 'VXNlci0x',
    name: 'Matthew Lemon',
    _id: '1',
    __typename: 'User'
  },
  entryCounts: {
    repliesCount: 2,
    unreadCount: 0,
    __typename: 'DiscussionEntryCounts'
  },
  id: 'RGlzY3Vzc2lvbi0x',
  isSectionSpecific: false,
  onlyGradersCanRate: false,
  permissions: {
    attach: true,
    create: true,
    delete: true,
    duplicate: false,
    rate: true,
    read: true,
    readAsAdmin: true,
    readReplies: true,
    reply: true,
    update: true,
    speedGrader: true,
    peerReview: true,
    showRubric: true,
    addRubric: true,
    openForComments: true,
    closeForComments: false,
    copyAndSendTo: true,
    __typename: 'DiscussionPermissions'
  },
  postedAt: '2020-11-23T11:40:44-07:00',
  published: true,
  requireInitialPost: false,
  rootDiscussionEntriesConnection: {
    nodes: [
      {
        author: {
          avatarUrl: imageUrl,
          id: 'VXNlci0x',
          name: 'Matthew Lemon',
          _id: '1',
          __typename: 'User'
        },
        createdAt: '2021-04-05T13:40:50-06:00',
        deleted: false,
        editor: null,
        id: '49',
        lastReply: {
          createdAt: '2021-04-05T13:41:42-06:00',
          __typename: 'DiscussionEntry'
        },
        message: '<p>This is the parent reply</p>',
        permissions: {
          attach: true,
          create: true,
          delete: true,
          rate: true,
          read: true,
          reply: true,
          update: true,
          viewRating: true,
          __typename: 'DiscussionEntryPermissions'
        },
        rating: false,
        ratingCount: null,
        ratingSum: null,
        read: true,
        rootEntryParticipantCounts: {
          unreadCount: 1,
          repliesCount: 1,
          __typename: 'RootEntryParticipantCount'
        },
        subentriesCount: 1,
        updatedAt: '2021-04-05T13:40:50-06:00',
        _id: '49',
        __typename: 'DiscussionEntry'
      }
    ],
    pageInfo: {
      endCursor: 'MTg',
      hasNextPage: false,
      hasPreviousPage: false,
      startCursor: 'MQ',
      __typename: 'PageInfo'
    },
    __typename: 'DiscussionEntryConnection'
  },
  rootEntriesTotalPages: 1,
  discussionEntriesConnection: {
    nodes: [
      {
        author: {
          avatarUrl: imageUrl,
          id: 'VXNlci0x',
          name: 'Matthew Lemon',
          _id: '1',
          __typename: 'User'
        },
        createdAt: '2021-04-05T13:40:50-06:00',
        deleted: false,
        editor: null,
        id: '49',
        lastReply: {
          createdAt: '2021-04-05T13:41:42-06:00',
          __typename: 'DiscussionEntry'
        },
        message: '<p>This is the parent reply</p>',
        permissions: {
          attach: true,
          create: true,
          delete: true,
          rate: true,
          read: true,
          reply: true,
          update: true,
          viewRating: true,
          __typename: 'DiscussionEntryPermissions'
        },
        rating: false,
        ratingCount: null,
        ratingSum: null,
        read: true,
        rootEntryParticipantCounts: {
          unreadCount: 1,
          repliesCount: 1,
          __typename: 'RootEntryParticipantCount'
        },
        subentriesCount: 1,
        updatedAt: '2021-04-05T13:40:50-06:00',
        _id: '49',
        __typename: 'DiscussionEntry'
      }
    ],
    pageInfo: {
      endCursor: 'MTg',
      hasNextPage: false,
      hasPreviousPage: false,
      startCursor: 'MQ',
      __typename: 'PageInfo'
    },
    __typename: 'DiscussionEntryConnection'
  },
  entriesTotalPages: 1,
  subscribed: true,
  title: 'Cookie Cat',
  message: 'This is a Discussion Topic Message',
  updatedAt: '2021-04-13T17:49:23-06:00',
  _id: '1',
  __typename: 'Discussion'
}

export const handlers = [
  graphql.query('GetDiscussionQuery', (req, res, ctx) => {
    return res(
      ctx.data({
        legacyNode: defaultTopic
      })
    )
  }),
  graphql.query('GetDiscussionSubentriesQuery', (req, res, ctx) => {
    return res(
      ctx.data({
        legacyNode: defaultEntry
      })
    )
  }),
  graphql.mutation('UpdateDiscussionEntryParticipant', (req, res, ctx) => {
    return res(
      ctx.data({
        updateDiscussionEntryParticipant: {
          discussionEntry: mswAssign(
            {...defaultEntry},
            {
              id: req.body.variables.discussionEntryId,
              read: req.body.variables.read,
              rating: req.body.variables.rating === 'liked',
              ratingSum: req.body.variables.rating === 'liked' ? 1 : 0
            }
          ),
          __typename: 'UpdateDiscussionEntryParticipantPayload'
        }
      })
    )
  }),
  graphql.mutation('DeleteDiscussionEntry', (req, res, ctx) => {
    return res(
      ctx.data({
        deleteDiscussionEntry: {
          discussionEntry: mswAssign(
            {...defaultEntry},
            {
              deleted: true,
              message: null
            }
          ),
          errors: null,
          __typename: 'DeleteDiscussionEntryPayload'
        }
      })
    )
  }),
  graphql.mutation('updateDiscussionTopic', (req, res, ctx) => {
    return res(
      ctx.data({
        updateDiscussionTopic: {
          discussionTopic: mswAssign(
            {...defaultTopic},
            {
              id: 'RGlzY3Vzc2lvbi0x',
              published: req.body.variables.published,
              __typename: 'Discussion'
            }
          ),
          __typename: 'UpdateDiscussionTopicPayload'
        }
      })
    )
  }),
  graphql.mutation('subscribeToDiscussionTopic', (req, res, ctx) => {
    return res(
      ctx.data({
        subscribeToDiscussionTopic: {
          discussionTopic: mswAssign(
            {...defaultTopic},
            {
              id: 'RGlzY3Vzc2lvbi0x',
              subscribed: req.body.variables.subscribed,
              __typename: 'Discussion'
            }
          ),
          __typename: 'SubscribeToDiscussionTopicPayload'
        }
      })
    )
  }),
  graphql.mutation('DeleteDiscussionTopic', (req, res, ctx) => {
    return res(
      ctx.data({
        deleteDiscussionTopic: {
          discussionTopicId: req.variables.id,
          errors: null,
          __typename: 'DeleteDiscussionTopicPayload'
        }
      })
    )
  }),
  graphql.mutation('CreateDiscussionEntry', (req, res, ctx) => {
    return res(
      ctx.data({
        createDiscussionEntry: {
          discussionEntry: mswAssign(
            {...defaultEntry},
            {
              id: req.body.variables.discussionTopicId,
              message: req.body.variables.message
            }
          ),
          errors: null,
          __typename: 'CreateDiscussionEntryPayload'
        }
      })
    )
  }),
  graphql.mutation('UpdateDiscussionEntry', (req, res, ctx) => {
    ctx.data({
      updateDiscussionEntry: {
        discussionTopic: mswAssign(
          {...defaultEntry},
          {
            id: req.body.variables.discussionEntryId,
            message: req.body.variables.message
          }
        ),
        __typename: 'UpdateDiscussionEntryPayload'
      }
    })
  })
]
