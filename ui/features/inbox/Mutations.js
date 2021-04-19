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

import {ConversationMessage} from './graphql/ConversationMessage'
import {ConversationParticipant} from './graphql/ConversationParticipant'
import {ConversationParticipantWithConversation} from './graphql/ConversationParticipantWithConversation'
import {Error} from '../../shared/graphql/Error'
import gql from 'graphql-tag'

export const UPDATE_CONVERSATION_PARTICIPANTS = gql`
  mutation UpdateConversationParticipants(
    $conversationIds: [ID!]!
    $starred: Boolean
    $subscribed: Boolean
    $workflowState: String
  ) {
    updateConversationParticipants(
      input: {
        conversationIds: $conversationIds
        starred: $starred
        subscribed: $subscribed
        workflowState: $workflowState
      }
    ) {
      conversationParticipants {
        ...ConversationParticipant
      }
      errors {
        message
      }
    }
  }
  ${ConversationParticipant.fragment}
`

export const DELETE_CONVERSATIONS = gql`
  mutation DeleteConversations($ids: [ID!]!) {
    deleteConversations(input: {ids: $ids}) {
      conversationIds
      errors {
        message
      }
    }
  }
`

export const CREATE_CONVERSATION = gql`
  mutation CreateConversation(
    $attachmentIds: [ID!]
    $body: String!
    $contextCode: String
    $conversationId: ID
    $groupConversation: Boolean
    $mediaCommentId: ID
    $mediaCommentType: String
    $recipients: [String!]!
    $subject: String
    $tags: [String!]
    $userNote: Boolean
  ) {
    createConversation(
      input: {
        attachmentIds: $attachmentIds
        body: $body
        contextCode: $contextCode
        conversationId: $conversationId
        groupConversation: $groupConversation
        mediaCommentId: $mediaCommentId
        mediaCommentType: $mediaCommentType
        recipients: $recipients
        subject: $subject
        tags: $tags
        userNote: $userNote
      }
    ) {
      conversations {
        ...ConversationParticipantWithConversation
      }
      errors {
        ...Error
      }
    }
  }
  ${Error.fragment}
  ${ConversationParticipantWithConversation.fragment}
`

export const ADD_CONVERSATION_MESSAGE = gql`
  mutation AddConversationMessage(
    $attachmentIds: [ID!]
    $body: String!
    $conversationId: ID!
    $includedMessages: [ID!]
    $mediaCommentId: ID
    $mediaCommentType: String
    $recipients: [String!]!
  ) {
    addConversationMessage(
      input: {
        attachmentIds: $attachmentIds
        body: $body
        conversationId: $conversationId
        includedMessages: $includedMessages
        mediaCommentId: $mediaCommentId
        mediaCommentType: $mediaCommentType
        recipients: $recipients
      }
    ) {
      conversationMessage {
        ...ConversationMessage
      }
      errors {
        ...Error
      }
    }
  }
  ${Error.fragment}
  ${ConversationMessage.fragment}
`
