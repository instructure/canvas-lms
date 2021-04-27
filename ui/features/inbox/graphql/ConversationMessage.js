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
      nodes: arrayOf(Attachment.shape)
    }),
    author: User.shape,
    mediaComment: MediaComment.shape,
    recipients: arrayOf(User.shape)
  })
}

export const DefaultMocks = {
  ConversationMessage: () => ({
    _id: '1a',
    body: 'This is the body of a mocked message',
    createdAt: 'November 5, 2020 at 2:25pm'
  })
}
