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
import {shape, string} from 'prop-types'
import {Conversation} from './Conversation'
import {ConversationParticipant} from './ConversationParticipant'
import {User} from './User'

export const ConversationParticipantWithConversation = {
  fragment: gql`
    fragment ConversationParticipantWithConversation on ConversationParticipant {
      ...ConversationParticipant
      conversation {
        ...Conversation
      }
    }
    ${ConversationParticipant.fragment}
    ${Conversation.fragment}
  `,

  shape: shape({
    _id: string,
    id: string,
    label: string,
    conversation: Conversation.shape,
    user: User.shape
  })
}

export const DefaultMocks = {
  ConversationParticipant: () => ({
    _id: 'mock_id',
    id: 'mockId',
    label: 'someLabel',
    conversation: {},
    user: {}
  })
}
