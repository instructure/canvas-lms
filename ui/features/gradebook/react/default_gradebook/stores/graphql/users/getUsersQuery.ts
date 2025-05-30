/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

export const GET_USERS_QUERY = gql`
query getUsers($after: String, $courseId: ID!, $first: Int!, $userIds: [ID!]) {
  course(id: $courseId) {
    usersConnection(
      after: $after
      filter: {
        userIds: $userIds,
        enrollmentStates: [active, completed, inactive, invited],
        enrollmentTypes:[StudentEnrollment, StudentViewEnrollment]
      }
      first: $first
    ) {
      pageInfo {
        endCursor
        hasNextPage
      }
      nodes {
        _id
        avatarUrl
        createdAt
        email
        firstName
        integrationId
        lastName
        loginId
        name
        shortName
        sisId
        sortableName
        groupMemberships(
          filter: {
            groupCourseId: [$courseId]
            state:[accepted, invited, rejected, requested]
            groupState: [available]
          }) {
          group{
            _id
            nonCollaborative
          }
        }
      }
    }
  }
}`
