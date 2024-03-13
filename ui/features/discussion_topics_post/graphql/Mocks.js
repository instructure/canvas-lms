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

import {
  DISCUSSION_ENTRY_ALL_ROOT_ENTRIES_QUERY,
  DISCUSSION_QUERY,
  DISCUSSION_SUBENTRIES_QUERY,
} from './Queries'
import {
  DELETE_DISCUSSION_ENTRY,
  UPDATE_DISCUSSION_ENTRY_PARTICIPANT,
  UPDATE_DISCUSSION_ENTRY,
  SUBSCRIBE_TO_DISCUSSION_TOPIC,
  CREATE_DISCUSSION_ENTRY,
  DELETE_DISCUSSION_TOPIC,
  UPDATE_DISCUSSION_READ_STATE,
  UPDATE_DISCUSSION_TOPIC,
  UPDATE_USER_DISCUSSION_SPLITSCREEN_PREFERENCE,
} from './Mutations'
import {Discussion} from './Discussion'
import {DiscussionEntry} from './DiscussionEntry'
import {PageInfo} from './PageInfo'
import {User} from './User'
import {Attachment} from './Attachment'
import {AnonymousUser} from './AnonymousUser'

/* Query Mocks */
export const getDiscussionQueryMock = ({
  discussionID = 'Discussion-default-mock',
  filter = 'all',
  page = 'MA==',
  perPage = 20,
  rootEntries = true,
  searchTerm = '',
  sort = 'desc',
  shouldError = false,
  isGroup = true,
  unreadBefore = '',
} = {}) => [
  {
    request: {
      query: DISCUSSION_QUERY,
      variables: {
        discussionID,
        filter,
        page,
        perPage,
        rootEntries,
        searchTerm,
        sort,
        unreadBefore,
      },
    },
    result: {
      data: {
        legacyNode: (() => {
          if (filter === 'unread') {
            return Discussion.mock({
              discussionEntriesConnection: {
                nodes: [
                  DiscussionEntry.mock({
                    _id: 'DiscussionEntry-unread-mock',
                    id: 'DiscussionEntry-unread-mock',
                    message: '<p>This is an Unread Reply</p>',
                  }),
                ],
                pageInfo: PageInfo.mock(),
                __typename: 'DiscussionSubentriesConnection',
              },
            })
          }
          if (sort === 'asc') {
            return Discussion.mock({
              discussionEntriesConnection: {
                nodes: [
                  DiscussionEntry.mock({
                    _id: 'DiscussionEntry-asc-mock',
                    id: 'DiscussionEntry-asc-mock',
                    message: '<p>This is a Reply asc</p>',
                  }),
                ],
                pageInfo: PageInfo.mock(),
                __typename: 'DiscussionSubentriesConnection',
              },
            })
          }
          if (!isGroup) {
            return Discussion.mock({
              author: User.mock({
                courseRoles: ['TeacherEnrollment', 'TaEnrollment', 'DesignerEnrollment'],
                id: 'role-user',
              }),
              groupSet: null,
            })
          }
          return Discussion.mock({
            author: User.mock({
              courseRoles: ['TeacherEnrollment', 'TaEnrollment', 'DesignerEnrollment'],
              id: 'role-user',
            }),
            discussionEntriesConnection: {
              nodes: [
                DiscussionEntry.mock({
                  _id: 'DiscussionEntry-default-mock',
                  id: 'DiscussionEntry-default-mock',
                }),
              ],
              pageInfo: PageInfo.mock(),
              __typename: 'DiscussionSubentriesConnection',
            },
          })
        })(),
      },
    },
    ...(shouldError && {error: new Error('graphql error')}),
  },
]

export const getAnonymousDiscussionQueryMock = ({
  discussionID = 'Discussion-default-mock',
  filter = 'all',
  page = 'MA==',
  perPage = 20,
  rootEntries = true,
  searchTerm = '',
  sort = 'desc',
  shouldError = false,
  unreadBefore = '',
} = {}) => [
  {
    request: {
      query: DISCUSSION_QUERY,
      variables: {
        discussionID,
        filter,
        page,
        perPage,
        rootEntries,
        searchTerm,
        sort,
        unreadBefore,
      },
    },
    result: {
      data: {
        legacyNode: (() => {
          return Discussion.mock({
            author: User.mock({
              courseRoles: ['TeacherEnrollment', 'TaEnrollment', 'DesignerEnrollment'],
              id: 'role-user',
            }),
            anonymousState: 'partial_anonymity',
            canReplyAnonymously: true,
            discussionEntriesConnection: {
              nodes: [
                DiscussionEntry.mock({
                  id: 'DiscussionEntry-anonymous-mock',
                  author: null,
                  anonymousAuthor: AnonymousUser.mock({shortName: 'current_user'}),
                }),
              ],
              pageInfo: PageInfo.mock(),
              __typename: 'DiscussionEntriesConnection',
            },
          })
        })(),
      },
    },
    ...(shouldError && {error: new Error('graphql error')}),
  },
]

export const getDiscussionSubentriesQueryMock = ({
  after = null,
  before = null,
  beforeRelativeEntry = null,
  discussionEntryID = 'DiscussionEntry-default-mock',
  first = null,
  includeRelativeEntry = null,
  last = null,
  relativeEntryId = null,
  sort = 'asc',
  shouldError = false,
} = {}) => [
  {
    request: {
      query: DISCUSSION_SUBENTRIES_QUERY,
      variables: {
        ...(after !== null && {after}),
        ...(before !== null && {before}),
        ...(beforeRelativeEntry !== null && {beforeRelativeEntry}),
        discussionEntryID,
        ...(first !== null && {first}),
        ...(includeRelativeEntry !== null && {includeRelativeEntry}),
        ...(last !== null && {last}),
        ...(relativeEntryId !== null && {relativeEntryId}),
        sort,
      },
    },
    result: {
      data: {
        legacyNode: (() => {
          if (includeRelativeEntry) {
            return DiscussionEntry.mock({
              id: discussionEntryID,
              _id: discussionEntryID,
              discussionSubentriesConnection: {
                nodes: [
                  DiscussionEntry.mock({
                    _id: '103',
                    id: 'RGlzY3Vzc2lvbkVudHJ5LTEwMwo=',
                    message: '<p>This is the search result child reply</p>',
                  }),
                ],
                pageInfo: PageInfo.mock(),
                __typename: 'DiscussionSubentriesConnection',
              },
            })
          }
          if (first !== null && first === 0) {
            return DiscussionEntry.mock({
              id: discussionEntryID,
              _id: discussionEntryID,
            })
          }
          if (sort === 'asc') {
            return DiscussionEntry.mock({
              id: discussionEntryID,
              _id: discussionEntryID,
              discussionSubentriesConnection: {
                nodes: [
                  DiscussionEntry.mock({
                    _id: '104',
                    id: 'RGlzY3Vzc2lvbkVudHJ5LTEwNAo=',
                    message: '<p>This is the child reply asc</p>',
                    rootEntryId: discussionEntryID,
                  }),
                ],
                pageInfo: PageInfo.mock(),
                __typename: 'DiscussionSubentriesConnection',
              },
            })
          }
          return DiscussionEntry.mock({
            id: discussionEntryID,
            _id: discussionEntryID,
            discussionSubentriesConnection: {
              nodes: [
                DiscussionEntry.mock({
                  _id: '105',
                  id: 'RGlzY3Vzc2lvbkVudHJ5LTEwNQo=',
                  message: '<p>This is the child reply</p>',
                }),
              ],
              pageInfo: PageInfo.mock(),
              __typename: 'DiscussionSubentriesConnection',
            },
          })
        })(),
      },
    },
    ...(shouldError && {error: new Error('graphql error')}),
  },
]

export const getDiscussionEntryAllRootEntriesQueryMock = ({
  discussionEntryID = 'DiscussionEntry-default-mock',
  shouldError = false,
} = {}) => [
  {
    request: {
      query: DISCUSSION_ENTRY_ALL_ROOT_ENTRIES_QUERY,
      variables: {
        discussionEntryID,
      },
    },
    result: {
      data: {
        legacyNode: {
          allRootEntries: [
            DiscussionEntry.mock({
              _id: '104',
              id: 'RGlzY3Vzc2lvbkVudHJ5LTEwNAo=',
              message: '<p>This is the child reply asc</p>',
              rootEntryId: discussionEntryID,
              parentId: 'DiscussionEntry-default-mock',
            }),
          ],
          __typename: 'DiscussionEntry',
        },
      },
    },
    ...(shouldError && {error: new Error('graphql error')}),
  },
]

/* Mutation Mocks */
export const deleteDiscussionEntryMock = ({id = 'DiscussionEntry-default-mock'} = {}) => [
  {
    request: {
      query: DELETE_DISCUSSION_ENTRY,
      variables: {id},
    },
    result: {
      data: {
        deleteDiscussionEntry: {
          discussionEntry: DiscussionEntry.mock({
            id,
            _id: id,
            deleted: true,
          }),
          errors: null,
          __typename: 'DeleteDiscussionEntryPayload',
        },
      },
    },
  },
]

export const updateDiscussionEntryParticipantMock = ({
  discussionEntryId = 'DiscussionEntry-default-mock',
  read = null,
  rating = null,
  forcedReadState = null,
  reportType = null,
  shouldError = false,
} = {}) => [
  {
    request: {
      query: UPDATE_DISCUSSION_ENTRY_PARTICIPANT,
      variables: {
        discussionEntryId,
        ...(read !== null && {read}),
        ...(rating !== null && {rating}),
        ...(forcedReadState !== null && {forcedReadState}),
        ...(reportType !== null && {reportType}),
      },
    },
    result: {
      data: {
        updateDiscussionEntryParticipant: {
          discussionEntry: DiscussionEntry.mock({
            id: discussionEntryId,
            _id: discussionEntryId,
            ratingSum: rating !== null && rating === 'liked' ? 1 : 0,
            entryParticipant: {
              rating: !!(rating !== null && rating === 'liked'),
              read: read !== null ? read : true,
              forcedReadState: forcedReadState !== null ? forcedReadState : false,
              reportType: reportType !== null ? reportType : null,
              __typename: 'EntryParticipant',
            },
          }),
          __typename: 'UpdateDiscussionEntryParticipantPayload',
        },
      },
    },
    ...(shouldError && {error: new Error('graphql error')}),
  },
]

export const updateDiscussionEntryMock = ({
  discussionEntryId = 'DiscussionEntry-default-mock',
  message = '<p>This is the parent reply</p>',
  fileId = '7',
  removeAttachment = !fileId,
} = {}) => [
  {
    request: {
      query: UPDATE_DISCUSSION_ENTRY,
      variables: {
        discussionEntryId,
        message,
        ...(fileId !== null && {fileId}),
        removeAttachment,
      },
    },
    result: {
      data: {
        updateDiscussionEntry: {
          discussionEntry: DiscussionEntry.mock({
            id: discussionEntryId,
            _id: discussionEntryId,
            message,
            attachment: removeAttachment ? null : Attachment.mock(),
          }),
          errors: null,
          __typename: 'UpdateDiscussionEntryPayload',
        },
      },
    },
  },
]

export const subscribeToDiscussionTopicMock = ({
  discussionTopicId = 'Discussion-default-mock',
  subscribed = true,
} = {}) => [
  {
    request: {
      query: SUBSCRIBE_TO_DISCUSSION_TOPIC,
      variables: {
        discussionTopicId,
        subscribed,
      },
    },
    result: {
      data: {
        subscribeToDiscussionTopic: {
          discussionTopic: Discussion.mock({
            id: discussionTopicId,
            _id: discussionTopicId,
            subscribed,
            groupSet: null,
          }),
          __typename: 'SubscribeToDiscussionTopicPayload',
        },
      },
    },
  },
]

export const createDiscussionEntryMock = ({
  discussionTopicId = 'Discussion-default-mock',
  message = '',
  parentEntryId = null,
  fileId = null,
  isAnonymousAuthor = false,
  quotedEntryId = undefined,
} = {}) => [
  {
    request: {
      query: CREATE_DISCUSSION_ENTRY,
      variables: {
        discussionTopicId,
        message,
        isAnonymousAuthor,
        ...(parentEntryId !== null && {parentEntryId}),
        ...(fileId !== null && {fileId}),
        ...(quotedEntryId !== undefined && {quotedEntryId}),
      },
    },
    result: {
      data: {
        createDiscussionEntry: {
          discussionEntry: DiscussionEntry.mock({
            id: 'DiscussionEntry-created-mock',
            _id: 'DiscussionEntry-created-mock',
            message,
          }),
          errors: null,
          __typename: 'CreateDiscussionEntryPayload',
        },
      },
    },
  },
]

export const updateUserDiscussionsSplitscreenViewMock = ({
  discussionsSplitscreenView = true,
} = {}) => [
  {
    request: {
      query: UPDATE_USER_DISCUSSION_SPLITSCREEN_PREFERENCE,
      variables: {
        discussionsSplitscreenView,
      },
    },
    result: {
      data: {
        updateUserDiscussionsSplitscreenView: {
          user: {
            discussionsSplitscreenView: true,
            __typename: 'User',
          },
          errors: null,
          __typename: 'updateUserDiscussionsSplitscreenViewPayload',
        },
        __typename: 'Mutation',
      },
    },
  },
]

export const deleteDiscussionTopicMock = ({id = 'Discussion-default-mock'} = {}) => [
  {
    request: {
      query: DELETE_DISCUSSION_TOPIC,
      variables: {id},
    },
    result: {
      data: {
        deleteDiscussionTopic: {
          discussionTopicId: id,
          errors: null,
          __typename: 'DeleteDiscussionTopicPayload',
        },
      },
    },
  },
]

export const updateDiscussionReadStateMock = ({
  discussionTopicId = 'Discussion-default-mock',
  read = true,
} = {}) => [
  {
    request: {
      query: UPDATE_DISCUSSION_READ_STATE,
      variables: {
        discussionTopicId,
        read,
      },
    },
    result: {
      data: {
        updateDiscussionReadState: {
          discussionTopic: Discussion.mock({
            id: btoa(`Discussion-${discussionTopicId}`),
            _id: discussionTopicId,
          }),
          __typename: 'UpdateDiscussionReadStatePayload',
        },
      },
    },
  },
]

export const updateDiscussionTopicMock = ({
  discussionTopicId = 'Discussion-default-mock',
  published = null,
  locked = null,
} = {}) => [
  {
    request: {
      query: UPDATE_DISCUSSION_TOPIC,
      variables: {
        discussionTopicId,
        ...(published !== null && {published}),
        ...(locked !== null && {locked}),
      },
    },
    result: {
      data: {
        updateDiscussionTopic: {
          discussionTopic: Discussion.mock({
            id: btoa(`Discussion-${discussionTopicId}`),
            _id: discussionTopicId,
          }),
          __typename: 'UpdateDiscussionTopicPayload',
        },
      },
    },
  },
]
