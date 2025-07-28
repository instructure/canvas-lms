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
import {gql} from '@apollo/client'

const MAX_ENROLLMENTS_PER_PAGE = 100

type PageInfo = {
  hasNextPage: boolean
  endCursor: string | null
}

export type ObserverEnrollmentQueryResult = {
  course: {
    enrollmentsConnection: {
      nodes: ObserverEnrollmentConnectionNode[]
      pageInfo: PageInfo
    }
  }
}

export type ObserverEnrollmentConnectionNode = {
  _id: string
  type: string
  user: ObserverEnrollmentConnectionUser
  associatedUser: {
    _id: string
  }
}

export type ObserverEnrollmentConnectionUser = {
  _id: string
  name: string
  sortableName: string
}

export type ObserverEnrollmentQueryVariables = {
  courseId: string
  studentIds: string[]
}

export const OBSERVER_ENROLLMENTS_QUERY = gql`
  query ObserversForStudents($courseId: ID!, $studentIds: [ID!], $cursor: String) {
    course(id: $courseId) {
      enrollmentsConnection(first: ${MAX_ENROLLMENTS_PER_PAGE}, after: $cursor, filter: {associatedUserIds: $studentIds, types: ObserverEnrollment}) {
        nodes {
          _id
          type
          user {
            _id
            name
            sortableName
          }
          associatedUser {
            _id
          }
        }
        pageInfo {
          hasNextPage
          endCursor
        }
      }
    }
  }
`
