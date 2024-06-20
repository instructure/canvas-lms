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

import gql from 'graphql-tag'
import {CourseDashboardCard} from './CourseDashboardCard'
import {ActivityStreamSummary} from './ActivityStream'

const dashcard_query_enabled = !!ENV?.FEATURES?.dashboard_graphql_integration

export const LOAD_DASHBOARD_CARDS_QUERY = gql`
  query GetDashboardCards($userID: ID!, $observedUserId: ID = null) {
    legacyNode(_id: $userID, type: User) {
      ... on User {
        favoriteCoursesConnection {
          nodes {
            _id
            dashboardCard(dashboardFilter: {observedUserId: $observedUserId}) {
              ...CourseDashboardCard @include(if: ${dashcard_query_enabled})
            }
          }
        }
      }
    }
  }
  ${CourseDashboardCard.fragment}
`

export const DASHBOARD_ACTIVITY_STREAM_SUMMARY_QUERY = gql`
  query GetDashboardActivityStreamSummary($userID: ID!) {
    legacyNode(_id: $userID, type: User) {
      ... on User {
        favoriteCoursesConnection {
          nodes {
            _id
            activityStream {
              ...ActivityStreamSummary @include(if: ${dashcard_query_enabled})
            }
          }
        }
      }
    }
  }
  ${ActivityStreamSummary.fragment}
`
