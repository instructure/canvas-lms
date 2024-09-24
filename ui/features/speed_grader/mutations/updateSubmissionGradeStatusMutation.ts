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

export const UPDATE_SUBMISSION_GRADE_STATUS = gql`
  mutation updateSubmissionGradeStatus(
    $submissionId: ID!
    $latePolicyStatus: String
    $customGradeStatusId: ID
  ) {
    __typename
    updateSubmissionGradeStatus(
      input: {
        submissionId: $submissionId
        latePolicyStatus: $latePolicyStatus
        customGradeStatusId: $customGradeStatusId
      }
    ) {
      submission {
        gradingStatus
      }
    }
  }
`

export const ZUpdateSubmissionGradeStatusParams = z.object({
  submissionId: z.string(),
  latePolicyStatus: z.string().nullable(),
  customGradeStatusId: z.string().nullable(),
  courseId: z.string().nullable(),
})

type UpdateSubmissionGradeStatusParams = z.infer<typeof ZUpdateSubmissionGradeStatusParams>

export async function updateSubmissionGradeStatus({
  submissionId,
  latePolicyStatus,
  customGradeStatusId,
  courseId,
}: UpdateSubmissionGradeStatusParams): Promise<any> {
  const result: any = await executeQuery(UPDATE_SUBMISSION_GRADE_STATUS, {
    submissionId,
    latePolicyStatus,
    customGradeStatusId,
    courseId,
  })

  return result.createSubmissionComment.submission
}
