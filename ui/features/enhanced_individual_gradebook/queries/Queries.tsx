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

import {executeQuery} from '@canvas/graphql'
import {gql} from '@apollo/client'
import type {QueryFunctionContext} from '@tanstack/react-query'
import type {
  AssignmentConnection,
  AssignmentGroupConnection,
  EnrollmentConnection,
  GradebookCourseOutcomeCalculationMethod,
  GradebookCourseOutcomeProficiency,
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

// TODO: make enrollments a Connection type and then paginate it, so we don't fetch all enrollments at once.
export const GRADEBOOK_STUDENT_QUERY = gql`
  query GradebookStudentQuery($courseId: ID!, $userId: ID!, $cursor: String) {
    course(id: $courseId) {
      usersConnection(
        first: 1
        filter: {
          enrollmentTypes: [StudentEnrollment, StudentViewEnrollment]
          enrollmentStates: [active, invited, completed]
          userIds: [$userId]
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
        first: 100
        after: $cursor
        studentIds: [$userId]
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
        pageInfo {
          hasNextPage
          endCursor
        }
      }
    }
  }
`

// TODO: paginate commentsConnection instead of just getting the first 100.
export const GRADEBOOK_SUBMISSION_COMMENTS = gql`
  query GradebookSubmissionCommentsQuery($courseId: ID!, $submissionId: ID!) {
    submission(id: $submissionId) {
      commentsConnection(first: 100) {
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

export const GRADEBOOK_COURSE_OUTCOME_MASTERY_SCALES_QUERY = gql`
  query GradebookCourseOutcomeMasteryScalesQuery($courseId:ID!) {
    course(id: $courseId){
      outcomeCalculationMethod {
        _id
        calculationInt
        calculationMethod
      }
      outcomeProficiency {
        masteryPoints
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

export type FetchEnrollmentsResponse = {
  course: {
    enrollmentsConnection: {
      nodes: EnrollmentConnection[]
      pageInfo: PageInfo
    }
  }
}

export const fetchEnrollments = async (context: QueryFunctionContext<(string | number)[]>) => {
  const {pageParam, queryKey} = context
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
export const fetchSections = async ({
  pageParam,
  queryKey,
}: QueryFunctionContext<[string, string], unknown>): Promise<FetchSectionsResponse> => {
  let cursor: string | null = null
  if (pageParam === null) {
    cursor = null
  } else if (typeof pageParam === 'string') {
    cursor = pageParam
  }

  return executeQuery<FetchSectionsResponse>(GRADEBOOK_SECTIONS_QUERY, {
    courseId: queryKey[1],
    cursor,
  })
}
export const getNextSectionsPage = (lastPage: FetchSectionsResponse) => {
  const {pageInfo} = lastPage.course.sectionsConnection
  return pageInfo.hasNextPage ? pageInfo.endCursor : null
}

export type FetchOutcomesResponse = {
  course: {
    rootOutcomeGroup: {
      outcomes: {
        nodes: Outcome[]
        pageInfo: PageInfo
      }
    }
  }
}
export const fetchOutcomes = async ({
  pageParam,
  queryKey,
}: QueryFunctionContext<[string, string], unknown>): Promise<FetchOutcomesResponse> => {
  let cursor: string | null = null
  if (pageParam === null) {
    cursor = null
  } else if (typeof pageParam === 'string') {
    cursor = pageParam
  }

  return executeQuery<FetchOutcomesResponse>(GRADEBOOK_OUTCOMES_QUERY, {
    courseId: queryKey[1],
    cursor,
  })
}
export const getNextOutcomesPage = (lastPage: FetchOutcomesResponse) => {
  const {pageInfo} = lastPage.course.rootOutcomeGroup.outcomes
  return pageInfo.hasNextPage ? pageInfo.endCursor : null
}

type FetchCourseOutcomeMasteryScalesResponse = {
  course: {
    outcomeCalculationMethod: GradebookCourseOutcomeCalculationMethod
    outcomeProficiency: GradebookCourseOutcomeProficiency
  }
}
export const fetchCourseOutcomeMasteryScales = async ({
  queryKey,
}: {
  queryKey: FetchRequestParams['queryKey']
}) => {
  return executeQuery<FetchCourseOutcomeMasteryScalesResponse>(
    GRADEBOOK_COURSE_OUTCOME_MASTERY_SCALES_QUERY,
    {
      courseId: queryKey[COURSE_ID_INDEX],
    },
  )
}

export type FetchSubmissionsResponse = {
  course: {
    submissionsConnection: {
      nodes: SubmissionConnection[]
      pageInfo: PageInfo
    }
  }
}
export const fetchSubmissions = async ({
  pageParam,
  queryKey,
}: QueryFunctionContext<[string, string], unknown>): Promise<FetchSubmissionsResponse> => {
  let cursor: string | null = null
  if (pageParam === null) {
    cursor = null
  } else if (typeof pageParam === 'string') {
    cursor = pageParam
  }

  return executeQuery<FetchSubmissionsResponse>(GRADEBOOK_SUBMISSIONS_QUERY, {
    courseId: queryKey[1],
    cursor,
  })
}
export const getNextSubmissionsPage = (lastPage: FetchSubmissionsResponse) => {
  const {pageInfo} = lastPage.course.submissionsConnection
  return pageInfo.hasNextPage ? pageInfo.endCursor : null
}

export const fetchStudentSubmission = async (
  context: QueryFunctionContext<[string, string, string], never>,
): Promise<GradebookStudentQueryResponse> => {
  const {pageParam, queryKey} = context
  return executeQuery<GradebookStudentQueryResponse>(GRADEBOOK_STUDENT_QUERY, {
    courseId: queryKey[1],
    userId: queryKey[2],
    cursor: pageParam,
  })
}

export const getNextStudentSubmissionPage = (lastPage: GradebookStudentQueryResponse) => {
  const {pageInfo} = lastPage.course.submissionsConnection
  return pageInfo.hasNextPage ? pageInfo.endCursor : null
}

export const fetchStudentSubmissionComments = async ({
  queryKey,
}: {
  queryKey: FetchRequestParams['queryKey']
}) => {
  return executeQuery<GradebookSubmissionCommentsResponse>(GRADEBOOK_SUBMISSION_COMMENTS, {
    courseId: queryKey[COURSE_ID_INDEX],
    submissionId: queryKey[2],
  })
}

export type FetchAssignmentGroupsResponse = {
  course: {
    assignmentGroupsConnection: {
      nodes: AssignmentGroupConnection[]
      pageInfo: PageInfo
    }
  }
}
export const fetchAssignmentGroups = async (context: QueryFunctionContext<(string | number)[]>) => {
  const {pageParam, queryKey} = context
  return executeQuery<FetchAssignmentGroupsResponse>(GRADEBOOK_ASSIGNMENT_GROUPS_QUERY, {
    courseId: queryKey[COURSE_ID_INDEX],
    cursor: pageParam,
  })
}
export const getNextAssignmentGroupsPage = (lastPage: FetchAssignmentGroupsResponse) => {
  const {pageInfo} = lastPage.course.assignmentGroupsConnection
  return pageInfo.hasNextPage ? pageInfo.endCursor : null
}

export type FetchAssignmentsResponse = {
  course: {
    assignmentsConnection: {
      nodes: AssignmentConnection[]
      pageInfo: PageInfo
    }
  }
}
export const fetchAssignments = async ({
  pageParam,
  queryKey,
}: QueryFunctionContext<[string, string], unknown>): Promise<FetchAssignmentsResponse> => {
  let cursor: string | null = null
  if (pageParam === null) {
    cursor = null
  } else if (typeof pageParam === 'string') {
    cursor = pageParam
  }

  return executeQuery<FetchAssignmentsResponse>(GRADEBOOK_ASSIGNMENTS_QUERY, {
    courseId: queryKey[1],
    cursor,
  })
}
export const getNextAssignmentsPage = (lastPage: FetchAssignmentsResponse) => {
  const {pageInfo} = lastPage.course.assignmentsConnection
  return pageInfo.hasNextPage ? pageInfo.endCursor : null
}
