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
      }
      submissionsConnection(filter: {userId: $userId}) {
        nodes {
          _id
          submissionStatus
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
        submission {
          _id
          attempt
          body
          submissionType
          url
          attachments {
            _id
            displayName
            mimeClass
            size
            thumbnailUrl
            submissionPreviewUrl
            url
          }
        }
      }
      rubric {
        _id
      }
    }
  }
`
