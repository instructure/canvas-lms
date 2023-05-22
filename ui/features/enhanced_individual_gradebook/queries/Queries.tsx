/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import gql from 'graphql-tag'

export const GRADEBOOK_QUERY = gql`
  query GradebookQuery($courseId: ID!) {
    course(id: $courseId) {
      enrollmentsConnection(filter: {types: [StudentEnrollment, StudentViewEnrollment]}) {
        nodes {
          user {
            id: _id
            name
            sortableName
          }
        }
      }
      submissionsConnection {
        nodes {
          grade
          id: _id
          score
          assignmentId
        }
      }
      assignmentGroupsConnection {
        nodes {
          id: _id
          name
          groupWeight
          rules {
            dropHighest
            dropLowest
          }
          state
          position
          assignmentsConnection {
            nodes {
              anonymizeStudents
              id: _id
              muted
              name
              omitFromFinalGrade
              pointsPossible
              submissionTypes
            }
          }
        }
      }
    }
  }
`

export const GRADEBOOK_STUDENT_QUERY = gql`
  query GradebookStudentQuery($courseId: ID!, $userIds: [ID!]) {
    course(id: $courseId) {
      usersConnection(
        filter: {
          enrollmentTypes: [StudentEnrollment, StudentViewEnrollment]
          enrollmentStates: active
          userIds: $userIds
        }
      ) {
        nodes {
          enrollments {
            id: _id
            grades {
              unpostedCurrentGrade
              unpostedCurrentScore
              unpostedFinalGrade
              unpostedFinalScore
            }
            section {
              id: _id
              name
            }
          }
          loginId
          name
        }
      }
      submissionsConnection(studentIds: $userIds) {
        nodes {
          grade
          id: _id
          score
          assignmentId
        }
      }
    }
  }
`
