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

import {gql} from '@apollo/client'

export const SET_WORKFLOW = gql`
  mutation SetWorkflow($id: ID!, $workflow: AssignmentState!) {
    updateAssignment(input: {id: $id, state: $workflow}) {
      assignment {
        __typename
        id
        state
      }
    }
  }
`

export const CREATE_ALLOCATION_RULE_MUTATION = gql`
  mutation CreateAllocationRule($input: CreateAllocationRuleInput!) {
    createAllocationRule(input: $input) {
      allocationRules {
        _id
        assessor {
          _id
          name
        }
        assessee {
          _id
          name
        }
        mustReview
        reviewPermitted
        appliesToAssessor
      }
      allocationErrors {
        message
        attribute
        attributeId
      }
    }
  }
`

export const UPDATE_ALLOCATION_RULE_MUTATION = gql`
  mutation UpdateAllocationRule($input: UpdateAllocationRuleInput!) {
    updateAllocationRule(input: $input) {
      allocationRules {
        _id
        mustReview
        reviewPermitted
        appliesToAssessor
        assessor {
          _id
          name
        }
        assessee {
          _id
          name
        }
      }
      allocationErrors {
        attributeId
        message
      }
    }
  }
`
