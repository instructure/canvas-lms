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

import {bool, func, string} from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import {NotificationPreferencesShape} from './Shape'
import NotificationPreferencesTable from './Table'
import React, {useContext, useEffect, useState} from 'react'

import {Alert} from '@instructure/ui-alerts'
import {Checkbox} from '@instructure/ui-checkbox'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {NotificationPreferencesContext} from './NotificationPreferencesContextProvider'
import NotificationPreferencesContextSelectQuery from './NotificationPreferencesContextSelectQuery'

const I18n = useI18nScope('notification_preferences')

const NotificationPreferences = props => {
  const {enabled} = props
  // props.updatePreference takes some time to reflect the change
  // let's use the component state to reflect the change faster
  const [stagedEnabled, setStagedEnabled] = useState(enabled)
  const [sendObservedNamesEnabled, setSendObservedNames] = useState(
    props.notificationPreferences?.sendObservedNamesInNotifications
  )
  const contextSelectable = useContext(NotificationPreferencesContext) !== null

  useEffect(() => {
    setStagedEnabled(enabled)
  }, [enabled])

  const renderMuteToggle = () => {
    if (props.contextType === 'course') {
      return (
        <>
          <Flex.Item margin="small 0 small 0" padding="xx-small">
            <Checkbox
              data-testid="enable-notifications-toggle"
              label={I18n.t('Enable Notifications for %{contextName}', {
                contextName: props.contextName,
              })}
              size="small"
              variant="toggle"
              checked={stagedEnabled}
              onChange={() => {
                setStagedEnabled(!stagedEnabled)
                props.updatePreference({enabled: !stagedEnabled})
              }}
            />
          </Flex.Item>
          <Flex.Item>
            <Text>
              {stagedEnabled
                ? I18n.t(
                    'You are currently receiving notifications for this course. To disable course notifications, use the toggle above.'
                  )
                : I18n.t(
                    'You will not receive any course notifications at this time. To enable course notifications, use the toggle above.'
                  )}
            </Text>
          </Flex.Item>
        </>
      )
    }
  }

  const renderNotificationPreferences = () => (
    <Flex.Item>
      <NotificationPreferencesTable
        preferences={props.notificationPreferences}
        updatePreference={props.updatePreference}
      />
    </Flex.Item>
  )

  const renderNotificationInfoAlert = () => (
    <Flex.Item>
      <Alert transition="none" variant="info" renderCloseButtonLabel={I18n.t('Close')}>
        {props.contextType === 'course'
          ? I18n.t(
              'Course-level notifications are inherited from your account-level notification settings. Adjusting notifications for this course will override notifications at the account level.'
            )
          : I18n.t(
              'Account-level notifications apply to all courses. Notifications for individual courses can be changed within each course and will override these notifications.'
            )}
      </Alert>
    </Flex.Item>
  )

  const renderNotificationTimesInfoAlert = () => {
    const globalTimeText = I18n.t(
      'Daily notifications will be delivered around %{day_time}. Weekly notifications will be delivered %{weekday} between %{start_time} and %{end_time}.',
      {
        day_time: ENV.NOTIFICATION_PREFERENCES_OPTIONS?.daily_notification_time,
        weekday: ENV.NOTIFICATION_PREFERENCES_OPTIONS?.weekly_notification_range?.weekday,
        start_time: ENV.NOTIFICATION_PREFERENCES_OPTIONS?.weekly_notification_range?.start_time,
        end_time: ENV.NOTIFICATION_PREFERENCES_OPTIONS?.weekly_notification_range?.end_time,
      }
    )
    return (
      ENV.NOTIFICATION_PREFERENCES_OPTIONS?.daily_notification_time &&
      ENV.NOTIFICATION_PREFERENCES_OPTIONS?.weekly_notification_range?.weekday &&
      ENV.NOTIFICATION_PREFERENCES_OPTIONS?.weekly_notification_range?.start_time &&
      ENV.NOTIFICATION_PREFERENCES_OPTIONS?.weekly_notification_range?.end_time && (
        <Flex.Item data-testid="notification_times">
          <Alert transition="none" variant="info" renderCloseButtonLabel={I18n.t('Close')}>
            {globalTimeText}
          </Alert>
        </Flex.Item>
      )
    )
  }

  const renderAccountPrivacyInfoAlert = () =>
    props.contextType === 'account' &&
    ENV?.NOTIFICATION_PREFERENCES_OPTIONS?.account_privacy_notice &&
    !ENV?.NOTIFICATION_PREFERENCES_OPTIONS?.read_privacy_info && (
      <Flex.Item>
        <Alert
          variant="info"
          renderCloseButtonLabel={I18n.t('Close')}
          onDismiss={() => props.updatePreference({hasReadPrivacyNotice: true})}
        >
          {I18n.t(
            'Notice: Some notifications may contain confidential information. Selecting to receive notifications at an email other than your institution provided address may result in sending sensitive Canvas course and group information outside of the institutional system.'
          )}
        </Alert>
      </Flex.Item>
    )

  const renderSendObservedNamesInNotificationsToggle = () => {
    if (
      props.contextType === 'account' &&
      props.notificationPreferences.sendObservedNamesInNotifications !== null
    ) {
      return (
        <Flex.Item margin="small 0 small 0" padding="xx-small">
          <Checkbox
            data-testid="send-observed-names-toggle"
            label={I18n.t('Show name of observed students in notifications')}
            size="small"
            variant="toggle"
            checked={sendObservedNamesEnabled}
            onChange={() => {
              setSendObservedNames(!sendObservedNamesEnabled)
              props.updatePreference({sendObservedNamesInNotifications: !sendObservedNamesEnabled})
            }}
          />
        </Flex.Item>
      )
    }
  }

  const renderContextSelect = () => {
    return (
      <NotificationPreferencesContext.Consumer>
        {context =>
          context ? (
            <NotificationPreferencesContextSelectQuery
              currentContext={context.currentContext}
              onContextChanged={context.setContext}
              userId={props.userId}
            />
          ) : null
        }
      </NotificationPreferencesContext.Consumer>
    )
  }

  return (
    <Flex direction="column">
      <Flex.Item overflowY="visible" margin="0 0 small 0">
        <Heading level="h2" as="h1">
          {contextSelectable
            ? I18n.t('Notification Settings')
            : props.contextType === 'course'
            ? I18n.t('Course Notification Settings')
            : I18n.t('Account Notification Settings')}
        </Heading>
      </Flex.Item>
      {renderNotificationInfoAlert()}
      {renderNotificationTimesInfoAlert()}
      {renderAccountPrivacyInfoAlert()}
      {contextSelectable && renderContextSelect()}
      {renderMuteToggle()}
      {renderSendObservedNamesInNotificationsToggle()}
      {renderNotificationPreferences()}
    </Flex>
  )
}

NotificationPreferences.propTypes = {
  contextType: string.isRequired,
  contextName: string,
  enabled: bool,
  updatePreference: func.isRequired,
  userId: string.isRequired,
  notificationPreferences: NotificationPreferencesShape,
}

export default NotificationPreferences
