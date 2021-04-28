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

import {Discussion} from './Discussion'
import {DiscussionEntry} from './DiscussionEntry'
import gql from 'graphql-tag'

export const DISCUSSION_QUERY = gql`
  query GetDiscussionQuery($discussionID: ID!, $page: String, $perPage: Int) {
    legacyNode(_id: $discussionID, type: Discussion) {
      ... on Discussion {
        ...Discussion
        rootDiscussionEntriesConnection(after: $page, first: $perPage) {
          nodes {
            ...DiscussionEntry
          }
          pageInfo {
            endCursor
            hasNextPage
            hasPreviousPage
            startCursor
          }
        }
      }
    }
  }
  ${Discussion.fragment}
  ${DiscussionEntry.fragment}
`

export const DISCUSSION_SUBENTRIES_QUERY = gql`
  query GetDiscussionSubentriesQuery($discussionEntryID: ID!, $page: String, $perPage: Int) {
    legacyNode(_id: $discussionEntryID, type: DiscussionEntry) {
      ... on DiscussionEntry {
        ...DiscussionEntry
        discussionSubentriesConnection(after: $page, first: $perPage) {
          nodes {
            ...DiscussionEntry
          }
          pageInfo {
            endCursor
            hasNextPage
            hasPreviousPage
            startCursor
          }
        }
      }
    }
  }
  ${DiscussionEntry.fragment}
`
