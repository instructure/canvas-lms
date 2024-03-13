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
import {DiscussionEntry} from './DiscussionEntry'
import {Discussion} from './Discussion'
import {Error} from '../../../shared/graphql/Error'
import gql from 'graphql-tag'
import {User} from './User'

export const DELETE_DISCUSSION_TOPIC = gql`
  mutation DeleteDiscussionTopic($id: ID!) {
    deleteDiscussionTopic(input: {id: $id}) {
      discussionTopicId
      errors {
        ...Error
      }
    }
  }
  ${Error.fragment}
`

export const UPDATE_DISCUSSION_ENTRY_PARTICIPANT = gql`
  mutation UpdateDiscussionEntryParticipant(
    $discussionEntryId: ID!
    $read: Boolean
    $rating: RatingInputType
    $forcedReadState: Boolean
    $reportType: ReportType
  ) {
    updateDiscussionEntryParticipant(
      input: {
        discussionEntryId: $discussionEntryId
        read: $read
        rating: $rating
        forcedReadState: $forcedReadState
        reportType: $reportType
      }
    ) {
      discussionEntry {
        ...DiscussionEntry
      }
    }
  }
  ${DiscussionEntry.fragment}
`
export const DELETE_DISCUSSION_ENTRY = gql`
  mutation DeleteDiscussionEntry($id: ID!) {
    deleteDiscussionEntry(input: {id: $id}) {
      discussionEntry {
        ...DiscussionEntry
      }
      errors {
        ...Error
      }
    }
  }
  ${DiscussionEntry.fragment}
  ${Error.fragment}
`
export const UPDATE_DISCUSSION_TOPIC = gql`
  mutation updateDiscussionTopic($discussionTopicId: ID!, $published: Boolean, $locked: Boolean) {
    updateDiscussionTopic(
      input: {discussionTopicId: $discussionTopicId, published: $published, locked: $locked}
    ) {
      discussionTopic {
        ...Discussion
      }
    }
  }
  ${Discussion.fragment}
`
export const SUBSCRIBE_TO_DISCUSSION_TOPIC = gql`
  mutation subscribeToDiscussionTopic($discussionTopicId: ID!, $subscribed: Boolean!) {
    subscribeToDiscussionTopic(
      input: {discussionTopicId: $discussionTopicId, subscribed: $subscribed}
    ) {
      discussionTopic {
        ...Discussion
      }
    }
  }
  ${Discussion.fragment}
`

export const CREATE_DISCUSSION_ENTRY = gql`
  mutation CreateDiscussionEntry(
    $discussionTopicId: ID!
    $message: String!
    $parentEntryId: ID
    $fileId: ID
    $isAnonymousAuthor: Boolean
    $quotedEntryId: ID
  ) {
    createDiscussionEntry(
      input: {
        discussionTopicId: $discussionTopicId
        message: $message
        parentEntryId: $parentEntryId
        fileId: $fileId
        isAnonymousAuthor: $isAnonymousAuthor
        quotedEntryId: $quotedEntryId
      }
    ) {
      discussionEntry {
        ...DiscussionEntry
        anonymousAuthor {
          ...AnonymousUser
        }
      }
      errors {
        ...Error
      }
    }
  }
  ${AnonymousUser.fragment}
  ${DiscussionEntry.fragment}
  ${Error.fragment}
`

export const UPDATE_DISCUSSION_ENTRY = gql`
  mutation UpdateDiscussionEntry(
    $discussionEntryId: ID!
    $message: String
    $fileId: ID
    $removeAttachment: Boolean
  ) {
    updateDiscussionEntry(
      input: {
        discussionEntryId: $discussionEntryId
        message: $message
        fileId: $fileId
        removeAttachment: $removeAttachment
      }
    ) {
      discussionEntry {
        ...DiscussionEntry
      }
      errors {
        ...Error
      }
    }
  }
  ${DiscussionEntry.fragment}
  ${Error.fragment}
`

export const UPDATE_DISCUSSION_ENTRIES_READ_STATE = gql`
  mutation UpdateDiscussionEntriesReadState($discussionEntryIds: [ID!]!, $read: Boolean!) {
    updateDiscussionEntriesReadState(
      input: {discussionEntryIds: $discussionEntryIds, read: $read}
    ) {
      discussionEntries {
        ...DiscussionEntry
      }
    }
  }
  ${DiscussionEntry.fragment}
`

export const UPDATE_DISCUSSION_THREAD_READ_STATE = gql`
  mutation UpdateDiscussionThreadReadState($discussionEntryId: ID!, $read: Boolean!) {
    updateDiscussionThreadReadState(input: {discussionEntryId: $discussionEntryId, read: $read}) {
      discussionEntry {
        ...DiscussionEntry
      }
    }
  }
  ${DiscussionEntry.fragment}
`

export const UPDATE_DISCUSSION_READ_STATE = gql`
  mutation UpdateDiscussionReadState($discussionTopicId: ID!, $read: Boolean!) {
    updateDiscussionReadState(input: {discussionTopicId: $discussionTopicId, read: $read}) {
      discussionTopic {
        ...Discussion
      }
    }
  }
  ${Discussion.fragment}
`

export const UPDATE_SPLIT_SCREEN_VIEW_DEEPLY_NESTED_ALERT = gql`
  mutation UpdateSplitScreenViewDeeplyNestedAlert($splitScreenViewDeeplyNestedAlert: Boolean!) {
    UpdateSplitScreenViewDeeplyNestedAlert(
      input: {splitScreenViewDeeplyNestedAlert: $splitScreenViewDeeplyNestedAlert}
    ) {
      user {
        ...User
      }
    }
  }
  ${User.fragment}
`

export const UPDATE_USER_GRADE = gql`
  mutation UpdateUserGrade($submissionId: ID!, $score: Int!) {
    __typename
    updateSubmissionGrade(input: {submissionId: $submissionId, score: $score}) {
      submission {
        _id
        id
        grade
        score
        user {
          _id
          id
          name
        }
      }
    }
  }
`
export const UPDATE_USER_DISCUSSION_SPLITSCREEN_PREFERENCE = gql`
  mutation UpdateUserDiscussionsSplitscreenView($discussionsSplitscreenView: Boolean!) {
    __typename
    updateUserDiscussionsSplitscreenView(
      input: {discussionsSplitscreenView: $discussionsSplitscreenView}
    ) {
      user {
        discussionsSplitscreenView
      }
    }
  }
`
