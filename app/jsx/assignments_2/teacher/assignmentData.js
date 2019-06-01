/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import {bool, number, oneOf, oneOfType, shape, string, arrayOf} from 'prop-types'

// This ENV shape is for the controller's current show action. We'll have
// something different when assignments are being created, which is a different
// controller action. Think about this later.
export const EnvShape = shape({
  // Legacy controller populates this id as a number instead of a string. I'm not sure what uses it,
  // so I didn't change it. It's probably always a local id and won't cause overflow problems.
  ASSIGNMENT_ID: number.isRequired,
  PERMISSIONS: shape({
    context: shape({
      read_as_admin: bool.isRequired,
      manage_assignments: bool.isRequired
    }).isRequired,
    assignment: shape({
      update: bool.isRequired,
      submit: bool.isRequired
    }).isRequired
  }).isRequired
})

const userFields = gql`
  fragment UserFields on User {
    __typename
    gid: id
    lid: _id
    name
    shortName
    sortableName
    avatarUrl
    email
  }
`

export const TEACHER_QUERY = gql`
  query GetAssignment($assignmentLid: ID!) {
    assignment(id: $assignmentLid) {
      __typename
      id
      lid: _id
      gid: id
      name
      description
      dueAt
      unlockAt
      lockAt
      pointsPossible
      state
      needsGradingCount
      onlyVisibleToOverrides
      lockInfo {
        isLocked
      }
      assignmentGroup {
        lid: _id
        name
      }
      modules {
        lid: _id
        name
      }
      submissionTypes
      allowedExtensions
      allowedAttempts
      course {
        lid: _id
        modulesConnection(first: 0) {
          pageInfo {
            hasNextPage
          }
        }
        assignmentGroupsConnection(first: 0) {
          pageInfo {
            hasNextPage
          }
        }
      }
      assignmentOverrides {
        pageInfo {
          startCursor
          endCursor
          hasNextPage
          hasPreviousPage
        }
        nodes {
          gid: id
          lid: _id
          title
          dueAt
          lockAt
          unlockAt
          set {
            __typename
            ... on Section {
              lid: _id
              sectionName: name
            }
            ... on Group {
              lid: _id
              groupName: name
            }
            ... on AdhocStudents {
              students {
                lid: _id
                studentName: name
              }
            }
          }
        }
      }
      submissions: submissionsConnection(
        filter: {states: [submitted, unsubmitted, graded, ungraded, pending_review]}
      ) {
        pageInfo {
          startCursor
          endCursor
          hasNextPage
          hasPreviousPage
        }
        nodes {
          gid: id
          lid: _id
          submissionStatus
          grade
          gradingStatus
          score
          state
          excused
          latePolicyStatus
          submittedAt
          user {
            ...UserFields
          }
        }
      }
    }
  }
  ${userFields}
`

const assignmentGroup = gql`
  fragment CourseAssignmentGroups on AssignmentGroupConnection {
    __typename
    nodes {
      lid: _id
      gid: id
      name
      __typename
    }
  }
`

export const COURSE_ASSIGNMENT_GROUPS_QUERY = gql`
  query GetCourseAssignmentGroups($courseId: ID!, $cursor: String) {
    course(id: $courseId) {
      lid: _id
      gid: id
      assignmentGroupsConnection(first: 200, after: $cursor) {
        pageInfo {
          endCursor
          hasNextPage
        }
        ...CourseAssignmentGroups
      }
    }
  }
  ${assignmentGroup}
`
export const COURSE_ASSIGNMENT_GROUPS_QUERY_LOCAL = gql`
  query GetCourseAssignmentGroupsLocal($courseId: ID!) {
    course(id: $courseId) @client {
      lid: _id
      gid: id
      assignmentGroupsConnection(first: 200) {
        ...CourseAssignmentGroups
      }
    }
  }
  ${assignmentGroup}
`

const assignmentModule = gql`
  fragment CourseModules on ModuleConnection {
    __typename
    nodes {
      lid: _id
      gid: id
      name
      position
      __typename
    }
  }
`

// FYI, modules are areturned sorted by position
export const COURSE_MODULES_QUERY = gql`
  query GetCourseModules($courseId: ID!, $cursor: String) {
    course(id: $courseId) {
      lid: _id
      gid: id
      modulesConnection(first: 200, after: $cursor) {
        pageInfo {
          endCursor
          hasNextPage
        }
        ...CourseModules
      }
    }
  }
  ${assignmentModule}
`

export const COURSE_MODULES_QUERY_LOCAL = gql`
  query GetCourseModules($courseId: ID!) {
    course(id: $courseId) @client {
      lid: _id
      gid: id
      modulesConnection(first: 200) {
        ...CourseModules
      }
    }
  }
  ${assignmentModule}
`

export const STUDENT_SEARCH_QUERY = gql`
  query SearchStudents(
    $assignmentId: ID!
    $userSearch: String
    $orderBy: [SubmissionSearchOrder!]
  ) {
    assignment(id: $assignmentId) {
      id
      submissions: submissionsConnection(
        filter: {
          userSearch: $userSearch
          enrollmentTypes: StudentEnrollment
          states: [submitted, unsubmitted, graded, ungraded, pending_review]
        }
        orderBy: $orderBy
      ) {
        nodes {
          lid: _id
          gid: id
          state
          score
          submittedAt
          user {
            ...UserFields
          }
        }
      }
    }
  }
  ${userFields}
`

export const SET_WORKFLOW = gql`
  mutation SetWorkflow($id: ID!, $workflow: AssignmentState!) {
    updateAssignment(input: {id: $id, state: $workflow}) {
      assignment {
        __typename
        id
        state
      }
    }
  }
`

export const SAVE_ASSIGNMENT = gql`
  mutation SaveAssignment(
    $id: ID!
    $name: String
    $description: String
    $dueAt: DateTime
    $unlockAt: DateTime
    $lockAt: DateTime
    $pointsPossible: Float
    $state: AssignmentState
  ) {
    updateAssignment(
      input: {
        id: $id
        name: $name
        description: $description
        dueAt: $dueAt
        unlockAt: $unlockAt
        lockAt: $lockAt
        pointsPossible: $pointsPossible
        state: $state
      }
    ) {
      assignment {
        __typename
        id
        lid: _id
        gid: id
        dueAt
        unlockAt
        lockAt
        name
        description
        pointsPossible
        state
      }
    }
  }
`

export const CourseShape = shape({
  lid: string.isRequired
})

export const ModuleShape = shape({
  lid: string.isRequired,
  name: string.isRequired
})

export const AssignmentGroupShape = shape({
  lid: string.isRequired,
  name: string.isRequired
})

export const LockInfoShape = shape({
  isLocked: bool.isRequired
})

// TODO: is this the final shape?
//       what is required?
export const OverrideShape = shape({
  id: string,
  lid: string,
  title: string,
  dueAt: string,
  lockAt: string,
  unlockAt: string,
  submissionTypes: arrayOf(string), // currently copied from the asisgnment
  allowedAttempts: number, // currently copied from the assignment
  allowedExtensions: arrayOf(string), // currently copied from the assignment
  set: shape({
    lid: string,
    name: string,
    __typename: oneOf(['Section', 'Group', 'AdhocStudents'])
  })
})

export const UserShape = shape({
  lid: string,
  gid: string,
  name: string,
  shortName: string,
  sortableName: string,
  avatarUrl: string,
  email: string
})

export const SubmissionShape = shape({
  gid: string,
  lid: string,
  submissionStatus: oneOf(['resubmitted', 'missing', 'late', 'submitted', 'unsubmitted']),
  grade: string,
  gradingStatus: oneOf([null, 'excused', 'needs_review', 'needs_grading', 'graded']),
  score: number,
  state: oneOf(['submitted', 'unsubmitted', 'pending_review', 'graded', 'deleted']),
  excused: bool,
  latePolicyStatus: oneOf([null, 'missing']),
  submittedAt: string, // datetime
  user: UserShape
})

export const TeacherAssignmentShape = shape({
  lid: string,
  name: string,
  pointsPossible: oneOfType([number, string]),
  dueAt: string,
  lockAt: string,
  unlockAt: string,
  description: string,
  state: oneOf(['published', 'unpublished', 'deleted']).isRequired,
  assignmentGroup: AssignmentGroupShape,
  modules: arrayOf(ModuleShape).isRequired,
  course: CourseShape.isRequired, // not edited by the teacher
  lockInfo: LockInfoShape.isRequired,
  submissionTypes: arrayOf(string).isRequired,
  allowedExtensions: arrayOf(string).isRequired,
  assignmentOverrides: shape({
    nodes: arrayOf(OverrideShape)
  }).isRequired,
  submissions: shape({
    nodes: arrayOf(SubmissionShape)
  }).isRequired
})

export const StudentSearchQueryShape = shape({
  assignmentId: string.isRequired,
  userSearch: string,
  orderBy: arrayOf(
    shape({
      field: string,
      direction: oneOf(['ascending', 'descending'])
    })
  )
})

// custom proptype validator
// requires the property if the component's prop.variant === 'detail'
// this is used in components that have summary and detail renderings
export function requiredIfDetail(props, propName, componentName) {
  if (!props[propName] && props.variant === 'detail') {
    return new Error(
      `The prop ${propName} is required on ${componentName} if the variant is 'detail'`
    )
  }
}
