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
import {bool, number, shape, string, arrayOf} from 'prop-types'

export const STUDENT_VIEW_QUERY = gql`
  query GetAssignment($assignmentLid: ID!) {
    assignment: legacyNode(type: Assignment, _id: $assignmentLid) {
      ... on Assignment {
        description
        dueAt
        lockAt
        name
        pointsPossible
        unlockAt
        assignmentGroup {
          name
        }
        lockInfo {
          isLocked
        }
        modules {
          name
        }
      }
    }
  }
`

export const StudentAssignmentShape = shape({
  description: string.isRequired,
  dueAt: string,
  lockAt: string,
  name: string.isRequired,
  pointsPossible: number.isRequired,
  unlockAt: string,
  assignmentGroup: shape({
    name: string.isRequired
  }).isRequired,
  lockInfo: shape({
    isLocked: bool.isRequired
  }).isRequired,
  modules: arrayOf(shape({name: string.isRequired})).isRequired
})
