/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
      anonymizedUser {
        _id
        displayName: shortName
      }
      anonymousId
      workflowState
      assetSubmissionType
      assetId
    }
  `,

  shape: shape({
    anonymizedUser: shape({
      id: string,
      displayName: string,
    }),
    anonymousId: string,
    workflowState: string,
  }),

  mock: ({
    anonymizedUser = {_id: '1', displayName: 'Morty Smith', __typename: 'AnonymizedUser'},
    anonymousId = '7a8c1',
    workflowState = 'assigned',
  } = {}) => ({
    anonymizedUser,
    anonymousId,
    workflowState,
    __typename: 'AssessmentRequest',
  }),
}
