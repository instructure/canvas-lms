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

export const DELETE_COMMENT_MUTATION = gql`
  mutation DeleteCommentBankItem($id: ID!) {
    deleteCommentBankItem(input: {id: $id}) {
      commentBankItemId
      errors {
        attribute
        message
      }
    }
  }
`

export const ZDeleteSubmissionCommentParams = z.object({
  id: z.string(),
})

type DeleteSubmissionCommentParams = z.infer<typeof ZDeleteSubmissionCommentParams>

export async function deleteCommentBankItem({id}: DeleteSubmissionCommentParams): Promise<any> {
  const result = executeQuery<any>(DELETE_COMMENT_MUTATION, {
    id,
  })

  return result
}
