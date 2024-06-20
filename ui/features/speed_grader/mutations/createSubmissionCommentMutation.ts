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
import {submissionCommentAttachmentsUpload} from '@canvas/upload-file'

export const CREATE_SUBMISSION_COMMENT = gql`
  mutation CreateSubmissionComment(
    $submissionId: ID!
    $comment: String!
    $fileIds: [ID!]
    $groupComment: Boolean!
    $draftComment: Boolean
  ) {
    __typename
    createSubmissionComment(
      input: {
        submissionId: $submissionId
        comment: $comment
        fileIds: $fileIds
        groupComment: $groupComment
        draftComment: $draftComment
      }
    ) {
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
        attachments {
          _id
          displayName
          id
          mimeClass
          url
        }
      }
    }
  }
`

export const ZCreateSubmissionCommentParams = z.object({
  submissionId: z.string(),
  comment: z.string(),
  groupComment: z.boolean(),
  courseId: z.string(),
  assignmentId: z.string(),
  userId: z.string(),
  files: z.array(z.object({})),
  draftComment: z.boolean().optional(),
})

type CreateSubmissionCommentParams = z.infer<typeof ZCreateSubmissionCommentParams>

export async function createSubmissionComment({
  submissionId,
  comment,
  groupComment,
  courseId,
  assignmentId,
  userId,
  files,
  draftComment,
}: CreateSubmissionCommentParams): Promise<any> {
  let fileIds = []
  if (files.length > 0) {
    const attachments = await submissionCommentAttachmentsUpload(
      files,
      courseId,
      assignmentId,
      userId
    )
    fileIds = attachments.map(attachment => attachment.id)
  }
  const result = executeQuery<any>(CREATE_SUBMISSION_COMMENT, {
    submissionId,
    comment,
    groupComment,
    fileIds,
    draftComment,
  })

  return result
}
