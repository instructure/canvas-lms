/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {string} from 'prop-types'

export const SubmissionComment = {
  fragment: gql`
    fragment SubmissionComment on SubmissionComment {
      _id
      comment
      createdAt
      author {
        name
        shortName
      }
    }
  `,
  shape: {
    _id: string,
    comment: string,
    createdAt: string,
    author: {
      name: string,
      shortName: string,
    },
  },
  mock: ({
    _id = '1',
    comment = 'This is a comment',
    createdAt = '2019-01-01T00:00:00Z',
    author = {
      name: 'John Doe',
      shortName: 'JD',
    },
  } = {}) => ({
    _id,
    comment,
    createdAt,
    author,
    __typename: 'Comment',
  }),
}
