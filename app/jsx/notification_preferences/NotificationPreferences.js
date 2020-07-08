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
import I18n from 'i18n!notification_preferences'
import NotificationPreferencesShape from './NotificationPreferencesShape'
import NotificationPreferencesTable from './NotificationPreferencesTable'
import PleaseWaitWristWatch from './SVG/PleaseWaitWristWatch.svg'
import React, {useState} from 'react'

import {Alert} from '@instructure/ui-alerts'
import {Checkbox} from '@instructure/ui-checkbox'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

const NotificationPreferences = props => {
  const [enabled, setEnabled] = useState(props.enabled)
  const capitalizedContextType = props.contextType[0].toUpperCase() + props.contextType.slice(1)

  const renderMuteToggle = () => {
    if (props.contextType === 'course') {
      return (
        <>
          <Flex.Item margin="small 0 small 0" padding="xx-small">
            <Checkbox
              data-testid="enable-notifications-toggle"
              label={I18n.t('Enable Notifications for %{contextName}', {
                contextName: props.contextName
              })}
              size="small"
              variant="toggle"
              checked={enabled}
              onChange={() => {
                setEnabled(!enabled)
                props.updatePreference({enabled: !enabled})
              }}
            />
          </Flex.Item>
          <Flex.Item>
            <Text>
              {enabled
                ? I18n.t(
                    'You are currently receiving notifications for this %{contextType}. To disable %{contextType} notifications, use the toggle above.',
                    {contextType: props.contextType}
                  )
                : I18n.t(
                    'You will not receive any %{contextType} notifications at this time. To enable %{contextType} notifications, use the toggle above.',
                    {contextType: props.contextType}
                  )}
            </Text>
          </Flex.Item>
        </>
      )
    }
  }

  const renderNotificationPreferences = () => {
    if (
      props.contextType === 'account' ||
      ENV.NOTIFICATION_PREFERENCES_OPTIONS?.granular_course_preferences_enabled
    ) {
      return (
        <Flex.Item>
          <NotificationPreferencesTable
            preferences={props.notificationPreferences}
            updatePreference={props.updatePreference}
          />
        </Flex.Item>
      )
    } else {
      return (
        <Flex.Item>
          <View as="div" margin="large 0 medium 0" textAlign="center">
            <Text size="large">
              {I18n.t(
                'Granular %{contextType} notification settings will be configurable here in the future.',
                {contextType: props.contextType}
              )}
            </Text>
          </View>
          <div style={{textAlign: 'center'}}>
            <img alt="" src={PleaseWaitWristWatch} style={{width: '200px'}} />
          </div>
        </Flex.Item>
      )
    }
  }

  const renderNotificationInfoAlert = () => (
    <Flex.Item>
      <Alert variant="info" renderCloseButtonLabel="Close">
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

  return (
    <Flex direction="column">
      <Flex.Item overflowY="visible" margin="0 0 small 0">
        <Heading level="h2" as="h1">
          {I18n.t('%{contextType} Notification Settings', {
            contextType: capitalizedContextType
          })}
        </Heading>
      </Flex.Item>
      {renderNotificationInfoAlert()}
      {renderMuteToggle()}
      {renderNotificationPreferences()}
    </Flex>
  )
}

NotificationPreferences.propTypes = {
  contextType: string.isRequired,
  contextName: string,
  enabled: bool,
  updatePreference: func.isRequired,
  notificationPreferences: NotificationPreferencesShape
}

export default NotificationPreferences
