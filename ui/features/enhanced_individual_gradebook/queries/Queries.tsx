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
      enrollmentsConnection(
        filter: {
          states: [active, invited, completed]
          types: [StudentEnrollment, StudentViewEnrollment]
        }
      ) {
        nodes {
          user {
            id: _id
            name
            sortableName
          }
          courseSectionId
          state
        }
      }
      sectionsConnection {
        nodes {
          id: _id
          name
        }
      }
      submissionsConnection(
        filter: {states: [graded, pending_review, submitted, ungraded, unsubmitted]}
      ) {
        nodes {
          grade
          id: _id
          score
          assignmentId
          redoRequest
          submittedAt
          userId
          state
          gradingPeriodId
          excused
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
          sisId
          state
          position
          assignmentsConnection(filter: {gradingPeriodId: null}) {
            nodes {
              anonymizeStudents
              assignmentGroupId
              gradingType
              id: _id
              name
              omitFromFinalGrade
              pointsPossible
              submissionTypes
              dueAt
              groupCategoryId
              gradeGroupStudentsIndividually
              allowedAttempts
              anonymousGrading
              courseId
              gradesPublished
              htmlUrl
              moderatedGrading: moderatedGradingEnabled
              postManually
              published
              hasSubmittedSubmissions
              inClosedGradingPeriod
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
          enrollmentStates: [active, invited, completed]
          userIds: $userIds
        }
      ) {
        nodes {
          enrollments(courseId: $courseId) {
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
          id: _id
          loginId
          name
        }
      }
      submissionsConnection(
        studentIds: $userIds
        filter: {states: [graded, pending_review, submitted, ungraded, unsubmitted]}
      ) {
        nodes {
          grade
          id: _id
          score
          enteredScore
          assignmentId
          submissionType
          submittedAt
          state
          proxySubmitter
          excused
          late
          latePolicyStatus
          missing
          userId
          cachedDueDate
          gradingPeriodId
          deductedPoints
          enteredGrade
          gradeMatchesCurrentSubmission
          customGradeStatus
        }
      }
    }
  }
`

export const GRADEBOOK_SUBMISSION_COMMENTS = gql`
  query GradebookSubmissionCommentsQuery($courseId: ID!, $submissionId: ID!) {
    submission(id: $submissionId) {
      commentsConnection {
        nodes {
          id: _id
          comment
          mediaObject {
            id: _id
            mediaDownloadUrl
          }
          attachments {
            id: _id
            displayName
            mimeClass
            url
          }
          author {
            name
            id: _id
            avatarUrl
            htmlUrl(courseId: $courseId)
          }
          updatedAt
        }
      }
    }
  }
`
