/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import gql from 'graphql-tag'

export const ROSTER_QUERY = gql`
  query getRosterQuery($courseID: ID!) {
    course(id: $courseID) {
      usersConnection(
        filter: {
          enrollmentTypes: [
            StudentEnrollment
            TeacherEnrollment
            TaEnrollment
            DesignerEnrollment
            ObserverEnrollment
          ]
        }
      ) {
        nodes {
          name
          _id
          id
          sisId
          avatarUrl
          pronouns
          loginId
          enrollments(courseId: $courseID, excludeConcluded: true) {
            id
            type
            state
            lastActivityAt
            htmlUrl
            totalActivityTime
            canBeRemoved
            sisRole
            associatedUser {
              _id
              id
              name
            }
            section {
              _id
              id
              name
            }
          }
        }
      }
    }
  }
`
