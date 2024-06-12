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

export const SUBMISSION_FRAGMENT = gql`
  fragment SubmissionInterfaceFragment on SubmissionInterface {
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
    grade
    excused
    postedAt
    previewUrl
    proxySubmitter
    wordCount
    late
    missing
    submissionStatus
    customGradeStatus
    submittedAt
    submissionType
    secondsLate
    commentsConnection(includeDraftComments: true) {
      nodes {
        id
        _id
        comment
        attempt
        createdAt
        draft
        author {
          name
          updatedAt
          avatarUrl
        }
        attachments {
          _id
          displayName
          url
          mimeClass
        }
        mediaObject {
          _id
          mediaSources {
            height
            src: url
            type: contentType
            width
          }
          mediaTracks {
            _id
            locale
            content
            kind
          }
          thumbnailUrl
          mediaType
          title
        }
      }
    }
    attachments {
      _id
      displayName
      wordCount
      submissionPreviewUrl
      url
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
`

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
          id
          _id
          ...SubmissionInterfaceFragment
          submissionHistoriesConnection {
            nodes {
              ...SubmissionInterfaceFragment
            }
          }
        }
      }
    }
  }
  ${SUBMISSION_FRAGMENT}
`

function transform(result: any) {
  const submission = result.assignment?.submissionsConnection?.nodes?.[0]
  if (submission) {
    submission.attachments.forEach((attachment: any) => {
      attachment.delete = () =>
        doFetchApi({
          path: `/api/v1/files/${attachment._id}?replace=1`,
          method: 'DELETE',
        })
    })
    submission.submissionHistoriesConnection?.nodes.forEach(
      (submissionHistory: any, index: number) => {
        submissionHistory.attachments.forEach((attachment: any) => {
          attachment.delete = () =>
            doFetchApi({
              path: `/api/v1/files/${attachment._id}?replace=1`,
              method: 'DELETE',
            })
        })
        submissionHistory.comments = submissionHistory.commentsConnection?.nodes
        submissionHistory.rubricAssessments = submissionHistory.rubricAssessmentsConnection?.nodes
        delete submissionHistory.commentsConnection
        delete submissionHistory.rubricAssessmentsConnection
      }
    )
    return {
      ...omit(submission, [
        'commentsConnection',
        'rubricAssessmentsConnection',
        'submissionHistoriesConnection',
      ]),
      comments: submission?.commentsConnection?.nodes,
      rubricAssessments: submission.rubricAssessmentsConnection?.nodes,
      submissionHistory: submission.submissionHistoriesConnection?.nodes,
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
