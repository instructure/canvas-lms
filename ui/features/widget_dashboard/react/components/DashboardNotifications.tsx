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

import React, {useState} from 'react'
import {useQuery, useMutation, gql} from '@apollo/client'
import {View} from '@instructure/ui-view'
import {Spinner} from '@instructure/ui-spinner'
import {useScope as createI18nScope} from '@canvas/i18n'
import {ApolloProvider, createClient} from '@canvas/apollo-v3'
import NotificationAlert, {AccountNotificationData} from './NotificationAlert'

const I18n = createI18nScope('dashboard_notifications')

const ACCOUNT_NOTIFICATIONS_QUERY = gql`
  query GetAccountNotifications {
    accountNotifications {
      id
      _id
      subject
      message
      startAt
      endAt
      accountName
      siteAdmin
      notificationType
    }
  }
`

const DISMISS_NOTIFICATION_MUTATION = gql`
  mutation DismissAccountNotification($notificationId: ID!) {
    dismissAccountNotification(input: {notificationId: $notificationId}) {
      errors { message }
    }
  }
`

const DashboardNotifications: React.FC = () => {
  const [dismissedIds, setDismissedIds] = useState<Set<string>>(new Set())
  const {loading, error, data} = useQuery(ACCOUNT_NOTIFICATIONS_QUERY)
  const [dismissNotification] = useMutation(DISMISS_NOTIFICATION_MUTATION)

  const handleDismiss = async (id: string) => {
    try {
      const result = await dismissNotification({
        variables: {notificationId: id},
      })
      if (result.data?.dismissAccountNotification?.success) {
        setDismissedIds(prev => new Set([...prev, id]))
      }
    } catch (err) {
      console.error('Failed to dismiss notification:', err)
    }
  }

  if (loading) {
    return (
      <View as="div" margin="small">
        <Spinner renderTitle={I18n.t('Loading notifications')} size="x-small" />
      </View>
    )
  }

  if (error || !data?.accountNotifications) {
    return null
  }

  const visibleNotifications = data.accountNotifications.filter(
    (notification: AccountNotificationData) => !dismissedIds.has(notification.id),
  )

  if (visibleNotifications.length === 0) {
    return null
  }

  return (
    <View as="div" margin="0 0 medium 0">
      {visibleNotifications.map((notification: AccountNotificationData) => (
        <NotificationAlert
          key={notification.id}
          notification={notification}
          onDismiss={handleDismiss}
        />
      ))}
    </View>
  )
}

export {DashboardNotifications}

const DashboardNotificationsWithApollo: React.FC = () => {
  const apolloClient = createClient()

  return (
    <ApolloProvider client={apolloClient}>
      <DashboardNotifications />
    </ApolloProvider>
  )
}

export default DashboardNotificationsWithApollo
