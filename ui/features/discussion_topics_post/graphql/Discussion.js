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

import {arrayOf, bool, number, shape, string} from 'prop-types'
import {AnonymousUser} from './AnonymousUser'
import {Assignment} from './Assignment'
import {Attachment} from './Attachment'
import {Section} from './Section'
import {DiscussionPermissions} from './DiscussionPermissions'
import gql from 'graphql-tag'
import {User} from './User'
import {DiscussionEntry} from './DiscussionEntry'
import {PageInfo} from './PageInfo'
import {ChildTopic} from './ChildTopic'
import {RootTopic} from './RootTopic'
import {GroupSet} from './GroupSet'

export const Discussion = {
  fragment: gql`
    fragment Discussion on Discussion {
      id
      _id
      title
      message
      createdAt
      updatedAt
      postedAt
      requireInitialPost
      initialPostRequiredForCurrentUser
      isSectionSpecific
      isAnnouncement
      discussionType
      anonymousState
      allowRating
      onlyGradersCanRate
      delayedPostAt
      subscribed
      published
      canUnpublish
      canReplyAnonymously
      lockAt
      availableForUser
      userCount
      editor {
        ...User
      }
      author {
        ...User
      }
      entryCounts {
        unreadCount
        repliesCount
      }
      attachment {
        ...Attachment
      }
      assignment {
        ...Assignment
      }
      permissions {
        ...DiscussionPermissions
      }
      courseSections {
        ...Section
      }
      childTopics {
        ...ChildTopic
      }
      groupSet {
        ...GroupSet
      }
      rootTopic {
        ...RootTopic
      }
    }
    ${User.fragment}
    ${Attachment.fragment}
    ${Assignment.fragment}
    ${DiscussionPermissions.fragment}
    ${Section.fragment}
    ${ChildTopic.fragment}
    ${GroupSet.fragment}
    ${RootTopic.fragment}
  `,

  shape: shape({
    id: string,
    _id: string,
    title: string,
    message: string,
    createdAt: string,
    updatedAt: string,
    postedAt: string,
    requireInitialPost: bool,
    initialPostRequiredForCurrentUser: bool,
    isSectionSpecific: bool,
    isAnnouncement: bool,
    discussionType: string,
    anonymousState: string,
    allowRating: bool,
    onlyGradersCanRate: bool,
    delayedPostAt: string,
    lockAt: string,
    subscribed: bool,
    published: bool,
    canUnpublish: bool,
    canReplyAnonymously: bool,
    searchEntryCount: number,
    availableForUser: bool,
    userCount: number,
    entryCounts: shape({
      unreadCount: number,
      repliesCount: number,
    }),
    author: User.shape,
    anonymousAuthor: AnonymousUser.shape,
    editor: User.shape,
    attachment: Attachment.shape,
    assignment: Assignment.shape,
    permissions: DiscussionPermissions.shape,
    courseSections: arrayOf(Section.shape),
    childTopics: arrayOf(ChildTopic.shape),
    groupSet: GroupSet.shape,
    rootTopic: RootTopic.shape,
    rootEntriesTotalPages: number,
    entriesTotalPages: number,
  }),

  mock: ({
    id = 'Discussion-default-mock',
    _id = 'Discussion-default-mock',
    title = 'X-Men Powers Discussion',
    message = 'This is a Discussion Topic Message',
    createdAt = '2020-11-23T11:40:44-07:00',
    updatedAt = '2021-04-22T12:41:56-06:00',
    postedAt = '2020-11-23T11:40:44-07:00',
    requireInitialPost = false,
    initialPostRequiredForCurrentUser = false,
    isSectionSpecific = false,
    isAnnouncement = false,
    discussionType = 'threaded',
    anonymousState = null,
    allowRating = true,
    onlyGradersCanRate = false,
    delayedPostAt = null,
    lockAt = null,
    subscribed = true,
    published = true,
    canUnpublish = false,
    canReplyAnonymously = false,
    searchEntryCount = 3,
    availableForUser = true,
    userCount = 4,
    entryCounts = {
      unreadCount: 2,
      repliesCount: 56,
      __typename: 'DiscussionEntryCounts',
    },
    author = User.mock({_id: '1', displayName: 'Charles Xavier'}),
    anonymousAuthor = null,
    editor = User.mock({_id: '1', displayName: 'Charles Xavier'}),
    attachment = Attachment.mock(),
    assignment = Assignment.mock(),
    permissions = DiscussionPermissions.mock(),
    courseSections = [Section.mock()],
    childTopics = [ChildTopic.mock()],
    groupSet = GroupSet.mock(),
    rootTopic = RootTopic.mock(),
    entriesTotalPages = 2,
    discussionEntriesConnection = {
      nodes: [DiscussionEntry.mock()],
      pageInfo: PageInfo.mock(),
      __typename: 'DiscussionEntriesConnection',
    },
  } = {}) => ({
    id,
    _id,
    title,
    message,
    createdAt,
    updatedAt,
    postedAt,
    requireInitialPost,
    initialPostRequiredForCurrentUser,
    isSectionSpecific,
    isAnnouncement,
    discussionType,
    anonymousState,
    allowRating,
    onlyGradersCanRate,
    delayedPostAt,
    lockAt,
    subscribed,
    published,
    canUnpublish,
    canReplyAnonymously,
    entryCounts,
    availableForUser,
    userCount,
    author,
    anonymousAuthor,
    editor,
    attachment,
    assignment,
    permissions,
    courseSections,
    childTopics,
    groupSet,
    rootTopic,
    searchEntryCount,
    entriesTotalPages,
    discussionEntriesConnection,
    __typename: 'Discussion',
  }),
}

export const DefaultMocks = {
  Discussion: () => ({
    _id: '1',
    title: 'This is a Title',
  }),
}
