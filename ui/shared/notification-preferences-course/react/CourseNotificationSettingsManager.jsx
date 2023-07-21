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

import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {bool, string} from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import {useMutation} from 'react-apollo'
import NotificationPreferences from '@canvas/notification-preferences'
import {NotificationPreferencesShape} from '@canvas/notification-preferences/react/Shape'
import React, {useContext} from 'react'
import {UPDATE_COURSE_NOTIFICATION_PREFERENCES} from '../graphql/Mutations'

const I18n = useI18nScope('courses')

export default function CourseNotificationSettingsManager(props) {
  const {setOnSuccess, setOnFailure} = useContext(AlertManagerContext)
  const [updatePreference] = useMutation(UPDATE_COURSE_NOTIFICATION_PREFERENCES, {
    onCompleted(data) {
      handleUpdateComplete(data)
    },
    onError() {
      setOnFailure(I18n.t('Failed to update course notification settings'))
    },
  })

  const handleUpdateComplete = data => {
    if (data.updateNotificationPreferences.errors) {
      setOnFailure(I18n.t('Failed to update course notification settings'))
    } else {
      setOnSuccess(I18n.t('Course notification settings updated'))
    }
  }

  return (
    <NotificationPreferences
      contextType="course"
      contextName={props.courseName}
      enabled={props.enabled}
      updatePreference={(data = {}) =>
        updatePreference({
          variables: {
            courseId: props.courseId,
            enabled: data.enabled,
            channelId: data.channel?._id,
            category: data.category?.split(' ').join('_'),
            frequency: data.frequency,
            sendScoresInEmails: data.sendScoresInEmails,
          },
        })
      }
      notificationPreferences={props.notificationPreferences}
      userId={props.userId}
    />
  )
}

CourseNotificationSettingsManager.propTypes = {
  courseId: string.isRequired,
  courseName: string.isRequired,
  enabled: bool.isRequired,
  notificationPreferences: NotificationPreferencesShape,
  userId: string.isRequired,
}
