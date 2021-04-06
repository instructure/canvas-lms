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

import axios from '@canvas/axios'
import pluralize from 'str-pluralize'
import {gql} from '@canvas/apollo'

const groupFragment = gql`
  fragment GroupFragment on LearningOutcomeGroup {
    _id
    outcomesCount
    childGroupsCount
    childGroups {
      nodes {
        _id
        title
        description
        outcomesCount
        childGroupsCount
        canEdit
      }
    }
  }
`

export const CHILD_GROUPS_QUERY = gql`
  query LearningOutcomesGroupQuery($id: ID!, $type: NodeType!) {
    context: legacyNode(type: $type, _id: $id) {
      ... on Account {
        _id
        rootOutcomeGroup {
          ...GroupFragment
        }
      }
      ... on Course {
        _id
        rootOutcomeGroup {
          ...GroupFragment
        }
      }
      ... on LearningOutcomeGroup {
        ...GroupFragment
      }
    }
  }
  ${groupFragment}
`

export const GROUP_DETAIL_QUERY = gql`
  query GroupDetailQuery(
    $id: ID!
    $outcomesCursor: String
    $outcomesContextId: ID!
    $outcomesContextType: String!
  ) {
    group: legacyNode(type: LearningOutcomeGroup, _id: $id) {
      ... on LearningOutcomeGroup {
        _id
        description
        title
        outcomesCount
        canEdit
        outcomes(first: 10, after: $outcomesCursor) {
          pageInfo {
            hasNextPage
            endCursor
          }
          edges {
            canUnlink
            node {
              ... on LearningOutcome {
                _id
                description
                title
                displayName
                canEdit
                contextType
                contextId
                friendlyDescription(
                  contextId: $outcomesContextId
                  contextType: $outcomesContextType
                ) {
                  _id
                  description
                }
              }
            }
          }
        }
      }
    }
  }
`

export const GROUP_DETAIL_QUERY_WITH_IMPORTED_OUTCOMES = gql`
  query GroupDetailQuery(
    $id: ID!
    $outcomeIsImportedContextType: String!
    $outcomeIsImportedContextId: ID!
    $outcomesCursor: String
  ) {
    group: legacyNode(type: LearningOutcomeGroup, _id: $id) {
      ... on LearningOutcomeGroup {
        _id
        description
        title
        outcomesCount
        outcomes(first: 10, after: $outcomesCursor) {
          pageInfo {
            hasNextPage
            endCursor
          }
          nodes {
            ... on LearningOutcome {
              _id
              description
              title
              displayName
              isImported(
                targetContextType: $outcomeIsImportedContextType
                targetContextId: $outcomeIsImportedContextId
              )
            }
          }
        }
      }
    }
  }
`

export const SET_OUTCOME_FRIENDLY_DESCRIPTION_MUTATION = gql`
  mutation SetOutcomeFriendlyDescription($input: SetFriendlyDescriptionInput!) {
    setFriendlyDescription(input: $input) {
      outcomeFriendlyDescription {
        _id
        description
      }
      errors {
        attribute
        message
      }
    }
  }
`

export const updateOutcomeGroup = (contextType, contextId, groupId, group) =>
  axios.put(
    `/api/v1/${pluralize(contextType).toLowerCase()}/${contextId}/outcome_groups/${groupId}`,
    group
  )

export const removeOutcomeGroup = (contextType, contextId, groupId) =>
  axios.delete(
    `/api/v1/${pluralize(contextType).toLowerCase()}/${contextId}/outcome_groups/${groupId}`
  )

export const removeOutcome = (contextType, contextId, groupId, outcomeId) =>
  axios.delete(
    `/api/v1/${pluralize(
      contextType
    ).toLowerCase()}/${contextId}/outcome_groups/${groupId}/outcomes/${outcomeId}`
  )

export const updateOutcome = (outcomeId, outcome) =>
  axios.put(`/api/v1/outcomes/${outcomeId}`, outcome)

export const moveOutcomeGroup = (contextType, contextId, groupId, newParentGroupId) =>
  axios.put(
    `/api/v1/${pluralize(contextType).toLowerCase()}/${contextId}/outcome_groups/${groupId}`,
    {parent_outcome_group_id: newParentGroupId}
  )

export const createOutcome = (contextType, contextId, groupId, outcome) =>
  axios.post(
    `/api/v1/${pluralize(
      contextType
    ).toLowerCase()}/${contextId}/outcome_groups/${groupId}/outcomes`,
    outcome
  )

export const addOutcomeGroup = (contextType, contextId, parentGroupId, title) => {
  return axios.post(
    `/api/v1/${pluralize(
      contextType
    ).toLowerCase()}/${contextId}/outcome_groups/${parentGroupId}/subgroups`,
    {title}
  )
}
