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

import {DISCUSSION_QUERY, DISCUSSION_SUBENTRIES_QUERY} from './Queries'
import {
  DELETE_DISCUSSION_ENTRY,
  UPDATE_DISCUSSION_ENTRY_PARTICIPANT,
  UPDATE_DISCUSSION_ENTRY,
  SUBSCRIBE_TO_DISCUSSION_TOPIC,
  CREATE_DISCUSSION_ENTRY
} from './Mutations'
import {Discussion} from './Discussion'
import {DiscussionEntry} from './DiscussionEntry'
import {PageInfo} from './PageInfo'
import {User} from './User'

/* Query Mocks */
export const getDiscussionQueryMock = ({
  courseID = '1',
  discussionID = '1',
  filter = 'all',
  page = 'MA==',
  perPage = 20,
  rolePillTypes = ['TaEnrollment', 'TeacherEnrollment'],
  rootEntries = true,
  searchTerm = '',
  sort = 'desc',
  shouldError = false
} = {}) => [
  {
    request: {
      query: DISCUSSION_QUERY,
      variables: {
        courseID,
        discussionID,
        filter,
        page,
        perPage,
        rolePillTypes,
        rootEntries,
        searchTerm,
        sort
      }
    },
    result: {
      data: {
        legacyNode: (() => {
          if (filter === 'unread') {
            return Discussion.mock({
              discussionEntriesConnection: {
                nodes: [
                  DiscussionEntry.mock({
                    _id: '101',
                    id: 'RGlzY3Vzc2lvbkVudHJ5LTEwMQo=',
                    message: '<p>This is an Unread Reply</p>'
                  })
                ],
                pageInfo: PageInfo.mock(),
                __typename: 'DiscussionSubentriesConnection'
              }
            })
          }
          if (sort === 'asc') {
            return Discussion.mock({
              discussionEntriesConnection: {
                nodes: [
                  DiscussionEntry.mock({
                    _id: '102',
                    id: 'RGlzY3Vzc2lvbkVudHJ5LTEwMgo=',
                    message: '<p>This is a Reply asc</p>'
                  })
                ],
                pageInfo: PageInfo.mock(),
                __typename: 'DiscussionSubentriesConnection'
              }
            })
          }
          return Discussion.mock({
            author: User.mock({
              courseRoles: ['TeacherEnrollment', 'TaEnrollment'],
              id: 'role-user'
            })
          })
        })()
      }
    },
    ...(shouldError && {error: new Error('graphql error')})
  }
]

export const getDiscussionSubentriesQueryMock = ({
  after = null,
  before = null,
  beforeRelativeEntry = null,
  courseID = '1',
  discussionEntryID = '1',
  first = null,
  includeRelativeEntry = null,
  last = null,
  relativeEntryId = null,
  rolePillTypes = ['TaEnrollment', 'TeacherEnrollment'],
  sort = 'asc'
} = {}) => [
  {
    request: {
      query: DISCUSSION_SUBENTRIES_QUERY,
      variables: {
        ...(after !== null && {after}),
        ...(before !== null && {before}),
        ...(beforeRelativeEntry !== null && {beforeRelativeEntry}),
        courseID,
        discussionEntryID,
        ...(first !== null && {first}),
        ...(includeRelativeEntry !== null && {includeRelativeEntry}),
        ...(last !== null && {last}),
        ...(relativeEntryId !== null && {relativeEntryId}),
        rolePillTypes,
        sort
      }
    },
    result: {
      data: {
        legacyNode: (() => {
          if (includeRelativeEntry) {
            return DiscussionEntry.mock({
              id: btoa(`DiscussionEntry-${discussionEntryID}`),
              _id: discussionEntryID,
              discussionSubentriesConnection: {
                nodes: [
                  DiscussionEntry.mock({
                    _id: '103',
                    id: 'RGlzY3Vzc2lvbkVudHJ5LTEwMwo=',
                    message: '<p>This is the search result child reply</p>'
                  })
                ],
                pageInfo: PageInfo.mock(),
                __typename: 'DiscussionSubentriesConnection'
              }
            })
          }
          if (first !== null && first === 0) {
            return DiscussionEntry.mock({
              id: btoa(`DiscussionEntry-${discussionEntryID}`),
              _id: discussionEntryID
            })
          }
          if (sort === 'asc') {
            return DiscussionEntry.mock({
              id: btoa(`DiscussionEntry-${discussionEntryID}`),
              _id: discussionEntryID,
              discussionSubentriesConnection: {
                nodes: [
                  DiscussionEntry.mock({
                    _id: '104',
                    id: 'RGlzY3Vzc2lvbkVudHJ5LTEwNAo=',
                    message: '<p>This is the child reply asc</p>'
                  })
                ],
                pageInfo: PageInfo.mock(),
                __typename: 'DiscussionSubentriesConnection'
              }
            })
          }
          return DiscussionEntry.mock({
            id: btoa(`DiscussionEntry-${discussionEntryID}`),
            _id: discussionEntryID,
            discussionSubentriesConnection: {
              nodes: [
                DiscussionEntry.mock({
                  _id: '105',
                  id: 'RGlzY3Vzc2lvbkVudHJ5LTEwNQo=',
                  message: '<p>This is the child reply</p>'
                })
              ],
              pageInfo: PageInfo.mock(),
              __typename: 'DiscussionSubentriesConnection'
            }
          })
        })()
      }
    }
  }
]

/* Mutation Mocks */
export const deleteDiscussionEntryMock = ({id = '1'} = {}) => [
  {
    request: {
      query: DELETE_DISCUSSION_ENTRY,
      variables: {id}
    },
    result: {
      data: {
        deleteDiscussionEntry: {
          discussionEntry: DiscussionEntry.mock({
            id: btoa(`DiscussionEntry-${id}`),
            _id: id,
            deleted: true
          }),
          __typename: 'DeleteDiscussionEntryPayload'
        }
      }
    }
  }
]

export const updateDiscussionEntryParticipantMock = ({
  discussionEntryId = '1',
  read = null,
  rating = null,
  forcedReadState = null
} = {}) => [
  {
    request: {
      query: UPDATE_DISCUSSION_ENTRY_PARTICIPANT,
      variables: {
        discussionEntryId,
        ...(read !== null && {read}),
        ...(rating !== null && {rating}),
        ...(forcedReadState !== null && {forcedReadState})
      }
    },
    result: {
      data: {
        updateDiscussionEntryParticipant: {
          discussionEntry: DiscussionEntry.mock({
            id: btoa(`DiscussionEntry-${discussionEntryId}`),
            _id: discussionEntryId,
            ratingSum: rating !== null && rating === 'liked' ? 1 : 0,
            entryParticipant: {
              rating: !!(rating !== null && rating === 'liked'),
              read: read !== null ? read : true,
              forcedReadState: forcedReadState !== null ? forcedReadState : false,
              __typename: 'EntryParticipant'
            }
          }),
          __typename: 'UpdateDiscussionEntryParticipantPayload'
        }
      }
    }
  }
]

export const updateDiscussionEntryMock = ({discussionEntryId = '1', message = ''} = {}) => [
  {
    request: {
      query: UPDATE_DISCUSSION_ENTRY,
      variables: {
        discussionEntryId,
        message
      }
    },
    result: {
      data: {
        updateDiscussionEntry: {
          discussionEntry: DiscussionEntry.mock({
            id: btoa(`DiscussionEntry-${discussionEntryId}`),
            _id: discussionEntryId,
            message
          }),
          __typename: 'UpdateDiscussionEntryPayload'
        }
      }
    }
  }
]

export const subscribeToDiscussionTopicMock = ({
  discussionTopicId = '1',
  subscribed = true
} = {}) => [
  {
    request: {
      query: SUBSCRIBE_TO_DISCUSSION_TOPIC,
      variables: {
        discussionTopicId,
        subscribed
      }
    },
    result: {
      data: {
        subscribeToDiscussionTopic: {
          discussionTopic: Discussion.mock({
            id: btoa(`Discussion-${discussionTopicId}`),
            _id: discussionTopicId,
            subscribed
          }),
          __typename: 'SubscribeToDiscussionTopicPayload'
        }
      }
    }
  }
]

export const createDiscussionEntryMock = ({
  discussionTopicId = '1',
  message = '',
  replyFromEntryId = null,
  fileId = null,
  includeReplyPreview = null
} = {}) => [
  {
    request: {
      query: CREATE_DISCUSSION_ENTRY,
      variables: {
        discussionTopicId,
        message,
        ...(replyFromEntryId !== null && {replyFromEntryId}),
        ...(fileId !== null && {fileId}),
        ...(includeReplyPreview !== null && {includeReplyPreview})
      }
    },
    result: {
      data: {
        createDiscussionEntry: {
          discussionEntry: DiscussionEntry.mock({
            id: btoa(`DiscussionEntry-1337`),
            _id: '1337',
            message
          }),
          __typename: 'CreateDiscussionEntryPayload'
        }
      }
    }
  }
]
