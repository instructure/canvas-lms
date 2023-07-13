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

import {Error} from '../../../shared/graphql/Error'
import gql from 'graphql-tag'

export const CREATE_DISCUSSION_TOPIC = gql`
  mutation CreateDiscussionTopic(
    $contextId: ID!
    $contextType: String!
    $isAnnouncement: Boolean!
    $title: String
    $message: String
    $discussionType: String
    $delayedPostAt: ISO8601DateTime
    $lockAt: ISO8601DateTime
    $podcastEnabled: Boolean
    $podcastHasStudentPosts: Boolean
    $requireInitialPost: Boolean
    $pinned: Boolean
    $todoDate: ISO8601DateTime
    $groupCategoryId: ID
    $allowRating: Boolean
    $onlyGradersCanRate: Boolean
    $sortByRating: Boolean
    $anonymousState: String
    $isAnonymousAuthor: Boolean
    $specificSections: [String!]
    $locked: Boolean
    $published: Boolean
  ) {
    createDiscussionTopic(
      input: {
        contextId: $contextId
        contextType: $contextType
        isAnnouncement: $isAnnouncement
        title: $title
        message: $message
        discussionType: $discussionType
        delayedPostAt: $delayedPostAt
        lockAt: $lockAt
        podcastEnabled: $podcastEnabled
        podcastHasStudentPosts: $podcastHasStudentPosts
        requireInitialPost: $requireInitialPost
        pinned: $pinned
        todoDate: $todoDate
        groupCategoryId: $groupCategoryId
        allowRating: $allowRating
        onlyGradersCanRate: $onlyGradersCanRate
        sortByRating: $sortByRating
        anonymousState: $anonymousState
        isAnonymousAuthor: $isAnonymousAuthor
        specificSections: $specificSections
        locked: $locked
        published: $published
      }
    ) {
      discussionTopic {
        _id
        contextType
      }
      errors {
        ...Error
      }
    }
  }
  ${Error.fragment}
`
