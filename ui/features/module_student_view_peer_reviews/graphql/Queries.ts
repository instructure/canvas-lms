/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {gql} from '@canvas/apollo'

const ASSIGNMENT_QUERY = gql`
  query GetCourseModules($courseId: ID!) {
    course(id: $courseId) {
      modulesConnection {
        nodes {
          moduleItems {
            _id
            content {
              ... on Assignment {
                name
                _id
                peerReviews {
                  anonymousReviews
                }
                assessmentRequestsForCurrentUser {
                  _id
                  anonymousId
                  available
                  createdAt
                  workflowState
                  user {
                    _id
                    name
                  }
                  anonymizedUser {
                    _id
                    name
                  }
                }
              }
            }
          }
        }
      }
    }
  }
`
export default ASSIGNMENT_QUERY
