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
    state
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
    originalityData
  }
`

const QUERY = gql`
  query SpeedGrader_SubmissionQuery($assignmentId: ID!, $userId: ID!, $courseId: ID!) {
    assignment(id: $assignmentId) {
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

export const ZGetSubmissionParams = z.object({
  assignmentId: z.string().min(1),
  userId: z.string().min(1),
  courseId: z.string().min(1),
})

type GetSubmissionParams = z.infer<typeof ZGetSubmissionParams>

export function getSubmission<T extends GetSubmissionParams>({queryKey}: {queryKey: [string, T]}) {
  ZGetSubmissionParams.parse(queryKey[1])
  const {assignmentId, userId, courseId} = queryKey[1]

  return executeQuery<any>(QUERY, {
    assignmentId,
    userId,
    courseId,
  })
}
