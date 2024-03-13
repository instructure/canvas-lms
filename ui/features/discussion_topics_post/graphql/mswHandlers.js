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

import {graphql, HttpResponse} from 'msw'
import {Discussion} from './Discussion'
import {DiscussionEntry} from './DiscussionEntry'
import {PageInfo} from './PageInfo'

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

export const handlers = [
  graphql.query('GetDiscussionQuery', ({variables}) => {
    if (variables.filter === 'unread') {
      return HttpResponse.json({
        data: {
          legacyNode: Discussion.mock({
            discussionEntriesConnection: {
              nodes: [
                DiscussionEntry.mock({
                  _id: '50',
                  id: '50',
                  message: '<p>This is an Unread Reply</p>',
                }),
              ],
              pageInfo: PageInfo.mock(),
              __typename: 'DiscussionSubentriesConnection',
            },
          }),
        },
      })
    }
    if (variables.sort === 'asc') {
      return HttpResponse.json({
        data: {
          legacyNode: Discussion.mock({
            discussionEntriesConnection: {
              nodes: [
                DiscussionEntry.mock({
                  _id: '50',
                  id: '50',
                  message: '<p>This is a Reply asc</p>',
                }),
              ],
              pageInfo: PageInfo.mock(),
              __typename: 'DiscussionSubentriesConnection',
            },
          }),
        },
      })
    }
    return HttpResponse.json({
      data: {legacyNode: Discussion.mock()},
    })
  }),
  graphql.query('GetDiscussionSubentriesQuery', ({variables}) => {
    if (variables.includeRelativeEntry) {
      return HttpResponse.json({
        data: {
          legacyNode: DiscussionEntry.mock({
            discussionSubentriesConnection: {
              nodes: [
                DiscussionEntry.mock({
                  _id: '51',
                  id: '51',
                  message: '<p>This is the search result child reply</p>',
                }),
              ],
              pageInfo: PageInfo.mock(),
              __typename: 'DiscussionSubentriesConnection',
            },
          }),
        },
      })
    }
    if (variables.sort === 'asc') {
      return HttpResponse.json({
        data: {
          legacyNode: DiscussionEntry.mock({
            parentId: '77',
            discussionSubentriesConnection: {
              nodes: [
                DiscussionEntry.mock({
                  _id: '50',
                  id: '50',
                  message: '<p>This is the child reply asc</p>',
                }),
              ],
              pageInfo: PageInfo.mock(),
              __typename: 'DiscussionSubentriesConnection',
            },
          }),
        },
      })
    }
    return HttpResponse.json({
      data: {
        legacyNode: DiscussionEntry.mock({
          rootEntry: DiscussionEntry.mock({_id: 32}),
          discussionSubentriesConnection: {
            nodes: [
              DiscussionEntry.mock({
                _id: '50',
                id: '50',
                message: '<p>This is the child reply</p>',
              }),
            ],
            pageInfo: PageInfo.mock(),
            __typename: 'DiscussionSubentriesConnection',
          },
        }),
      },
    })
  }),
  graphql.mutation('UpdateDiscussionEntryParticipant', ({variables}) => {
    return HttpResponse.json({
      data: {
        updateDiscussionEntryParticipant: {
          discussionEntry: mswAssign(
            {...DiscussionEntry.mock()},
            {
              id: variables.discussionEntryId,
              read: variables.read,
              rating: variables.rating === 'liked',
              ratingSum: variables.rating === 'liked' ? 1 : 0,
              forcedReadState: variables.forcedReadState,
            }
          ),
          __typename: 'UpdateDiscussionEntryParticipantPayload',
        },
      },
    })
  }),
  graphql.mutation('DeleteDiscussionEntry', () => {
    return HttpResponse.json({
      data: {
        deleteDiscussionEntry: {
          discussionEntry: mswAssign(
            {...DiscussionEntry.mock()},
            {
              deleted: true,
              message: null,
            }
          ),
          errors: null,
          __typename: 'DeleteDiscussionEntryPayload',
        },
      },
    })
  }),
  graphql.mutation('updateDiscussionTopic', ({variables}) => {
    return HttpResponse.json({
      data: {
        updateDiscussionTopic: {
          discussionTopic: mswAssign(
            {...Discussion.mock()},
            {
              id: 'RGlzY3Vzc2lvbi0x',
              published: variables.published,
              __typename: 'Discussion',
            }
          ),
          __typename: 'UpdateDiscussionTopicPayload',
        },
      },
    })
  }),
  graphql.mutation('subscribeToDiscussionTopic', ({variables}) => {
    return HttpResponse.json({
      data: {
        subscribeToDiscussionTopic: {
          discussionTopic: mswAssign(
            {...Discussion.mock()},
            {
              id: 'RGlzY3Vzc2lvbi0x',
              subscribed: variables.subscribed,
              __typename: 'Discussion',
            }
          ),
          __typename: 'SubscribeToDiscussionTopicPayload',
        },
      },
    })
  }),
  graphql.mutation('DeleteDiscussionTopic', ({variables}) => {
    return HttpResponse.json({
      data: {
        deleteDiscussionTopic: {
          discussionTopicId: variables.id,
          errors: null,
          __typename: 'DeleteDiscussionTopicPayload',
        },
      },
    })
  }),
  graphql.mutation('CreateDiscussionEntry', ({variables}) => {
    return HttpResponse.json({
      data: {
        createDiscussionEntry: {
          discussionEntry: mswAssign(
            {...DiscussionEntry.mock()},
            {
              id: variables.discussionTopicId,
              message: variables.message,
            }
          ),
          errors: null,
          __typename: 'CreateDiscussionEntryPayload',
        },
      },
    })
  }),
  graphql.mutation('UpdateDiscussionEntry', ({variables}) => {
    return HttpResponse.json({
      data: {
        updateDiscussionEntry: {
          discussionEntry: mswAssign(
            {...DiscussionEntry.mock()},
            {
              id: variables.discussionEntryId,
              message: variables.message,
            }
          ),
          errors: null,
          __typename: 'UpdateDiscussionEntryPayload',
        },
      },
    })
  }),
  graphql.mutation('UpdateDiscussionEntriesReadState', ({variables}) => {
    const discussionEntries = variables.discussionEntryIds.map(id => ({
      ...DiscussionEntry.mock(),
      id,
      read: variables.read,
    }))

    return HttpResponse.json({
      data: {
        updateDiscussionEntriesReadState: {
          discussionEntries,
          __typename: 'UpdateDiscussionEntriesReadState',
        },
      },
    })
  }),
  graphql.mutation('UpdateDiscussionReadState', () => {
    return HttpResponse.json({
      data: {
        updateDiscussionReadState: {
          discussionTopic: Discussion.mock(),
          __typename: 'UpdateDiscussionReadStatePayload',
        },
      },
    })
  }),
]
