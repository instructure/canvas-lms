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

const groupFragment = gql`
  fragment GroupFragment on LearningOutcomeGroup {
    _id
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
          outcomesCount
          childGroupsCount
        }
      }
      ... on Course {
        _id
        rootOutcomeGroup {
          ...GroupFragment
          outcomesCount
          childGroupsCount
        }
      }
      ... on LearningOutcomeGroup {
        ...GroupFragment
      }
    }
  }
  ${groupFragment}
`
