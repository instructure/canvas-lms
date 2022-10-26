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

import {arrayOf, shape, string} from 'prop-types'
import {Attachment} from './Attachment'
import gql from 'graphql-tag'
import {MediaComment} from './MediaComment'
import {User} from './User'

export const ConversationMessage = {
  fragment: gql`
    fragment ConversationMessage on ConversationMessage {
      _id
      id
      createdAt
      body
      attachmentsConnection {
        nodes {
          ...Attachment
        }
      }
      author {
        ...User
      }
      mediaComment {
        ...MediaComment
      }
      recipients {
        ...User
      }
    }
    ${Attachment.fragment}
    ${User.fragment}
    ${MediaComment.fragment}
  `,

  shape: shape({
    _id: string,
    id: string,
    createdAt: string,
    body: string,
    attachmentsConnection: shape({
      nodes: arrayOf(Attachment.shape),
    }),
    author: User.shape,
    mediaComment: MediaComment.shape,
    recipients: arrayOf(User.shape),
  }),

  mock: ({
    _id = '2696',
    id = 'Q29udmVyc2F0aW9uTWVzc2FnZS0yNjk2',
    createdAt = '2021-02-01T12:28:57-07:00',
    body = 'this is the first reply message',
    attachmentsConnection = {
      nodes: [Attachment.mock()],
      __typename: 'FileConnection',
    },
    author = User.mock(),
    mediaComment = MediaComment.mock(),
    recipients = [User.mock({_id: '8', pronouns: 'They/Them', name: 'Scotty Summers'})],
  } = {}) => ({
    _id,
    id,
    createdAt,
    body,
    attachmentsConnection,
    author,
    mediaComment,
    recipients,
    __typename: 'ConversationMessage',
  }),
}
