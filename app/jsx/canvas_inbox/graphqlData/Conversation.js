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
import {number, shape, string} from 'prop-types'
import {ConversationMessage} from './ConversationMessage'
import {ConversationParticipant} from './ConversationParticipant'

export const Conversation = {
  fragment: gql`
    fragment Conversation on Conversation {
      _id
      contextId
      contextType
      contextName
      subject
      conversationMessagesConnection {
        nodes {
          ...ConversationMessage
        }
      }
      conversationParticipantsConnection {
        nodes {
          ...ConversationParticipant
        }
      }
    }
    ${ConversationMessage.fragment}
    ${ConversationParticipant.fragment}
  `,

  shape: shape({
    _id: string,
    contextId: number,
    contextType: string,
    contextName: string,
    subject: string,
    conversationMessagesConnection: ConversationMessage.shape,
    conversationParticipantsConnection: ConversationParticipant.shape,
  }),
}

export const DefaultMocks = {
  Conversation: () => ({
    _id: '1a',
    contextType: 'context',
    contextId: 2,
    contextName: 'Context Name',
    subject: 'Mock Subject',
    updatedAt: 'November 5, 2020 at 2:25pm',
    conversationMessagesConnection: {edges: [{}]},
    conversationParticipantsConnection: {edges: [{}]},
  }),
}
