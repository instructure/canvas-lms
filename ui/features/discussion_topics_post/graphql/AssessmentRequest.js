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
import {shape, string} from 'prop-types'

export const AssessmentRequest = {
  fragment: gql`
    fragment AssessmentRequest on AssessmentRequest {
      _id
      createdAt
      updatedAt
      user {
        _id
        displayName: shortName
      }
      workflowState
    }
  `,

  shape: shape({
    _id: string,
    createdAt: string,
    updatedAt: string,
    user: shape({
      id: string,
      displayName: string,
    }),
    workflowState: string,
  }),

  mock: ({
    _id = '1',
    createdAt = '2021-06-23T12:37:45-06:00',
    updatedAt = '2021-06-25T09:24:21-06:00',
    user = {_id: '1', displayName: 'Morty Smith', __typename: 'User'},
    workflowState = 'assigned',
  } = {}) => ({
    _id,
    createdAt,
    updatedAt,
    user,
    workflowState,
    __typename: 'AssessmentRequest',
  }),
}
