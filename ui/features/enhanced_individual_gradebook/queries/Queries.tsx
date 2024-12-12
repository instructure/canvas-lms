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

import {executeQuery} from '@canvas/query/graphql'
import {gql} from '@apollo/client'
import type {
  AssignmentConnection,
  AssignmentGroupConnection,
  EnrollmentConnection,
  GradebookStudentQueryResponse,
  GradebookSubmissionCommentsResponse,
  Outcome,
  SectionConnection,
  SubmissionConnection,
} from '../types'

export const GRADEBOOK_QUERY = gql`
  query GradebookQuery($courseId: ID!) {
    course(id: $courseId) {
      rootOutcomeGroup {
        outcomes {
          nodes {
            ... on LearningOutcome {
              id: _id
              assessed
              calculationInt
              calculationMethod
              description
              displayName
              masteryPoints
              pointsPossible
              title
              ratings {
                mastery
                points
                description
              }
            }
          }
        }
      }
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
          subAssignmentSubmissions {
            grade
            score
            publishedGrade
            publishedScore
            assignmentId
            gradeMatchesCurrentSubmission
            subAssignmentTag
            enteredGrade
            enteredScore
            excused
          }
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
              checkpoints {
                unlockAt
                lockAt
                dueAt
                name
                pointsPossible
                tag
              }
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
          sticker
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
          subAssignmentSubmissions {
            grade
            score
            publishedGrade
            publishedScore
            assignmentId
            gradeMatchesCurrentSubmission
            subAssignmentTag
            enteredGrade
            enteredScore
            excused
          }
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
          htmlComment
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

export const GRADEBOOK_ENROLLMENTS_QUERY = gql`
  query GradebookEnrollmentsQuery($courseId: ID!, $cursor: String) {
    course(id: $courseId) {
      enrollmentsConnection(
        first: 100
        after: $cursor
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
        pageInfo {
          hasNextPage
          endCursor
        }
      }
    }
  }
`

export const GRADEBOOK_SUBMISSIONS_QUERY = gql`
  query GradebookSubmissionsQuery($courseId: ID!, $cursor: String) {
    course(id: $courseId) {
      submissionsConnection(
        after: $cursor
        first: 100
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
          subAssignmentSubmissions {
            grade
            score
            publishedGrade
            publishedScore
            assignmentId
            gradeMatchesCurrentSubmission
            subAssignmentTag
            enteredGrade
            enteredScore
            excused
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

export const GRADEBOOK_SECTIONS_QUERY = gql`
  query GradebookSectionsQuery($courseId: ID!, $cursor: String) {
    course(id: $courseId) {
      sectionsConnection(first: 100, after: $cursor) {
        nodes {
          id: _id
          name
        }
        pageInfo {
          hasNextPage
          endCursor
        }
      }
    }
  }
`

export const GRADEBOOK_OUTCOMES_QUERY = gql`
  query GradebookOutcomesQuery($courseId: ID!, $cursor: String) {
    course(id: $courseId) {
      rootOutcomeGroup {
        outcomes(first: 100, after: $cursor) {
          nodes {
            ... on LearningOutcome {
              id: _id
              assessed
              calculationInt
              calculationMethod
              description
              displayName
              masteryPoints
              pointsPossible
              title
              ratings {
                mastery
                points
                description
              }
            }
          }
          pageInfo {
            hasNextPage
            endCursor
          }
        }
      }
    }
  }
`

export const GRADEBOOK_ASSIGNMENT_GROUPS_QUERY = gql`
  query GradebookAssignmentGroupsQuery($courseId: ID!, $cursor: String) {
    course(id: $courseId) {
      assignmentGroupsConnection(after: $cursor, first: 100) {
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
        }
        pageInfo {
          hasNextPage
          endCursor
        }
      }
    }
  }
`

export const GRADEBOOK_ASSIGNMENTS_QUERY = gql`
  query GradebookAssignmentsQuery($courseId: ID!, $cursor: String) {
    course(id: $courseId) {
      assignmentsConnection(after: $cursor, first: 100, filter: {gradingPeriodId: null}) {
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
          checkpoints {
            unlockAt
            lockAt
            dueAt
            name
            pointsPossible
            tag
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

const COURSE_ID_INDEX = 1

type PageInfo = {
  hasNextPage: boolean
  endCursor: string | null
}

export type FetchRequestParams = {
  pageParam?: string | null
  queryKey: (string | number)[]
}

type FetchEnrollmentsResponse = {
  course: {
    enrollmentsConnection: {
      nodes: EnrollmentConnection[]
      pageInfo: PageInfo
    }
  }
}
export const fetchEnrollments = async ({pageParam, queryKey}: FetchRequestParams) => {
  return executeQuery<FetchEnrollmentsResponse>(GRADEBOOK_ENROLLMENTS_QUERY, {
    courseId: queryKey[COURSE_ID_INDEX],
    cursor: pageParam,
  })
}
export const getNextEnrollmentPage = (lastPage: FetchEnrollmentsResponse) => {
  const {pageInfo} = lastPage.course.enrollmentsConnection
  return pageInfo.hasNextPage ? pageInfo.endCursor : null
}

type FetchSectionsResponse = {
  course: {
    sectionsConnection: {
      nodes: SectionConnection[]
      pageInfo: PageInfo
    }
  }
}
export const fetchSections = async ({pageParam, queryKey}: FetchRequestParams) => {
  return executeQuery<FetchSectionsResponse>(GRADEBOOK_SECTIONS_QUERY, {
    courseId: queryKey[COURSE_ID_INDEX],
    cursor: pageParam,
  })
}
export const getNextSectionsPage = (lastPage: FetchSectionsResponse) => {
  const {pageInfo} = lastPage.course.sectionsConnection
  return pageInfo.hasNextPage ? pageInfo.endCursor : null
}

type FetchOutcomesResponse = {
  course: {
    rootOutcomeGroup: {
      outcomes: {
        nodes: Outcome[]
        pageInfo: PageInfo
      }
    }
  }
}
export const fetchOutcomes = async ({pageParam, queryKey}: FetchRequestParams) => {
  return executeQuery<FetchOutcomesResponse>(GRADEBOOK_OUTCOMES_QUERY, {
    courseId: queryKey[COURSE_ID_INDEX],
    cursor: pageParam,
  })
}
export const getNextOutcomesPage = (lastPage: FetchOutcomesResponse) => {
  const {pageInfo} = lastPage.course.rootOutcomeGroup.outcomes
  return pageInfo.hasNextPage ? pageInfo.endCursor : null
}

type FetchSubmissionsResponse = {
  course: {
    submissionsConnection: {
      nodes: SubmissionConnection[]
      pageInfo: PageInfo
    }
  }
}
export const fetchSubmissions = async ({pageParam, queryKey}: FetchRequestParams) => {
  return executeQuery<FetchSubmissionsResponse>(GRADEBOOK_SUBMISSIONS_QUERY, {
    courseId: queryKey[COURSE_ID_INDEX],
    cursor: pageParam,
  })
}
export const getNextSubmissionsPage = (lastPage: FetchSubmissionsResponse) => {
  const {pageInfo} = lastPage.course.submissionsConnection
  return pageInfo.hasNextPage ? pageInfo.endCursor : null
}

export const fetchStudentSubmission = async ({queryKey}: FetchRequestParams) => {
  return executeQuery<GradebookStudentQueryResponse>(GRADEBOOK_STUDENT_QUERY, {
    courseId: queryKey[COURSE_ID_INDEX],
    userIds: queryKey[2] ? [queryKey[2]] : [],
  })
}

export const fetchStudentSubmissionComments = async ({queryKey}: FetchRequestParams) => {
  return executeQuery<GradebookSubmissionCommentsResponse>(GRADEBOOK_SUBMISSION_COMMENTS, {
    courseId: queryKey[COURSE_ID_INDEX],
    submissionId: queryKey[2],
  })
}

type FetchAssignmentGroupsResponse = {
  course: {
    assignmentGroupsConnection: {
      nodes: AssignmentGroupConnection[]
      pageInfo: PageInfo
    }
  }
}
export const fetchAssignmentGroups = async ({pageParam, queryKey}: FetchRequestParams) => {
  return executeQuery<FetchAssignmentGroupsResponse>(GRADEBOOK_ASSIGNMENT_GROUPS_QUERY, {
    courseId: queryKey[COURSE_ID_INDEX],
    cursor: pageParam,
  })
}
export const getNextAssignmentGroupsPage = (lastPage: FetchAssignmentGroupsResponse) => {
  const {pageInfo} = lastPage.course.assignmentGroupsConnection
  return pageInfo.hasNextPage ? pageInfo.endCursor : null
}

type FetchAssignmentsResponse = {
  course: {
    assignmentsConnection: {
      nodes: AssignmentConnection[]
      pageInfo: PageInfo
    }
  }
}
export const fetchAssignments = async ({pageParam, queryKey}: FetchRequestParams) => {
  return executeQuery<FetchAssignmentsResponse>(GRADEBOOK_ASSIGNMENTS_QUERY, {
    courseId: queryKey[COURSE_ID_INDEX],
    cursor: pageParam,
  })
}
export const getNextAssignmentsPage = (lastPage: FetchAssignmentsResponse) => {
  const {pageInfo} = lastPage.course.assignmentsConnection
  return pageInfo.hasNextPage ? pageInfo.endCursor : null
}
