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

export const UPSERT_STANDARD_GRADING_STATUS_MUTATION = gql`
  mutation UpsertStandardGradingStatusMutation($id: ID, $color: String!, $name: String!) {
    upsertStandardGradeStatus(input: {id: $id, color: $color, name: $name}) {
      standardGradeStatus {
        id: _id
        name
        color
      }
      errors {
        attribute
        message
      }
    }
  }
`

export const UPSERT_CUSTOM_GRADING_STATUS_MUTATION = gql`
  mutation UpsertCustomGradingStatusMutation($id: ID, $color: String!, $name: String!) {
    upsertCustomGradeStatus(input: {id: $id, color: $color, name: $name}) {
      customGradeStatus {
        id: _id
        name
        color
      }
      errors {
        attribute
        message
      }
    }
  }
`

export const DELETE_CUSTOM_GRADING_STATUS_MUTATION = gql`
  mutation DeleteCustomGradingStatusMutation($id: ID!) {
    deleteCustomGradeStatus(input: {id: $id}) {
      customGradeStatusId
      errors {
        attribute
        message
      }
    }
  }
`
