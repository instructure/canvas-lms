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

export const POST_DRAFT_SUBMISSION_COMMENT = gql`
  mutation PostDraftSubmissionComment($submissionCommentId: ID!) {
    __typename
    postDraftSubmissionComment(input: {submissionCommentId: $submissionCommentId}) {
      submissionComment {
        _id
        id
        comment
        read
        draft
        author {
          _id
          id
          name
        }
      }
    }
  }
`

export const ZPostDraftSubmissionCommentParams = z.object({
  submissionCommentId: z.string(),
})

type PostDraftSubmissionCommentParams = z.infer<typeof ZPostDraftSubmissionCommentParams>

export async function postDraftSubmissionComment({
  submissionCommentId,
}: PostDraftSubmissionCommentParams): Promise<any> {
  const result = executeQuery<any>(POST_DRAFT_SUBMISSION_COMMENT, {
    submissionCommentId,
  })

  return result
}
