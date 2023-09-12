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

export const CREATE_DISCUSSION_TOPIC = gql`
  mutation CreateDiscussionTopic(
    $contextId: ID!
    $contextType: String!
    $title: String
    $message: String
    $published: Boolean
    $requireInitialPost: Boolean
    $anonymousState: String
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
      }
    ) {
      discussionTopic {
        _id
        contextType
        title
        message
        published
        anonymousState
      }
      errors {
        ...Error
      }
    }
  }
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
