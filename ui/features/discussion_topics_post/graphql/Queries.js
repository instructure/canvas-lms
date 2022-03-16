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

import {AnonymousUser} from './AnonymousUser'
import {Discussion} from './Discussion'
import {DiscussionEntry} from './DiscussionEntry'
import {DiscussionEntryDraft} from './DiscussionEntryDraft'
import gql from 'graphql-tag'
import {PageInfo} from './PageInfo'
import {User} from './User'
import {GroupSet} from './GroupSet'
import {Group} from './Group'

export const DISCUSSION_QUERY = gql`
  query GetDiscussionQuery(
    $discussionID: ID!
    $page: String
    $perPage: Int!
    $searchTerm: String
    $rootEntries: Boolean
    $filter: DiscussionFilterType
    $sort: DiscussionSortOrderType
    $courseID: String
    $rolePillTypes: [String!] = ["TaEnrollment", "TeacherEnrollment", "DesignerEnrollment"]
  ) {
    legacyNode(_id: $discussionID, type: Discussion) {
      ... on Discussion {
        ...Discussion
        editor(courseId: $courseID, roleTypes: $rolePillTypes) {
          ...User
          courseRoles(courseId: $courseID, roleTypes: $rolePillTypes)
        }
        author(courseId: $courseID, roleTypes: $rolePillTypes) {
          ...User
          courseRoles(courseId: $courseID, roleTypes: $rolePillTypes)
        }
        anonymousAuthor {
          ...AnonymousUser
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
            editor(courseId: $courseID, roleTypes: $rolePillTypes) {
              ...User
              courseRoles(courseId: $courseID, roleTypes: $rolePillTypes)
            }
            author(courseId: $courseID, roleTypes: $rolePillTypes) {
              ...User
              courseRoles(courseId: $courseID, roleTypes: $rolePillTypes)
            }
            anonymousAuthor {
              ...AnonymousUser
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
        groupSet {
          ...GroupSet
          groupsConnection {
            nodes {
              ...Group
            }
          }
        }
      }
    }
  }
  ${User.fragment}
  ${AnonymousUser.fragment}
  ${Discussion.fragment}
  ${DiscussionEntry.fragment}
  ${DiscussionEntryDraft.fragment}
  ${PageInfo.fragment}
  ${GroupSet.fragment}
  ${Group.fragment}
`

export const DISCUSSION_SUBENTRIES_QUERY = gql`
  query GetDiscussionSubentriesQuery(
    $discussionEntryID: ID!
    $after: String
    $before: String
    $first: Int
    $last: Int
    $sort: DiscussionSortOrderType
    $courseID: String
    $rolePillTypes: [String!] = ["TaEnrollment", "TeacherEnrollment", "DesignerEnrollment"]
    $relativeEntryId: ID
    $includeRelativeEntry: Boolean
    $beforeRelativeEntry: Boolean
  ) {
    legacyNode(_id: $discussionEntryID, type: DiscussionEntry) {
      ... on DiscussionEntry {
        ...DiscussionEntry
        editor(courseId: $courseID, roleTypes: $rolePillTypes) {
          ...User
          courseRoles(courseId: $courseID, roleTypes: $rolePillTypes)
        }
        author(courseId: $courseID, roleTypes: $rolePillTypes) {
          ...User
          courseRoles(courseId: $courseID, roleTypes: $rolePillTypes)
        }
        anonymousAuthor {
          ...AnonymousUser
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
            editor(courseId: $courseID, roleTypes: $rolePillTypes) {
              ...User
              courseRoles(courseId: $courseID, roleTypes: $rolePillTypes)
            }
            author(courseId: $courseID, roleTypes: $rolePillTypes) {
              ...User
              courseRoles(courseId: $courseID, roleTypes: $rolePillTypes)
            }
            anonymousAuthor {
              ...AnonymousUser
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
  ${AnonymousUser.fragment}
  ${DiscussionEntry.fragment}
  ${PageInfo.fragment}
`
