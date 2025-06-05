/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {gql} from '@apollo/client'

const userFields = gql`
  fragment UserFields on User {
    __typename
    gid: id
    lid: _id
    name
    shortName
    sortableName
    avatarUrl
    email
  }
`

const assignmentOverridesNodes = gql`
  fragment AssignmentOverrides on AssignmentOverrideConnection {
    nodes {
      gid: id
      lid: _id
      title
      dueAt
      lockAt
      unlockAt
      set {
        __typename
        ... on Section {
          lid: _id
          sectionName: name
        }
        ... on Group {
          lid: _id
          groupName: name
        }
        ... on AdhocStudents {
          students {
            lid: _id
            studentName: name
          }
        }
      }
    }
  }
`

export const TEACHER_QUERY = gql`
  query GetAssignment($assignmentLid: ID!) {
    assignment(id: $assignmentLid) {
      __typename
      id
      lid: _id
      gid: id
      name
      description
      dueAt(applyOverrides: false)
      unlockAt(applyOverrides: false)
      lockAt(applyOverrides: false)
      pointsPossible
      state
      needsGradingCount
      onlyVisibleToOverrides
      peerReviews {
        enabled
      }
      lockInfo {
        isLocked
      }
      assignmentGroup {
        lid: _id
        name
      }
      modules {
        lid: _id
        name
      }
      submissionTypes
      allowedExtensions
      allowedAttempts
      anonymizeStudents
      course {
        lid: _id
        modulesConnection(first: 0) {
          pageInfo {
            hasNextPage
          }
        }
        assignmentGroupsConnection(first: 0) {
          pageInfo {
            hasNextPage
          }
        }
      }
      assignmentOverrides {
        pageInfo {
          startCursor
          endCursor
          hasNextPage
          hasPreviousPage
        }
        ...AssignmentOverrides
      }
      hasSubmittedSubmissions
      submissionsDownloads
      submissions: submissionsConnection(
        filter: {states: [submitted, unsubmitted, graded, ungraded, pending_review]}
      ) {
        pageInfo {
          startCursor
          endCursor
          hasNextPage
          hasPreviousPage
        }
        nodes {
          gid: id
          lid: _id
          attempt
          submissionStatus
          grade
          gradingStatus
          score
          state
          excused
          latePolicyStatus
          submittedAt
          user {
            ...UserFields
          }
        }
      }
    }
  }
  ${userFields}
  ${assignmentOverridesNodes}
`

export const TEACHER_EDIT_QUERY = gql`
  query GetAssignmentForEdit($assignmentLid: ID!) {
    assignment(id: $assignmentLid) {
      lid: _id
      state
      hasSubmittedSubmissions
      course {
        lid: _id
      }
    }
  }
`
