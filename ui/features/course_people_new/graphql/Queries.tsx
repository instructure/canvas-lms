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

export const COURSE_PEOPLE_QUERY = gql`
  query getCoursePeopleQuery($courseId: ID!) {
    course(id: $courseId) {
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
          sisId
          avatarUrl
          pronouns
          loginId
          enrollments(courseId: $courseId, excludeConcluded: true) {
            _id
            type
            state
            lastActivityAt
            totalActivityTime
            canBeRemoved
            sisRole
            htmlUrl
            associatedUser {
              _id
              name
            }
            section {
              _id
              name
            }
          }
        }
      }
    }
  }
`
