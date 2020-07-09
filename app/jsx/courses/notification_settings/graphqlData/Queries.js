/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

export const COURSE_NOTIFICATIONS_QUERY = gql`
  query GetNotificationPreferences($courseId: ID!, $userId: ID!) {
    legacyNode(_id: $userId, type: User) {
      ... on User {
        _id
        notificationPreferencesEnabled(contextType: Course, courseId: $courseId)
        notificationPreferences {
          sendScoresInEmails(userId: $userId)
          channels {
            _id
            path
            pathType
            notificationPolicies(contextType: Course) {
              communicationChannelId
              frequency
              notification {
                _id
                category
                categoryDescription
                categoryDisplayName
                name
              }
            }
            notificationPolicyOverrides(contextType: Course, courseId: $courseId) {
              communicationChannelId
              frequency
              notification {
                _id
                category
                categoryDescription
                categoryDisplayName
                name
              }
            }
          }
        }
      }
    }
  }
`
