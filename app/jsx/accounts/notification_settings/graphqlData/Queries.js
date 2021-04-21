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

export const ACCOUNT_NOTIFICATIONS_QUERY = gql`
  query GetAccountNotificationPreferences($accountId: ID!, $userId: ID!) {
    legacyNode(_id: $userId, type: User) {
      ... on User {
        _id
        notificationPreferences {
          sendScoresInEmails
          sendObservedNamesInNotifications
          channels {
            _id
            path
            pathType
            notificationPolicies {
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
            notificationPolicyOverrides(contextType: Account, accountId: $accountId) {
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
