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

const QUERY = gql`
  query SpeedGrader_AssignmentSubmissionsQuery($assignmentId: ID!) {
    assignment(id: $assignmentId) {
      submissionsConnection(
        filter: {
          includeUnsubmitted: true
          applyGradebookEnrollmentFilters: true
          representativesOnly: true
        }
      ) {
        nodes {
          _id
          id
          cachedDueDate
          customGradeStatus
          excused
          gradeMatchesCurrentSubmission
          submissionCommentDownloadUrl
          gradingPeriodId
          gradingStatus
          groupId
          postedAt
          grade
          score
          state
          submissionStatus
          submittedAt
          attachments {
            submissionPreviewUrl
          }
          user {
            _id
            id
            name
            avatarUrl
          }
        }
      }
    }
  }
`

export const ZGetAssignmentParams = z.object({
  assignmentId: z.string().min(1),
})

type GetSubmissionsByAssignmentParams = z.infer<typeof ZGetAssignmentParams>

export async function getAssignmentSubmissions<T extends GetSubmissionsByAssignmentParams>({
  queryKey,
}: {
  queryKey: [string, T]
}): Promise<any> {
  ZGetAssignmentParams.parse(queryKey[1])
  const {assignmentId} = queryKey[1]

  return executeQuery<any>(QUERY, {
    assignmentId,
  })
}
