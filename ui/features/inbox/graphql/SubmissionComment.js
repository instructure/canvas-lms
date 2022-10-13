/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {shape, string, bool, number} from 'prop-types'
import {User} from './User'
import {Assignment} from './Assignment'
import {Course} from './Course'

export const SubmissionComment = {
  fragment: gql`
    fragment SubmissionComment on SubmissionComment {
      _id
      id
      submissionId
      createdAt
      attempt
      author {
        ...User
      }
      assignment {
        ...Assignment
      }
      comment
      course {
        ...Course
      }
      read
    }
    ${User.fragment}
    ${Assignment.fragment}
    ${Course.fragment}
  `,

  shape: shape({
    _id: string,
    id: string,
    submissionId: string,
    createdAt: string,
    attempt: number,
    author: User.shape,
    assignment: Assignment.shape,
    comment: string,
    course: Course.shape,
    read: bool,
  }),

  mock: ({
    _id = '9',
    id = 'U3VibWlzc2lvbkNvbW1lbnQtOQ==',
    submissionId = '15',
    createdAt = '2022-02-15T06:50:54-07:00',
    attempt = 0,
    author = User.mock(),
    assignment = Assignment.mock(),
    comment = 'Hey!',
    course = Course.mock(),
    read = true,
  } = {}) => ({
    _id,
    id,
    submissionId,
    createdAt,
    attempt,
    author,
    assignment,
    comment,
    course,
    read,
    __typename: 'SubmissionComment',
  }),
}
