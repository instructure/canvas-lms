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

const SUBMISSION_QUERY = gql`
  query SubmissionQuery($assignmentId: ID!, $userId: ID!) {
    assignment(id: $assignmentId) {
      id
      submissionsConnection(
        filter: {includeUnsubmitted: true, userId: $userId, applyGradebookEnrollmentFilters: true}
      ) {
        nodes {
          _id
          id
          cachedDueDate
          gradingStatus
          user {
            avatarUrl
            name
          }
          gradeMatchesCurrentSubmission
          score
          excused
          id
          _id
          postedAt
          previewUrl
          wordCount
          late
          submissionStatus
          commentsConnection {
            nodes {
              id
              comment
              attempt
              createdAt
              author {
                name
                updatedAt
                avatarUrl
              }
            }
          }
        }
      }
      name
      gradingType
      pointsPossible
    }
  }
`

function transform(result: any) {
  if (result.assignment?.submissionsConnection?.nodes?.[0]) {
    const submission = result.assignment?.submissionsConnection?.nodes?.[0]
    const comments = submission?.commentsConnection?.nodes
    delete submission?.commentsConnection
    return {
      ...submission,
      comments,
    }
  }
  return null
}

export const ZGetSubmissionParams = z.object({
  assignmentId: z.string(),
  userId: z.string(),
})

type GetSubmissionParams = z.infer<typeof ZGetSubmissionParams>

export async function getSubmission<T extends GetSubmissionParams>({
  queryKey,
}: {
  queryKey: [string, T]
}): Promise<any> {
  ZGetSubmissionParams.parse(queryKey[1])
  const {assignmentId, userId} = queryKey[1]

  const result = await executeQuery<any>(SUBMISSION_QUERY, {
    assignmentId,
    userId,
  })

  return transform(result)
}
