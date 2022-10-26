/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {arrayOf, bool, shape, string} from 'prop-types'
import {SubmissionCommentFile} from './File'
import gql from 'graphql-tag'
import {MediaObject} from './MediaObject'
import {SubmissionCommentAuthor} from './User'

export const SubmissionComment = {
  fragment: gql`
    fragment SubmissionComment on SubmissionComment {
      _id
      attachments {
        ...SubmissionCommentFile
      }
      author {
        ...SubmissionCommentAuthor
      }
      comment
      mediaObject {
        ...MediaObject
      }
      read
      updatedAt
    }
    ${MediaObject.fragment}
    ${SubmissionCommentAuthor.fragment}
    ${SubmissionCommentFile.fragment}
  `,

  shape: shape({
    _id: string,
    attachments: arrayOf(SubmissionCommentFile.shape),
    author: SubmissionCommentAuthor.shape,
    comment: string,
    mediaObject: MediaObject.shape,
    read: bool,
    updatedAt: string,
  }),
}

export const DefaultMocks = {
  SubmissionComment: () => {
    return {
      _id: 1,
      attachments: [{}],
      read: true,
    }
  },
}
