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
import {Attachment} from './Attachment'
import {User} from './User'
import {MediaComment} from './MediaComment'

export const ConversationMessage = {
  fragment: gql`
    fragment ConversationMessage on ConversationMessage {
      _id
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
    }
    ${Attachment.fragment}
    ${User.fragment}
    ${MediaComment.fragment}
  `,

  shape: shape({
    _id: string,
    createdAt: string,
    body: string,
    attachmentsConnection: Attachment.shape,
    author: User.shape,
    mediaComment: MediaComment.shape
  })
}
