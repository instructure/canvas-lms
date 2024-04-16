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
import {omit} from 'lodash'
import speedGraderHelpers from '../jquery/speed_grader_helpers'
import doFetchApi from '@canvas/do-fetch-api-effect'

const SUBMISSION_QUERY = gql`
  query SubmissionQuery($assignmentId: ID!, $userId: ID!) {
    assignment(id: $assignmentId) {
      id
      _id
      name
      gradingType
      pointsPossible
      courseId
      submissionsConnection(
        filter: {
          applyGradebookEnrollmentFilters: true
          includeUnsubmitted: true
          representativesOnly: true
          userId: $userId
        }
      ) {
        nodes {
          _id
          id
          cachedDueDate
          gradingStatus
          user {
            _id
            avatarUrl
            name
          }
          gradeMatchesCurrentSubmission
          submissionCommentDownloadUrl
          score
          excused
          id
          _id
          postedAt
          previewUrl
          wordCount
          late
          submissionStatus
          customGradeStatus
          excused
          submittedAt
          submissionType
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
          attachments {
            _id
            displayName
            wordCount
          }
          rubricAssessmentsConnection {
            nodes {
              _id
              assessmentType
              artifactAttempt
              score
              assessmentRatings {
                ratingTag: _id
                comments
                points
              }
            }
          }
        }
      }
    }
  }
`

function transform(result: any) {
  const submission = result.assignment?.submissionsConnection?.nodes?.[0]
  if (submission) {
    submission.attachments.forEach((attachment: any) => {
      attachment.downloadUrl = `/courses/${result.assignment.courseId}/assignments/${result.assignment._id}/submissions/${submission.user._id}?download=${attachment._id}`
      attachment.previewUrl = `/courses/${result.assignment.courseId}/assignments/${result.assignment._id}/submissions/${submission.user._id}?download=${attachment._id}&inline=1`
      attachment.delete = () =>
        doFetchApi({
          path: `/api/v1/files/${attachment._id}?replace=1`,
          method: 'DELETE',
        })
    })
    return {
      ...omit(submission, ['commentsConnection', 'rubricAssessmentsConnection']),
      comments: submission?.commentsConnection?.nodes,
      rubricAssessments: submission?.rubricAssessmentsConnection?.nodes,
      submissionState: speedGraderHelpers.submissionState(submission, ENV.grading_role ?? ''),
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
