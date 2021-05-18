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
import {PageInfo} from './PageInfo'

export const DISCUSSION_QUERY = gql`
  query GetDiscussionQuery(
    $discussionID: ID!
    $page: String
    $perPage: Int!
    $searchTerm: String
    $rootEntries: Boolean
    $filter: DiscussionFilterType
    $sort: DiscussionSortOrderType
  ) {
    legacyNode(_id: $discussionID, type: Discussion) {
      ... on Discussion {
        ...Discussion
        discussionEntriesConnection(
          after: $page
          first: $perPage
          searchTerm: $searchTerm
          rootEntries: $rootEntries
          filter: $filter
          sortOrder: $sort
        ) {
          nodes {
            ...DiscussionEntry
          }
          pageInfo {
            ...PageInfo
          }
        }
        entriesTotalPages(
          perPage: $perPage
          rootEntries: $rootEntries
          filter: $filter
          searchTerm: $searchTerm
        )
      }
    }
  }
  ${Discussion.fragment}
  ${DiscussionEntry.fragment}
  ${PageInfo.fragment}
`

export const DISCUSSION_SUBENTRIES_QUERY = gql`
  query GetDiscussionSubentriesQuery(
    $discussionEntryID: ID!
    $page: String
    $perPage: Int
    $sort: DiscussionSortOrderType
  ) {
    legacyNode(_id: $discussionEntryID, type: DiscussionEntry) {
      ... on DiscussionEntry {
        ...DiscussionEntry
        discussionSubentriesConnection(after: $page, first: $perPage, sortOrder: $sort) {
          nodes {
            ...DiscussionEntry
          }
          pageInfo {
            ...PageInfo
          }
        }
      }
    }
  }
  ${DiscussionEntry.fragment}
  ${PageInfo.fragment}
`
