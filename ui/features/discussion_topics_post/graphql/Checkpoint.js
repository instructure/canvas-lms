/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {AssignmentOverride} from './AssignmentOverride'
import {arrayOf, bool, number, shape, string} from 'prop-types'

export const Checkpoint = {
  fragment: gql`
    fragment Checkpoint on Checkpoint {
      name
      tag
      pointsPossible
      dueAt
      onlyVisibleToOverrides
      assignmentOverrides {
        nodes {
          ...AssignmentOverride
        }
      }
    }
    ${AssignmentOverride.fragment}
  `,

  shape: shape({
    dueAt: string,
    onlyVisibleToOverrides: bool,
    pointsPossible: number,
    assignmentOverrides: shape({nodes: arrayOf(AssignmentOverride.shape)}),
  }),

  mock: ({
    dueAt = '2021-03-30T23:59:59-06:00',
    onlyVisibleToOverrides = false,
    pointsPossible = 10,
    assignmentOverrides = {
      nodes: [AssignmentOverride.mock()],
      __typename: 'AssignmentOverrideConnection',
    },
  } = {}) => ({
    dueAt,
    onlyVisibleToOverrides,
    pointsPossible,
    assignmentOverrides,
    __typename: 'Assignment',
  }),
}
