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

import {ConversationParticipantWithConversation} from './graphqlData/ConversationParticipantWithConversation'
import {Enrollments} from './graphqlData/Enrollments'
import {FavoriteCoursesConnection} from './graphqlData/FavoriteCoursesConnection'
import {FavoriteGroupsConnection} from './graphqlData/FavoriteGroupsConnection'

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
            ...ConversationParticipantWithConversation
          }
        }
      }
    }
  }
  ${ConversationParticipantWithConversation.fragment}
`
export const COURSES_QUERY = gql`
  query GetUserCourses($userID: ID!) {
    legacyNode(_id: $userID, type: User) {
      ... on User {
        id
        email
        favoriteGroupsConnection {
          nodes {
            ...FavoriteGroupsConnection
          }
        }
        favoriteCoursesConnection {
          nodes {
            ...FavoriteCoursesConnection
          }
        }
        enrollments {
          ...Enrollments
        }
      }
    }
  }
  ${Enrollments.fragment}
  ${FavoriteCoursesConnection.fragment}
  ${FavoriteGroupsConnection.fragment}
`

export const REPLY_CONVERSATION_QUERY = gql`
  query ReplyConversationQuery($conversationID: ID!, $participants: [ID!]) {
    legacyNode(_id: $conversationID, type: Conversation) {
      ... on Conversation {
        _id
        id
        contextName
        subject
        conversationMessagesConnection(participants: $participants) {
          nodes {
            body
            createdAt
            author {
              name
            }
          }
        }
      }
    }
  }
`
