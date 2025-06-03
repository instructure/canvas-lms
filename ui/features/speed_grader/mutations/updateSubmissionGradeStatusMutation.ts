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

export const UPDATE_SUBMISSION_GRADE_STATUS = gql`
  mutation updateSubmissionGradeStatus(
    $submissionId: ID!
    $latePolicyStatus: String
    $customGradeStatusId: ID
    $checkpointTag: String
  ) {
    __typename
    updateSubmissionGradeStatus(
      input: {
        submissionId: $submissionId
        latePolicyStatus: $latePolicyStatus
        customGradeStatusId: $customGradeStatusId
        checkpointTag: $checkpointTag
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
  checkpointTag: z.string().nullable(),
})

const ZSubmissionWithGradingStatus = z.object({
  gradingStatus: z.string(),
})

const ZUpdateSubmissionGradeStatusResult = z.object({
  updateSubmissionGradeStatus: z.object({
    submission: ZSubmissionWithGradingStatus,
  }),
})

type UpdateSubmissionGradeStatusParams = z.infer<typeof ZUpdateSubmissionGradeStatusParams>
type UpdateSubmissionGradeStatusResult = z.infer<typeof ZUpdateSubmissionGradeStatusResult>
type SubmissionWithGradingStatus = z.infer<typeof ZSubmissionWithGradingStatus>

export async function updateSubmissionGradeStatus({
  submissionId,
  latePolicyStatus,
  customGradeStatusId,
  courseId,
  checkpointTag,
}: UpdateSubmissionGradeStatusParams): Promise<SubmissionWithGradingStatus> {
  const result: UpdateSubmissionGradeStatusResult = await executeQuery(
    UPDATE_SUBMISSION_GRADE_STATUS,
    {
      submissionId,
      latePolicyStatus,
      customGradeStatusId,
      courseId,
      checkpointTag,
    },
  )

  return result.updateSubmissionGradeStatus.submission
}
