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
    attempt
    cachedDueDate
    gradingStatus
    user {
      _id
      avatarUrl
      name
      enrollments(courseId: $courseId) {
        state
        courseSectionId
      }
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
    latePolicyStatus
    submissionStatus
    customGradeStatus
    redoRequest
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
          _id
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
    subAssignmentSubmissions {
      subAssignmentTag
      grade
      score
      publishedGrade
      publishedScore
    }
  }
`

const QUERY = gql`
  query SpeedGrader_SubmissionQuery($assignmentId: ID!, $userId: ID!, $courseId: ID!) {
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
          gradingPeriodId
          ...SubmissionInterfaceFragment
          rubricAssessmentsConnection {
            nodes {
              id: _id
              assessmentType
              assessmentRatings {
                id: _id
                comments
                commentsEnabled
                commentsHtml
                points
                description
                criterion {
                  _id
                }
                outcome {
                  _id
                }
              }
              score
              assessor {
                name
              }
            }
          }
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
    // TODO: should be updated with anonymous grading (see reassignAssignment method in speed_grader.tsx)
    submission.reassignAssignment = () => {
      return doFetchApi({
        path: `/courses/${result.assignment?.courseId}/assignments/${result.assignment?._id}/submissions/${submission.user._id}/reassign`,
        method: 'PUT',
      })
    }
    submission.attachments.forEach((attachment: any) => {
      attachment.delete = () =>
        doFetchApi({
          path: `/api/v1/files/${attachment._id}?replace=1`,
          method: 'DELETE',
        })
    })
    submission.rubricAssessments = submission?.rubricAssessmentsConnection?.nodes?.map(
      (rubricAssessment: any) => {
        rubricAssessment.assessmentRatings.forEach((rating: any) => {
          rating.criterionId = rating.criterion?._id
          rating.learningOutcomeId = rating.outcome?._id
          delete rating.criterion
          delete rating.outcome
        })
        rubricAssessment.assessorName = rubricAssessment.assessor?.name
        delete rubricAssessment.assessor
        return rubricAssessment
      }
    )
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
        delete submissionHistory.commentsConnection
      }
    )
    return {
      ...omit(submission, [
        'commentsConnection',
        'rubricAssessmentsConnection',
        'submissionHistoriesConnection',
      ]),
      comments: submission?.commentsConnection?.nodes,
      rubricAssessments: submission.rubricAssessments,
      submissionHistory: submission.submissionHistoriesConnection?.nodes,
      // @ts-expect-error
      submissionState: speedGraderHelpers.submissionState(submission, ENV.grading_role ?? ''),
    }
  }
  return null
}

export const ZGetSubmissionParams = z.object({
  assignmentId: z.string().min(1),
  userId: z.string().min(1),
  courseId: z.string().min(1),
})

type GetSubmissionParams = z.infer<typeof ZGetSubmissionParams>

export async function getSubmission<T extends GetSubmissionParams>({
  queryKey,
}: {
  queryKey: [string, T]
}): Promise<any> {
  ZGetSubmissionParams.parse(queryKey[1])
  const {assignmentId, userId, courseId} = queryKey[1]

  const result = await executeQuery<any>(QUERY, {
    assignmentId,
    userId,
    courseId,
  })

  return transform(result)
}
