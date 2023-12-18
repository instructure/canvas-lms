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
import pluralize from '@canvas/util/stringPluralize'
import {gql} from '@canvas/apollo'

export const groupFields = `
  _id
  title
`

const groupFragment = gql`
  fragment GroupFragment on LearningOutcomeGroup {
    ${groupFields}
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
        title
        parentOutcomeGroup {
          _id
          title
        }
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
    $targetGroupId: ID
  ) {
    group: legacyNode(type: LearningOutcomeGroup, _id: $id) {
      ... on LearningOutcomeGroup {
        _id
        title
        contextType
        contextId
        outcomesCount(searchQuery: $searchQuery)
        notImportedOutcomesCount(targetGroupId: $targetGroupId)
        outcomes(searchQuery: $searchQuery, first: 10, after: $outcomesCursor) {
          pageInfo {
            hasNextPage
            endCursor
          }
          edges {
            _id
            node {
              ... on LearningOutcome {
                _id
                description
                title
                calculationMethod
                calculationInt
                masteryPoints
                ratings {
                  description
                  points
                }
                isImported(
                  targetContextType: $outcomesContextType
                  targetContextId: $outcomesContextId
                ) @include(if: $outcomeIsImported)
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

export const SEARCH_GROUP_OUTCOMES = gql`
  query SearchGroupOutcomesQuery(
    $id: ID!
    $outcomesCursor: String
    $outcomesContextId: ID!
    $outcomesContextType: String!
    $searchQuery: String
    $targetGroupId: ID
  ) {
    group: legacyNode(type: LearningOutcomeGroup, _id: $id) {
      ... on LearningOutcomeGroup {
        _id
        description
        title
        outcomesCount(searchQuery: $searchQuery)
        notImportedOutcomesCount(targetGroupId: $targetGroupId)
        outcomes(searchQuery: $searchQuery, first: 10, after: $outcomesCursor) {
          pageInfo {
            hasNextPage
            endCursor
          }
          edges {
            canUnlink
            _id
            node {
              ... on LearningOutcome {
                _id
                description
                title
                displayName
                calculationMethod
                calculationInt
                masteryPoints
                ratings {
                  description
                  points
                }
                canEdit
                canArchive(contextId: $outcomesContextId, contextType: $outcomesContextType)
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
            group {
              _id
              title
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

export const IMPORT_OUTCOMES = gql`
  mutation ImportOutcomes($input: ImportOutcomesInput!) {
    importOutcomes(input: $input) {
      errors {
        attribute
        message
      }
      progress {
        _id
        state
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
        calculationMethod
        calculationInt
        masteryPoints
        pointsPossible
        ratings {
          description
          points
        }
      }
      errors {
        attribute
        message
      }
    }
  }
`

export const DELETE_OUTCOME_LINKS = gql`
  mutation DeleteOutcomeLinks($input: DeleteOutcomeLinksInput!) {
    deleteOutcomeLinks(input: $input) {
      deletedOutcomeLinkIds
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
        calculationMethod
        calculationInt
        masteryPoints
        pointsPossible
        ratings {
          description
          points
        }
      }
      errors {
        attribute
        message
      }
    }
  }
`

export const MOVE_OUTCOME_LINKS = gql`
  mutation MoveOutcomeLinks($input: MoveOutcomeLinksInput!) {
    moveOutcomeLinks(input: $input) {
      movedOutcomeLinks {
        _id
        group {
          _id
          title
        }
      }
      errors {
        attribute
        message
      }
    }
  }
`

export const UPDATE_LEARNING_OUTCOME_GROUP = gql`
  mutation UpdateLearningOutcomeGroup($input: UpdateLearningOutcomeGroupInput!) {
    updateLearningOutcomeGroup(input: $input) {
      learningOutcomeGroup {
        _id
        title
        description
        vendorGuid
        parentOutcomeGroup {
          _id
          title
        }
      }
      errors {
        attribute
        message
      }
    }
  }
`

export const CREATE_LEARNING_OUTCOME_GROUP = gql`
  mutation CreateLearningOutcomeGroup($input: CreateLearningOutcomeGroupInput!) {
    createLearningOutcomeGroup(input: $input) {
      learningOutcomeGroup {
        _id
        title
        description
        vendorGuid
        parentOutcomeGroup {
          _id
          title
        }
      }
      errors {
        attribute
        message
      }
    }
  }
`

export const COURSE_ALIGNMENT_STATS = gql`
  query GetCourseAlignmentStatsQuery($id: ID!) {
    course(id: $id) {
      outcomeAlignmentStats {
        totalOutcomes
        alignedOutcomes
        totalAlignments
        totalArtifacts
        alignedArtifacts
        artifactAlignments
      }
    }
  }
`

export const SEARCH_OUTCOME_ALIGNMENTS = gql`
  query SearchOutcomeAlignmentsQuery(
    $id: ID!
    $outcomesCursor: String
    $outcomesContextId: ID!
    $outcomesContextType: String!
    $searchQuery: String
    $searchFilter: String
  ) {
    group: legacyNode(type: LearningOutcomeGroup, _id: $id) {
      ... on LearningOutcomeGroup {
        _id
        outcomesCount(searchQuery: $searchQuery)
        outcomes(
          searchQuery: $searchQuery
          filter: $searchFilter
          first: 10
          after: $outcomesCursor
        ) {
          pageInfo {
            hasNextPage
            endCursor
          }
          edges {
            node {
              ... on LearningOutcome {
                _id
                title
                description
                alignments(contextId: $outcomesContextId, contextType: $outcomesContextType) {
                  _id
                  title
                  contentType
                  assignmentContentType
                  assignmentWorkflowState
                  url
                  moduleName
                  moduleUrl
                  moduleWorkflowState
                  quizItems {
                    _id
                    title
                  }
                  alignmentsCount
                }
              }
            }
          }
        }
      }
    }
  }
`

export const removeOutcomeGroup = (contextType, contextId, groupId) =>
  axios.delete(
    `/api/v1/${pluralize(contextType).toLowerCase()}/${contextId}/outcome_groups/${groupId}`
  )
