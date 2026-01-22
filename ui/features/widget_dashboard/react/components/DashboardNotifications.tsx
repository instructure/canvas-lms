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
import {useQuery, useMutation} from '@tanstack/react-query'
import {gql} from 'graphql-tag'
import {View} from '@instructure/ui-view'
import {Spinner} from '@instructure/ui-spinner'
import {useScope as createI18nScope} from '@canvas/i18n'
import {executeQuery} from '@canvas/graphql'
import NotificationAlert, {AccountNotificationData} from './NotificationAlert'
import EnrollmentInvitation, {EnrollmentInvitationData} from './EnrollmentInvitation'
import {DASHBOARD_NOTIFICATIONS_KEY} from '../constants'
import {widgetDashboardPersister} from '../utils/persister'
import {useBroadcastQuery} from '@canvas/query/broadcast'

interface DashboardNotificationsResponse {
  accountNotifications?: AccountNotificationData[]
  enrollmentInvitations?: EnrollmentInvitationData[]
}

interface DismissNotificationResponse {
  dismissAccountNotification?: {
    success?: boolean
    errors?: Array<{message: string}>
  }
}

const I18n = createI18nScope('dashboard_notifications')

const DASHBOARD_NOTIFICATIONS_QUERY = gql`
  query GetDashboardNotifications {
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
    enrollmentInvitations {
      id
      uuid
      course {
        id
        name
      }
      role {
        name
      }
      roleLabel
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
  const [dismissedNotificationIds, setDismissedNotificationIds] = useState<Set<string>>(new Set())
  const [dismissedInvitationIds, setDismissedInvitationIds] = useState<Set<string>>(new Set())

  const {
    data,
    isLoading: loading,
    error,
  } = useQuery<DashboardNotificationsResponse>({
    queryKey: [DASHBOARD_NOTIFICATIONS_KEY],
    queryFn: () => executeQuery(DASHBOARD_NOTIFICATIONS_QUERY, {}),
    staleTime: 5 * 60 * 1000,
    refetchOnWindowFocus: false,
    persister: widgetDashboardPersister,
    refetchOnMount: false,
  })

  // Broadcast notification updates across tabs
  useBroadcastQuery({
    queryKey: [DASHBOARD_NOTIFICATIONS_KEY],
    broadcastChannel: 'widget-dashboard',
  })

  const dismissMutation = useMutation<DismissNotificationResponse, Error, string>({
    mutationFn: async (notificationId: string) => {
      return executeQuery<DismissNotificationResponse>(DISMISS_NOTIFICATION_MUTATION, {
        notificationId,
      })
    },
  })

  const handleDismissNotification = async (id: string) => {
    try {
      const result = await dismissMutation.mutateAsync(id)
      if (!result?.dismissAccountNotification?.errors) {
        setDismissedNotificationIds(prev => new Set([...prev, id]))
      }
    } catch {
      // Silently fail - notification remains visible
    }
  }

  const handleAcceptInvitation = (invitationId: string) => {
    setDismissedInvitationIds(prev => new Set([...prev, invitationId]))
  }

  const handleRejectInvitation = (invitationId: string) => {
    setDismissedInvitationIds(prev => new Set([...prev, invitationId]))
  }

  if (loading) {
    return (
      <View as="div" margin="small">
        <Spinner renderTitle={I18n.t('Loading notifications')} size="x-small" />
      </View>
    )
  }

  if (error || (!data?.accountNotifications && !data?.enrollmentInvitations)) {
    return null
  }

  const visibleNotifications = (data?.accountNotifications || []).filter(
    (notification: AccountNotificationData) => !dismissedNotificationIds.has(notification.id),
  )

  const visibleInvitations = (data?.enrollmentInvitations || []).filter(
    (invitation: EnrollmentInvitationData) => !dismissedInvitationIds.has(invitation.id),
  )

  if (visibleNotifications.length === 0 && visibleInvitations.length === 0) {
    return null
  }

  return (
    <View as="div" margin="0 0 medium 0">
      {visibleInvitations.map((invitation: EnrollmentInvitationData) => (
        <EnrollmentInvitation
          key={invitation.id}
          invitation={invitation}
          onAccept={handleAcceptInvitation}
          onReject={handleRejectInvitation}
        />
      ))}
      {visibleNotifications.map((notification: AccountNotificationData) => (
        <NotificationAlert
          key={notification.id}
          notification={notification}
          onDismiss={handleDismissNotification}
        />
      ))}
    </View>
  )
}

export default DashboardNotifications
