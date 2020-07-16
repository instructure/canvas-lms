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

export const UPDATE_ACCOUNT_NOTIFICATION_PREFERENCES = gql`
  mutation UpdateAccountNotificationPreferences(
    $channelId: ID
    $category: NotificationCategoryType
    $frequency: NotificationFrequencyType
  ) {
    updateNotificationPreferences(
      input: {
        communicationChannelId: $channelId
        notificationCategory: $category
        frequency: $frequency
      }
    ) {
      user {
        _id
        notificationPreferences {
          channels(channelId: $channelId) {
            _id
            path
            pathType
            notificationPolicies {
              communicationChannelId
              frequency
              notification {
                _id
                category
                categoryDisplayName
                name
              }
            }
          }
        }
      }
      errors {
        message
      }
    }
  }
`
