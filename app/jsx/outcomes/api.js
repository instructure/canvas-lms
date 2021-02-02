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

import {gql} from 'jsx/canvas-apollo'

const parentAccountsFragment = gql`
  fragment ParentAccountsFragment on Account {
    parentAccountsConnection {
      nodes {
        rootOutcomeGroup {
          _id
          outcomesCount
          childGroupsCount
          title
        }
      }
    }
  }
`

export const FIND_GROUPS_QUERY = gql`
  query LearningOutcomesGroupQuery(
    $id: ID!
    $type: NodeType!
    $rootGroupId: ID!
    $includeGlobalRootGroup: Boolean!
  ) {
    context: legacyNode(type: $type, _id: $id) {
      ... on Account {
        _id
        ...ParentAccountsFragment
      }
      ... on Course {
        _id
        account {
          rootOutcomeGroup {
            _id
            outcomesCount
            childGroupsCount
            title
          }
          ...ParentAccountsFragment
        }
      }
    }
    globalRootGroup: learningOutcomeGroup(id: $rootGroupId) @include(if: $includeGlobalRootGroup) {
      _id
      outcomesCount
      childGroupsCount
    }
  }
  ${parentAccountsFragment}
`
