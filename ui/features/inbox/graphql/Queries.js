/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import gql from 'graphql-tag'

import {Conversation} from './Conversation'
import {ConversationMessage} from './ConversationMessage'
import {ConversationParticipant} from './ConversationParticipant'
import {Enrollment} from './Enrollment'
import {Course} from './Course'
import {Group} from './Group'

export const CONVERSATIONS_QUERY = gql`
  query GetConversationsQuery($userID: ID!, $course: String, $scope: String = "") {
    legacyNode(_id: $userID, type: User) {
      ... on User {
        _id
        id
        conversationsConnection(
          scope: $scope # e.g. archived
          filter: $course # e.g. course_1
        ) {
          nodes {
            ...ConversationParticipant
            conversation {
              ...Conversation
            }
          }
        }
      }
    }
  }
  ${ConversationParticipant.fragment}
  ${Conversation.fragment}
`
export const COURSES_QUERY = gql`
  query GetUserCourses($userID: ID!) {
    legacyNode(_id: $userID, type: User) {
      ... on User {
        id
        email
        favoriteGroupsConnection {
          nodes {
            ...Group
          }
        }
        favoriteCoursesConnection {
          nodes {
            ...Course
          }
        }
        enrollments {
          ...Enrollment
        }
      }
    }
  }
  ${Enrollment.fragment}
  ${Course.fragment}
  ${Group.fragment}
`

export const REPLY_CONVERSATION_QUERY = gql`
  query ReplyConversationQuery($conversationID: ID!, $participants: [ID!]) {
    legacyNode(_id: $conversationID, type: Conversation) {
      ... on Conversation {
        _id
        contextName
        subject
        conversationMessagesConnection(participants: $participants) {
          nodes {
            ...ConversationMessage
          }
        }
      }
    }
  }
  ${ConversationMessage.fragment}
`
