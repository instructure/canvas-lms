/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {arrayOf, bool, number, shape, string} from 'prop-types'

import {AssignmentOverride} from './AssignmentOverride'
import {AssessmentRequest} from './AssessmentRequest'
import {PeerReviews} from './PeerReviews'

export const Assignment = {
  fragment: gql`
    fragment Assignment on Assignment {
      id
      _id
      dueAt(applyOverrides: false)
      lockAt(applyOverrides: false)
      unlockAt(applyOverrides: false)
      onlyVisibleToOverrides
      pointsPossible
      assignmentOverrides {
        nodes {
          ...AssignmentOverride
        }
      }
      assessmentRequestsForCurrentUser {
        ...AssessmentRequest
      }
      peerReviews {
        ...PeerReviews
      }
    }
    ${AssignmentOverride.fragment}
    ${AssessmentRequest.fragment}
    ${PeerReviews.fragment}
  `,

  shape: shape({
    id: string,
    _id: string,
    dueAt: string,
    lockAt: string,
    unlockAt: string,
    onlyVisibleToOverrides: bool,
    pointsPossible: number,
    assignmentOverrides: shape({nodes: arrayOf(AssignmentOverride.shape)}),
    assessmentRequest: arrayOf(AssessmentRequest.shape),
    peerReviews: PeerReviews.shape
  }),

  mock: ({
    id = 'QXNzaWdubWVudC0x',
    _id = '1',
    dueAt = '2021-03-30T23:59:59-06:00',
    lockAt = '2021-04-03T23:59:59-06:00',
    unlockAt = '2021-03-24T00:00:00-06:00',
    onlyVisibleToOverrides = false,
    pointsPossible = 10,
    assignmentOverrides = {
      nodes: [AssignmentOverride.mock()],
      __typename: 'AssignmentOverrideConnection'
    },
    assessmentRequestsForCurrentUser = [AssessmentRequest.mock()],
    peerReviews = PeerReviews.mock()
  } = {}) => ({
    id,
    _id,
    dueAt,
    lockAt,
    unlockAt,
    onlyVisibleToOverrides,
    pointsPossible,
    assignmentOverrides,
    assessmentRequestsForCurrentUser,
    peerReviews,
    __typename: 'Assignment'
  })
}

export const DefaultMocks = {
  Assignment: () => ({
    _id: '1',
    dueAt: '2021-03-25T13:22:24-06:00',
    lockAt: '2021-03-27T13:22:24-06:00',
    unlockAt: '2021-03-21T13:22:24-06:00',
    onlyVisibleToOverrides: false,
    pointsPossible: 10,
    assignmentOverrides: {
      nodes: [AssignmentOverride.mock()],
      __typename: 'AssignmentOverrideConnection'
    }
  })
}
