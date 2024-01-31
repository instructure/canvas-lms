/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {Error} from '../../../shared/graphql/Error'
import gql from 'graphql-tag'
import {Attachment} from './Attachment'

export const CREATE_DISCUSSION_TOPIC = gql`
  mutation CreateDiscussionTopic(
    $contextId: ID!
    $contextType: DiscussionTopicContextType!
    $title: String
    $message: String
    $published: Boolean
    $requireInitialPost: Boolean
    $anonymousState: DiscussionTopicAnonymousStateType
    $delayedPostAt: DateTime
    $lockAt: DateTime
    $isAnonymousAuthor: Boolean
    $allowRating: Boolean
    $onlyGradersCanRate: Boolean
    $todoDate: DateTime
    $podcastEnabled: Boolean
    $podcastHasStudentPosts: Boolean
    $locked: Boolean
    $isAnnouncement: Boolean
    $specificSections: String
    $groupCategoryId: ID
    $assignment: AssignmentCreate
    $fileId: ID
  ) {
    createDiscussionTopic(
      input: {
        contextId: $contextId
        contextType: $contextType
        title: $title
        message: $message
        published: $published
        requireInitialPost: $requireInitialPost
        anonymousState: $anonymousState
        delayedPostAt: $delayedPostAt
        lockAt: $lockAt
        isAnonymousAuthor: $isAnonymousAuthor
        allowRating: $allowRating
        onlyGradersCanRate: $onlyGradersCanRate
        todoDate: $todoDate
        podcastEnabled: $podcastEnabled
        podcastHasStudentPosts: $podcastHasStudentPosts
        locked: $locked
        isAnnouncement: $isAnnouncement
        specificSections: $specificSections
        groupCategoryId: $groupCategoryId
        assignment: $assignment
        fileId: $fileId
      }
    ) {
      discussionTopic {
        _id
        contextType
        title
        message
        published
        requireInitialPost
        anonymousState
        delayedPostAt
        lockAt
        isAnonymousAuthor
        allowRating
        onlyGradersCanRate
        todoDate
        podcastEnabled
        podcastHasStudentPosts
        isAnnouncement
        assignment {
          _id
          name
          pointsPossible
          gradingType
          assignmentGroupId
          canDuplicate
          canUnpublish
          courseId
          description
          dueAt
          groupCategoryId
          id
          published
          restrictQuantitativeData
          sisId
          state
          peerReviews {
            automaticReviews
            count
            dueAt
            enabled
          }
        }
        attachment {
          ...Attachment
        }
      }
      errors {
        ...Error
      }
    }
  }
  ${Attachment.fragment}
  ${Error.fragment}
`

export const UPDATE_DISCUSSION_TOPIC = gql`
  mutation UpdateDiscussionTopic(
    $discussionTopicId: ID!
    $title: String
    $message: String
    $published: Boolean
    $requireInitialPost: Boolean
    $delayedPostAt: DateTime
    $lockAt: DateTime
    $allowRating: Boolean
    $onlyGradersCanRate: Boolean
    $todoDate: DateTime
    $podcastEnabled: Boolean
    $podcastHasStudentPosts: Boolean
    $locked: Boolean
    $specificSections: String
    $fileId: ID
    $groupCategoryId: ID
    $removeAttachment: Boolean
    $assignment: AssignmentUpdate
  ) {
    updateDiscussionTopic(
      input: {
        discussionTopicId: $discussionTopicId
        title: $title
        message: $message
        published: $published
        requireInitialPost: $requireInitialPost
        delayedPostAt: $delayedPostAt
        lockAt: $lockAt
        allowRating: $allowRating
        onlyGradersCanRate: $onlyGradersCanRate
        todoDate: $todoDate
        podcastEnabled: $podcastEnabled
        podcastHasStudentPosts: $podcastHasStudentPosts
        locked: $locked
        specificSections: $specificSections
        groupCategoryId: $groupCategoryId
        fileId: $fileId
        removeAttachment: $removeAttachment
        assignment: $assignment
      }
    ) {
      discussionTopic {
        _id
        contextType
        title
        message
        published
        requireInitialPost
        anonymousState
        delayedPostAt
        lockAt
        isAnonymousAuthor
        allowRating
        onlyGradersCanRate
        todoDate
        podcastEnabled
        podcastHasStudentPosts
        isAnnouncement
        attachment {
          ...Attachment
        }
        assignment {
          _id
          name
          pointsPossible
          gradingType
          assignmentGroupId
          canDuplicate
          canUnpublish
          courseId
          description
          dueAt
          groupCategoryId
          id
          published
          restrictQuantitativeData
          sisId
          state
          peerReviews {
            automaticReviews
            count
            dueAt
            enabled
          }
        }
      }
      errors {
        ...Error
      }
    }
  }
  ${Attachment.fragment}
  ${Error.fragment}
`

export const CREATE_GROUP_CATEGORY = gql`
  mutation CreateGroupCategory(
    $contextId: ID!
    $contextType: String!
    $name: String
    $selfSignup: String
    $numberOfGroups: Int
    $numberOfStudentsPerGroup: Int
    $autoLeader: String
    $randomlyAssignBySection: Boolean
    $randomlyAssignSynchronously: Boolean
  ) {
    createGroupCategory(
      input: {
        contextId: $contextId
        contextType: $contextType
        name: $name
        selfSignup: $selfSignup
        numberOfGroups: $numberOfGroups
        numberOfStudentsPerGroup: $numberOfStudentsPerGroup
        autoLeader: $autoLeader
        randomlyAssignBySection: $randomlyAssignBySection
        randomlyAssignSynchronously: $randomlyAssignSynchronously
      }
    ) {
      groupCategory {
        _id
        id
      }
      errors {
        ...Error
      }
    }
  }
  ${Error.fragment}
`
