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

import {arrayOf, bool, number, shape, string} from 'prop-types'
import {ConversationMessage} from './ConversationMessage'
import {ConversationParticipant} from './ConversationParticipant'
import gql from 'graphql-tag'
import {PageInfo} from './PageInfo'
import {User} from './User'

export const Conversation = {
  fragment: gql`
    fragment Conversation on Conversation {
      _id
      id
      contextId
      contextType
      contextName
      contextAssetString
      subject
      canReply
      isPrivate
      conversationParticipantsConnection {
        nodes {
          ...ConversationParticipant
        }
      }
    }
    ${ConversationParticipant.fragment}
  `,

  shape: shape({
    _id: string,
    id: string,
    contextId: string,
    contextType: string,
    contextName: string,
    contextAssetString: string,
    subject: string,
    canReply: bool,
    isPrivate: bool,
    conversationMessagesConnection: shape({
      nodes: arrayOf(ConversationMessage.shape),
    }),
    conversationMessagesCount: number,
    conversationParticipantsConnection: shape({
      nodes: arrayOf(ConversationParticipant.shape),
    }),
  }),

  mock: ({
    _id = '196',
    id = 'Q29udmVyc2F0aW9uLTE5Ng==',
    contextId = '195',
    contextType = 'Course',
    contextName = 'XavierSchool',
    contextAssetString = 'course_195',
    subject = 'testing 123',
    canReply = true,
    isPrivate = false,
    conversationMessagesConnection = {
      nodes: [
        ConversationMessage.mock(),
        ConversationMessage.mock({
          _id: '2695',
          id: 'Q29udmVyc2F0aW9uTWVzc2FnZS0yNjk1',
          createdAt: '2021-02-01T12:28:22-07:00',
          body: 'this is a reply all',
          recipients: [
            User.mock({_id: '10', name: 'Bobby Drake'}),
            User.mock({_id: '11', name: 'Warren Worthington'}),
            User.mock({_id: '8', name: 'Scotty Summers'}),
          ],
        }),
        ConversationMessage.mock({
          _id: '2694',
          id: 'Q29udmVyc2F0aW9uTWVzc2FnZS0yNjk0',
          createdAt: '2021-02-01T12:12:52-07:00',
          body: 'testing 123',
          recipients: [
            User.mock({_id: '10', name: 'Bobby Drake'}),
            User.mock({_id: '11', name: 'Warren Worthington'}),
            User.mock({_id: '8', name: 'Scotty Summers'}),
          ],
        }),
      ],
      pageInfo: PageInfo.mock({hasNextPage: false}),
      __typename: 'ConversationMessageConnection',
    },
    conversationMessagesCount = 3,
    conversationParticipantsConnection = {
      nodes: [
        ConversationParticipant.mock({
          _id: '252',
          id: 'Q29udmVyc2F0aW9uUGFydGljaXBhbnQtMjUy',
          user: User.mock({_id: '8', name: 'Scotty Summers'}),
        }),
        ConversationParticipant.mock({
          _id: '254',
          id: 'Q29udmVyc2F0aW9uUGFydGljaXBhbnQtMjU0',
          user: User.mock({_id: '10', name: 'Bobby Drake'}),
          workflowState: 'unread',
        }),
        ConversationParticipant.mock({
          _id: '253',
          id: 'Q29udmVyc2F0aW9uUGFydGljaXBhbnQtMjUz',
          user: User.mock({_id: '11', name: 'Warren Worthington'}),
          workflowState: 'unread',
        }),
        ConversationParticipant.mock(),
      ],
      __typename: 'ConversationParticipantConnection',
    },
  } = {}) => ({
    _id,
    id,
    contextId,
    contextType,
    contextName,
    contextAssetString,
    subject,
    conversationMessagesConnection,
    conversationMessagesCount,
    conversationParticipantsConnection,
    canReply,
    isPrivate,
    __typename: 'Conversation',
  }),
}
