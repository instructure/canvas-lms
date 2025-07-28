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

export const GET_ENROLLMENTS_QUERY = gql`
query getEnrollments($after: String, $courseId: ID!, $userIds: [ID!]) {
  course(id: $courseId) {
    enrollmentsConnection(
      after: $after
      filter: {
        states: [active, completed, inactive, invited]
        types: [StudentEnrollment, StudentViewEnrollment]
        userIds: $userIds
      }
      first: 100
    ) {
      pageInfo {
        endCursor
        hasNextPage
      }
      nodes {
        _id
        courseSectionId
        createdAt
        endAt
        enrollmentState
        htmlUrl
        lastActivityAt
        limitPrivilegesToCourseSection
        sisSectionId
        startAt
        state
        type
        updatedAt
        userId
        associatedUser {
          _id
        }
        course {
          _id
        }
        grades {
          currentGrade
          currentScore
          finalGrade
          finalScore
          htmlUrl
          htmlUrl
          unpostedCurrentGrade
          unpostedCurrentScore
          unpostedFinalGrade
          unpostedFinalScore
        }
        role {
          _id
          name
        }
        userId
      }
    }
  }
}
`
