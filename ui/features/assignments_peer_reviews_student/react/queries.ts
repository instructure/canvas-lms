/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {gql} from '@apollo/client'

export const PEER_REVIEW_ASSIGNMENT_QUERY = gql`
  query GetPeerReviewAssignment($assignmentId: ID!, $userId: ID!) {
    assignment(id: $assignmentId) {
      _id
      name
      dueAt
      description
      expectsSubmission
      nonDigitalSubmission
      pointsPossible
      courseId
      peerReviews {
        count
        submissionRequired
        pointsPossible
        anonymousReviews
      }
      submissionsConnection(filter: {userId: $userId}) {
        nodes {
          _id
          submittedAt
        }
      }
      assignedToDates {
        dueAt
        peerReviewDates {
          dueAt
          unlockAt
          lockAt
        }
      }
      assessmentRequestsForCurrentUser {
        _id
        available
        workflowState
        createdAt
        rubricAssessment {
          _id
          assessmentRatings {
            _id
            criterion {
              _id
            }
            comments
            commentsHtml
            description
            points
          }
        }
        anonymousId
        anonymizedUser {
          _id
          displayName: shortName
        }
        submission {
          _id
          id
          attempt
          body
          submissionType
          url
          submittedAt
          attachments {
            _id
            displayName
            mimeClass
            size
            thumbnailUrl
            submissionPreviewUrl
            url
          }
          user {
            _id
          }
          anonymousId
        }
      }
      rubric {
        _id
        title
        criteria {
          _id
          description
          longDescription
          points
          criterionUseRange
          ratings {
            _id
            description
            longDescription
            points
          }
          ignoreForScoring
          masteryPoints
          learningOutcomeId
        }
        freeFormCriterionComments
        hideScoreTotal
        pointsPossible
        ratingOrder
        buttonDisplay
      }
      rubricAssociation {
        _id
        hidePoints
        hideScoreTotal
        useForGrading
      }
    }
  }
`

export const REVIEWER_SUBMISSION_QUERY = gql`
  query GetReviewerSubmission($assignmentId: ID!, $userId: ID!) {
    submission(assignmentId: $assignmentId, userId: $userId) {
      _id
      id
      attempt
      assignedAssessments {
        assetId
        workflowState
        assetSubmissionType
      }
      rubricAssessmentsConnection(filter: {forAttempt: 0}) {
        nodes {
          _id
          assessmentType
          score
          assessor {
            _id
          }
          assessmentRatings {
            _id
            criterion {
              _id
            }
            comments
            commentsHtml
            description
            points
          }
        }
      }
    }
  }
`
