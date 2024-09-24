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
import {executeQuery} from '@canvas/query/graphql'
import gql from 'graphql-tag'

type Result = {
  legacyNode: {
    __typename: string
    commentBankItemsConnection?: {
      nodes: {
        comment: string
        _id: string
      }[]
    }
  } | null
}

const QUERY = gql`
  query CommentBankItemQuery($userId: ID!, $query: String, $maxResults: Int) {
    legacyNode(_id: $userId, type: User) {
      ... on User {
        commentBankItemsConnection(query: $query, limit: $maxResults) {
          nodes {
            comment
            _id
          }
        }
      }
    }
  }
`

export const ZParams = z.object({
  query: z.string().optional(),
  maxResults: z.number().optional(),
})

type Params = z.infer<typeof ZParams>

export function getCommentBankItems<T extends Params>({queryKey}: {queryKey: [string, T]}) {
  const params = ZParams.parse(queryKey[1])

  return executeQuery<Result>(QUERY, {
    ...params,
    // @ts-expect-error
    userId: window.ENV.current_user_id,
  })
}
