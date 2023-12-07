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

import {string} from 'prop-types'
import gql from 'graphql-tag'

import {AssignmentGroup} from './AssignmentGroup'

export const Assignment = {
  fragment: gql`
    fragment Assignment on Assignment {
      _id
      id
      name
      postToSis
      pointsPossible
      assignmentGroup {
        ...AssignmentGroup
      }
    }
    ${AssignmentGroup.fragment}
  `,
  shape: {
    _id: string,
    id: string,
    name: string,
    postToSis: string,
    pointsPossible: string,
    assignmentGroup: AssignmentGroup.shape,
  },
  mock: ({
    _id = '1',
    id = '1',
    name = 'Homework',
    postToSis = '1',
    pointsPossible = '10',
    assignmentGroup = AssignmentGroup.mock(),
  } = {}) => ({
    _id,
    id,
    name,
    postToSis,
    pointsPossible,
    assignmentGroup,
  }),
}
