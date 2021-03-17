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

import {gql} from 'jsx/canvas-apollo'
import axios from 'axios'
import pluralize from 'str/pluralize'

const groupFragment = gql`
  fragment GroupFragment on LearningOutcomeGroup {
    _id
    outcomesCount
    childGroupsCount
    childGroups {
      nodes {
        description
        _id
        outcomesCount
        childGroupsCount
        title
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
  query GroupDetailQuery($id: ID!, $outcomesCursor: String) {
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
