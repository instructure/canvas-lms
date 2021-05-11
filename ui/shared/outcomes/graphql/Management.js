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
    title
    description
    outcomesCount
    childGroupsCount
    canEdit
  }
`

const childGroupsFragment = gql`
  fragment ChildGroupsFragment on LearningOutcomeGroup {
    childGroups {
      nodes {
        ...GroupFragment
      }
    }
  }
  ${groupFragment}
`

export const CHILD_GROUPS_QUERY = gql`
  query LearningOutcomesGroupQuery($id: ID!, $type: NodeType!) {
    context: legacyNode(type: $type, _id: $id) {
      ... on Account {
        _id
        rootOutcomeGroup {
          ...GroupFragment
          ...ChildGroupsFragment
        }
      }
      ... on Course {
        _id
        rootOutcomeGroup {
          ...GroupFragment
          ...ChildGroupsFragment
        }
      }
      ... on LearningOutcomeGroup {
        _id
        outcomesCount
        childGroupsCount
        ...ChildGroupsFragment
      }
    }
  }
  ${groupFragment}
  ${childGroupsFragment}
`

export const FIND_GROUP_OUTCOMES = gql`
  query GroupDetailWithSearchQuery(
    $id: ID!
    $outcomesContextId: ID!
    $outcomesContextType: String!
    $outcomeIsImported: Boolean!
    $searchQuery: String
    $outcomesCursor: String
  ) {
    group: legacyNode(type: LearningOutcomeGroup, _id: $id) {
      ... on LearningOutcomeGroup {
        _id
        description
        title
        outcomesCount(searchQuery: $searchQuery)
        canEdit
        outcomes(searchQuery: $searchQuery, first: 10, after: $outcomesCursor) {
          pageInfo {
            hasNextPage
            endCursor
          }
          edges {
            node {
              ... on LearningOutcome {
                _id
                description
                title
                displayName
                isImported(
                  targetContextType: $outcomesContextType
                  targetContextId: $outcomesContextId
                ) @include(if: $outcomeIsImported)
              }
            }
          }
        }
      }
    }
  }
`

export const SEARCH_GROUP_OUTCOMES = gql`
  query SearchGroupDetailQuery(
    $id: ID!
    $outcomesCursor: String
    $outcomesContextId: ID!
    $outcomesContextType: String!
    $searchQuery: String
  ) {
    group: legacyNode(type: LearningOutcomeGroup, _id: $id) {
      ... on LearningOutcomeGroup {
        _id
        description
        title
        outcomesCount(searchQuery: $searchQuery)
        canEdit
        outcomes(searchQuery: $searchQuery, first: 10, after: $outcomesCursor) {
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

export const CREATE_LEARNING_OUTCOME = gql`
  mutation CreateLearningOutcome($input: CreateLearningOutcomeInput!) {
    createLearningOutcome(input: $input) {
      learningOutcome {
        _id
        title
        displayName
        description
      }
      errors {
        attribute
        message
      }
    }
  }
`

export const UPDATE_LEARNING_OUTCOME = gql`
  mutation UpdateLearningOutcome($input: UpdateLearningOutcomeInput!) {
    updateLearningOutcome(input: $input) {
      learningOutcome {
        _id
        title
        displayName
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

export const moveOutcomeGroup = (contextType, contextId, groupId, newParentGroupId) =>
  axios.put(
    `/api/v1/${pluralize(contextType).toLowerCase()}/${contextId}/outcome_groups/${groupId}`,
    {parent_outcome_group_id: newParentGroupId}
  )

export const addOutcomeGroup = (contextType, contextId, parentGroupId, title) => {
  return axios.post(
    `/api/v1/${pluralize(
      contextType
    ).toLowerCase()}/${contextId}/outcome_groups/${parentGroupId}/subgroups`,
    {title}
  )
}

export const moveOutcome = (
  contextType,
  contextId,
  outcomeId,
  oldParentGroupId,
  newParentGroupId
) =>
  axios.put(
    `/api/v1/${pluralize(
      contextType
    ).toLowerCase()}/${contextId}/outcome_groups/${newParentGroupId}/outcomes/${outcomeId}`,
    {move_from: oldParentGroupId}
  )
