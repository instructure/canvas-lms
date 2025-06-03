/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {z} from 'zod'
import {executeQuery} from '@canvas/graphql'
import {gql} from '@apollo/client'

export const CREATE_COMMENT_MUTATION = gql`
  mutation CreateCommentBankItem($courseId: ID!, $comment: String!) {
    createCommentBankItem(input: {courseId: $courseId, comment: $comment}) {
      commentBankItem {
        id: _id
        comment
      }
      errors {
        attribute
        message
      }
    }
  }
`

export const ZCreateSubmissionCommentParams = z.object({
  courseId: z.string(),
  comment: z.string(),
})

type CreateSubmissionCommentParams = z.infer<typeof ZCreateSubmissionCommentParams>

export async function createCommentBankItem({
  courseId,
  comment,
}: CreateSubmissionCommentParams): Promise<any> {
  const result = executeQuery<any>(CREATE_COMMENT_MUTATION, {
    courseId,
    comment,
  })

  return result
}
