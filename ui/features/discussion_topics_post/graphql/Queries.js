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
import {DiscussionEntryDraft} from './DiscussionEntryDraft'
import gql from 'graphql-tag'
import {PageInfo} from './PageInfo'
import {User} from './User'

export const DISCUSSION_QUERY = gql`
  query GetDiscussionQuery(
    $discussionID: ID!
    $page: String
    $perPage: Int!
    $searchTerm: String
    $rootEntries: Boolean
    $filter: DiscussionFilterType
    $sort: DiscussionSortOrderType
    $courseID: ID
    $rolePillTypes: [String!] = ["TaEnrollment", "TeacherEnrollment"]
  ) {
    legacyNode(_id: $discussionID, type: Discussion) {
      ... on Discussion {
        ...Discussion
        editor {
          ...User
          courseRoles(courseId: $courseID, roleTypes: $rolePillTypes)
        }
        author {
          ...User
          courseRoles(courseId: $courseID, roleTypes: $rolePillTypes)
        }
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
            editor {
              ...User
              courseRoles(courseId: $courseID, roleTypes: $rolePillTypes)
            }
            author {
              ...User
              courseRoles(courseId: $courseID, roleTypes: $rolePillTypes)
            }
          }
          pageInfo {
            ...PageInfo
          }
        }
        discussionEntryDraftsConnection {
          nodes {
            ...DiscussionEntryDraft
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
        searchEntryCount(filter: $filter, searchTerm: $searchTerm)
      }
    }
  }
  ${User.fragment}
  ${Discussion.fragment}
  ${DiscussionEntry.fragment}
  ${DiscussionEntryDraft.fragment}
  ${PageInfo.fragment}
`

export const DISCUSSION_SUBENTRIES_QUERY = gql`
  query GetDiscussionSubentriesQuery(
    $discussionEntryID: ID!
    $after: String
    $before: String
    $first: Int
    $last: Int
    $sort: DiscussionSortOrderType
    $courseID: ID
    $rolePillTypes: [String!] = ["TaEnrollment", "TeacherEnrollment"]
    $relativeEntryId: ID
    $includeRelativeEntry: Boolean
    $beforeRelativeEntry: Boolean
  ) {
    legacyNode(_id: $discussionEntryID, type: DiscussionEntry) {
      ... on DiscussionEntry {
        ...DiscussionEntry
        editor {
          ...User
          courseRoles(courseId: $courseID, roleTypes: $rolePillTypes)
        }
        author {
          ...User
          courseRoles(courseId: $courseID, roleTypes: $rolePillTypes)
        }
        discussionSubentriesConnection(
          after: $after
          before: $before
          first: $first
          last: $last
          sortOrder: $sort
          relativeEntryId: $relativeEntryId
          includeRelativeEntry: $includeRelativeEntry
          beforeRelativeEntry: $beforeRelativeEntry
        ) {
          nodes {
            ...DiscussionEntry
            editor {
              ...User
              courseRoles(courseId: $courseID, roleTypes: $rolePillTypes)
            }
            author {
              ...User
              courseRoles(courseId: $courseID, roleTypes: $rolePillTypes)
            }
          }
          pageInfo {
            ...PageInfo
          }
        }
      }
    }
  }
  ${User.fragment}
  ${DiscussionEntry.fragment}
  ${PageInfo.fragment}
`
