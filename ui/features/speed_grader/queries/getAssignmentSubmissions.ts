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
  assignment: {
    submissionsConnection: {
      nodes: {
        _id: string
        id: string
        cachedDueDate: string | null
        customGradeStatus: string | null
        excused: boolean
        gradeMatchesCurrentSubmission: boolean
        submissionCommentDownloadUrl: string | null
        gradingPeriodId: string | null
        gradingStatus: string
        groupId: string | null
        postedAt: string | null
        grade: string | null
        score: number | null
        state: string
        submissionStatus: string
        submittedAt: string | null
        attachments: {
          submissionPreviewUrl: string | null
        }[]
        user: {
          _id: string
          id: string
          name: string
          avatarUrl: string | null
        }
      }[]
    }
  }
}

const QUERY = gql`
  query SpeedGrader_AssignmentSubmissionsQuery($assignmentId: ID!, $cursor: String, $first: Int!) {
    assignment(id: $assignmentId) {
      submissionsConnection(
        filter: {
          includeUnsubmitted: true
          applyGradebookEnrollmentFilters: true
          representativesOnly: true
        }
        after: $cursor
        first: $first
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
          externalToolUrl
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
        pageInfo {
          hasNextPage
          endCursor
        }
      }
    }
  }
`

export const ZGetAssignmentParams = z.object({
  assignmentId: z.string().min(1),
  perPage: z.number().int().min(1),
})

type GetSubmissionsByAssignmentParams = z.infer<typeof ZGetAssignmentParams>

export async function getAssignmentSubmissions<T extends GetSubmissionsByAssignmentParams>({
  queryKey,
  pageParam,
}: {
  queryKey: [string, T]
  pageParam: string | null
}) {
  ZGetAssignmentParams.parse(queryKey[1])
  const {assignmentId, perPage} = queryKey[1]

  return executeQuery<Result>(QUERY, {
    cursor: pageParam,
    first: perPage,
    assignmentId,
  })
}
