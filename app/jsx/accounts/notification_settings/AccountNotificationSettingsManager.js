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

import {AlertManagerContext} from 'jsx/shared/components/AlertManager'
import I18n from 'i18n!courses'
import {useMutation} from 'react-apollo'
import NotificationPreferences from 'jsx/notification_preferences/NotificationPreferences'
import NotificationPreferencesShape from 'jsx/notification_preferences/NotificationPreferencesShape'
import React, {useContext} from 'react'
import {string} from 'prop-types'
import {UPDATE_ACCOUNT_NOTIFICATION_PREFERENCES} from './graphqlData/Mutations'

export default function AccountNotificationSettingsManager(props) {
  const {setOnSuccess, setOnFailure} = useContext(AlertManagerContext)
  const [updatePreference] = useMutation(UPDATE_ACCOUNT_NOTIFICATION_PREFERENCES, {
    onCompleted(data) {
      handleUpdateComplete(data)
    },
    onError() {
      setOnFailure(I18n.t('Failed to update account notification settings'))
    }
  })

  const handleUpdateComplete = data => {
    if (data.updateNotificationPreferences.errors) {
      setOnFailure(I18n.t('Failed to update account notification settings'))
    } else {
      setOnSuccess(I18n.t('Account notification settings updated'))
    }
  }

  return (
    <NotificationPreferences
      contextType="account"
      updatePreference={(data = {}) =>
        updatePreference({
          variables: {
            accountId: props.accountId,
            userId: props.userId,
            channelId: data.channel?._id,
            category: data.category?.split(' ').join('_'),
            frequency: data.frequency,
            sendScoresInEmails: data.sendScoresInEmails
          }
        })
      }
      notificationPreferences={props.notificationPreferences}
    />
  )
}

AccountNotificationSettingsManager.propTypes = {
  accountId: string.isRequired,
  userId: string.isRequired,
  notificationPreferences: NotificationPreferencesShape
}
