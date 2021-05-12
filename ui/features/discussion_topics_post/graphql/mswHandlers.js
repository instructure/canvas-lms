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
  graphql.query('GetDiscussionQuery', (req, res, ctx) => {
    return res(
      ctx.data({
        legacyNode: Discussion.mock()
      })
    )
  }),
  graphql.query('GetDiscussionSubentriesQuery', (req, res, ctx) => {
    return res(
      ctx.data({
        legacyNode: DiscussionEntry.mock({
          discussionSubentriesConnection: {
            nodes: [
              DiscussionEntry.mock({
                _id: '50',
                id: '50',
                message: '<p>This is the child reply</p>'
              })
            ],
            pageInfo: PageInfo.mock(),
            __typename: 'DiscussionSubentriesConnection'
          }
        })
      })
    )
  }),
  graphql.mutation('UpdateDiscussionEntryParticipant', (req, res, ctx) => {
    return res(
      ctx.data({
        updateDiscussionEntryParticipant: {
          discussionEntry: mswAssign(
            {...DiscussionEntry.mock()},
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
            {...DiscussionEntry.mock()},
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
            {...Discussion.mock()},
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
            {...Discussion.mock()},
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
            {...DiscussionEntry.mock()},
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
          {...DiscussionEntry.mock()},
          {
            id: req.body.variables.discussionEntryId,
            message: req.body.variables.message
          }
        ),
        __typename: 'UpdateDiscussionEntryPayload'
      }
    })
  }),
  graphql.mutation('UpdateDiscussionEntriesReadState', (req, res, ctx) => {
    const discussionEntries = req.variables.discussionEntryIds.map(id => ({
      ...defaultEntry,
      id,
      read: req.variables.read
    }))

    return res(
      ctx.data({
        updateDiscussionEntriesReadState: {
          discussionEntries,
          __typename: 'UpdateDiscussionEntriesReadState'
        }
      })
    )
  })
]
