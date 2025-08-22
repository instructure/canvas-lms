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

import React from 'react'
import {Alert} from '@instructure/ui-alerts'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {
  IconInfoLine,
  IconWarningLine,
  IconQuestionLine,
  IconCalendarMonthLine,
} from '@instructure/ui-icons'
import {useScope as createI18nScope} from '@canvas/i18n'
import sanitizeHtml from 'sanitize-html-with-tinymce'

const I18n = createI18nScope('account_notifications')

export interface AccountNotificationData {
  id: string
  subject: string
  message: string
  startAt: string
  endAt: string
  accountName?: string
  siteAdmin: boolean
  notificationType?: string
}

interface NotificationAlertProps {
  notification: AccountNotificationData
  onDismiss: (id: string) => void
}

const getNotificationIcon = (type?: string) => {
  switch (type) {
    case 'error':
    case 'warning':
      return () => <IconWarningLine />
    case 'question':
      return () => <IconQuestionLine />
    case 'calendar':
      return () => <IconCalendarMonthLine />
    case 'info':
    default:
      return () => <IconInfoLine />
  }
}

const getNotificationVariant = (type?: string): 'info' | 'success' | 'warning' | 'error' => {
  switch (type) {
    case 'warning':
      return 'warning'
    case 'error':
      return 'error'
    case 'info':
    case 'question':
    case 'calendar':
    default:
      return 'info'
  }
}

const NotificationAlert: React.FC<NotificationAlertProps> = ({notification, onDismiss}) => {
  const handleDismiss = () => {
    onDismiss(notification.id)
  }

  const accountMessage = notification.siteAdmin ? (
    <Text size="small">
      {I18n.t('This is a message from ')}
      <Text weight="bold" size="small">
        {I18n.t('Canvas Administration')}
      </Text>
    </Text>
  ) : (
    <Text size="small">
      {I18n.t('This is a message from ')}
      <Text weight="bold" size="small">
        {notification.accountName}
      </Text>
    </Text>
  )

  return (
    <Alert
      variant={getNotificationVariant(notification.notificationType)}
      renderCloseButtonLabel={I18n.t('Close')}
      renderCustomIcon={getNotificationIcon(notification.notificationType)}
      onDismiss={handleDismiss}
      margin="0 0 medium 0"
      transition="none"
    >
      <View as="div">
        <Text weight="bold" size="medium" as="div">
          {notification.subject}
        </Text>
        <View
          as="div"
          margin="x-small 0 0 0"
          dangerouslySetInnerHTML={{__html: sanitizeHtml(notification.message)}}
        />
        <View as="div" margin="small 0 0 0">
          {accountMessage}
        </View>
      </View>
    </Alert>
  )
}

export default NotificationAlert
