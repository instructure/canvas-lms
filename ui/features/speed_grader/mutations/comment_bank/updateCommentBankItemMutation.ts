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

export const UPDATE_COMMENT_MUTATION = gql`
  mutation UpdateCommentBankItem($id: ID!, $comment: String!) {
    updateCommentBankItem(input: {id: $id, comment: $comment}) {
      commentBankItem {
        _id
        comment
      }
      errors {
        attribute
        message
      }
    }
  }
`

export const ZUpdateSubmissionCommentParams = z.object({
  id: z.string(),
  comment: z.string(),
})

type UpdateSubmissionCommentParams = z.infer<typeof ZUpdateSubmissionCommentParams>

export async function updateCommentBankItem({
  id,
  comment,
}: UpdateSubmissionCommentParams): Promise<any> {
  const result = executeQuery<any>(UPDATE_COMMENT_MUTATION, {
    id,
    comment,
  })

  return result
}
