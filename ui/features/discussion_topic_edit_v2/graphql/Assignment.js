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
import {bool, number, shape, string} from 'prop-types'
import {AssignmentGroup} from './AssignmentGroup'
import {AssignmentOverride} from './AssignmentOverride'

export const Assignment = {
  fragment: gql`
    fragment Assignment on Assignment {
      id
      _id
      name
      postToSis
      pointsPossible
      gradingType
      importantDates
      onlyVisibleToOverrides
      dueAt(applyOverrides: false)
      unlockAt(applyOverrides: false)
      lockAt(applyOverrides: false)
      gradingStandard {
        id
        _id
      }
      peerReviews {
        anonymousReviews
        automaticReviews
        count
        dueAt
        enabled
        intraReviews
      }
      assignmentGroup {
        ...AssignmentGroup
      }
      assignmentOverrides {
        nodes {
          ...AssignmentOverride
        }
      }
    }
    ${AssignmentGroup.fragment}
    ${AssignmentOverride.fragment}
  `,

  shape: shape({
    _id: string,
    id: string,
    name: string,
    assignmentGroup: AssignmentGroup.shape,
    postToSis: bool,
    pointsPossible: number,
    gradingType: string,
    importantDates: bool,
    onlyVisibleToOverrides: bool,
    unlockAt: string,
    dueAt: string,
    lockAt: string,
    peerReviews: shape({
      anonymousReviews: bool,
      automaticReviews: bool,
      count: number,
      dueAt: string,
      enabled: bool,
      intraReviews: bool,
    }),
    assignmentOverrides: AssignmentOverride.shape(),
  }),

  mock: ({
    id = 'gfhrgsjaksa==',
    _id = '9',
    name = 'This is an Assignment',
    assignmentGroup = AssignmentGroup.mock(),
    postToSis = false,
    pointsPossible = 10,
    gradingType = 'points',
    importantDates = false,
    onlyVisibleToOverrides = false,
    unlockAt = null,
    dueAt = null,
    lockAt = null,
    peerReviews = null,
    assignmentOverrides = null,
  } = {}) => ({
    id,
    _id,
    name,
    assignmentGroup,
    postToSis,
    pointsPossible,
    gradingType,
    importantDates,
    onlyVisibleToOverrides,
    unlockAt,
    dueAt,
    lockAt,
    peerReviews,
    assignmentOverrides,
    __typename: 'Assignment',
  }),
}
