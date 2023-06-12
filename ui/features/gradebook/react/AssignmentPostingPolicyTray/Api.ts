// @ts-nocheck
/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import {createClient, gql} from '@canvas/apollo'

export const SET_ASSIGNMENT_POST_POLICY_MUTATION = gql`
  mutation SetAssignmentPostPolicy($assignmentId: ID!, $postManually: Boolean!) {
    setAssignmentPostPolicy(input: {assignmentId: $assignmentId, postManually: $postManually}) {
      postPolicy {
        postManually
      }
      errors {
        attribute
        message
      }
    }
  }
`

export function setAssignmentPostPolicy({assignmentId, postManually}) {
  return createClient()
    .mutate({
      mutation: SET_ASSIGNMENT_POST_POLICY_MUTATION,
      variables: {assignmentId, postManually},
    })
    .then(response => {
      const queryResponse = response && response.data && response.data.setAssignmentPostPolicy
      if (queryResponse) {
        if (queryResponse.postPolicy) {
          return {postManually: queryResponse.postPolicy.postManually}
        } else if (queryResponse.errors && queryResponse.errors.length > 0) {
          throw new Error(queryResponse.errors[0].message)
        }
      }

      throw new Error('no postPolicy or error provided in response')
    })
}
