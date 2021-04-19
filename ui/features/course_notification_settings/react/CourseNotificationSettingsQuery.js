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

import {COURSE_NOTIFICATIONS_QUERY} from '../graphql/Queries'
import CourseNotificationSettingsManager from './CourseNotificationSettingsManager'
import errorShipUrl from '@canvas/images/ErrorShip.svg'
import GenericErrorPage from '@canvas/generic-error-page'
import I18n from 'i18n!courses'
import LoadingIndicator from '@canvas/loading-indicator'
import React from 'react'
import {string} from 'prop-types'
import {useQuery} from 'react-apollo'

export default function CourseNotificationSettingsQuery(props) {
  const {loading, error, data} = useQuery(COURSE_NOTIFICATIONS_QUERY, {
    variables: {
      courseId: props.courseId,
      userId: props.userId
    }
  })

  if (loading) return <LoadingIndicator />
  if (error)
    return (
      <GenericErrorPage
        imageUrl={errorShipUrl}
        errorSubject={I18n.t('Course Notification Settings initial query error')}
        errorCategory={I18n.t('Course Notification Settings Error Page')}
      />
    )

  return (
    <CourseNotificationSettingsManager
      courseId={props.courseId}
      courseName={props.courseName}
      enabled={data?.legacyNode?.notificationPreferencesEnabled}
      notificationPreferences={data?.legacyNode?.notificationPreferences}
    />
  )
}

CourseNotificationSettingsQuery.propTypes = {
  courseId: string.isRequired,
  courseName: string.isRequired,
  userId: string.isRequired
}
