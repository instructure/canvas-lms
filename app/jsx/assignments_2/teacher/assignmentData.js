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
import {bool, number, oneOf, shape, string, arrayOf} from 'prop-types'

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

export const TEACHER_QUERY = gql`
  query GetAssignment($assignmentLid: ID!) {
    assignment(id: $assignmentLid) {
      lid: _id
      gid: id
      name
      description
      dueAt
      unlockAt
      lockAt
      pointsPossible
      state
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
      course {
        lid: _id
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
        }
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
  allowedExtensions: arrayOf(string), // currently copied from the assignment
  set: shape({
    lid: string,
    name: string,
    __typename: oneOf(['Section', 'Group'])
  })
})

export const TeacherAssignmentShape = shape({
  lid: string.isRequired,
  name: string.isRequired,
  pointsPossible: number.isRequired,
  dueAt: string,
  lockAt: string,
  unlockAt: string,
  description: string,
  state: oneOf(['published', 'unpublished']).isRequired,
  assignmentGroup: AssignmentGroupShape.isRequired,
  modules: arrayOf(ModuleShape).isRequired,
  course: CourseShape.isRequired,
  submissionTypes: arrayOf(string).isRequired,
  allowedExtensions: arrayOf(string).isRequired,
  assignmentOverrides: shape({
    nodes: arrayOf(OverrideShape)
  }).isRequired
})

export const AssignmentShape = shape({
  lid: string.isRequired,
  name: string.isRequired,
  pointsPossible: number.isRequired,
  dueAt: string,
  lockAt: string,
  unlockAt: string,
  description: string.isRequired,
  state: oneOf(['published', 'unpublished']).isRequired,
  assignmentGroup: AssignmentGroupShape.isRequired,
  modules: arrayOf(ModuleShape).isRequired,
  course: CourseShape.isRequired,
  lockInfo: LockInfoShape.isRequired,
  submissionTypes: arrayOf(string).isRequired,
  allowedExtensions: arrayOf(string).isRequired,
  assignmentOverrides: shape({
    nodes: arrayOf(OverrideShape)
  }).isRequired
})
