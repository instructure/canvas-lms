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
import PleaseWaitWristWatch from './SVG/PleaseWaitWristWatch.svg'
import React from 'react'

import {Checkbox} from '@instructure/ui-checkbox'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'

const NotificationPreferences = props => {
  const capitalizedContextType = props.contextType[0].toUpperCase() + props.contextType.slice(1)
  return (
    <Flex direction="column">
      <Flex.Item overflowY="visible">
        <Heading>
          {I18n.t('%{contextType} Notification Settings', {
            contextType: capitalizedContextType
          })}
        </Heading>
      </Flex.Item>
      <Flex.Item margin="large 0 small 0" padding="xx-small">
        <Checkbox
          data-testid="enable-notifications-toggle"
          label={I18n.t('Enable Notifications')}
          size="small"
          variant="toggle"
          checked={props.enabled}
          onChange={() => props.enableNotifications(!props.enabled)}
        />
      </Flex.Item>
      <Flex.Item>
        <Text>
          {props.enabled
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
      <Flex.Item margin="large 0 medium 0">
        <div style={{textAlign: 'center'}}>
          <Text size="large">
            {I18n.t(
              'Granular %{contextType} notification settings will be configurable here in the future.',
              {contextType: props.contextType}
            )}
          </Text>
        </div>
      </Flex.Item>
      <Flex.Item>
        <div style={{textAlign: 'center'}}>
          <img alt="" src={PleaseWaitWristWatch} style={{width: '200px'}} />
        </div>
      </Flex.Item>
    </Flex>
  )
}

NotificationPreferences.propTypes = {
  contextType: string.isRequired,
  enabled: bool.isRequired,
  enableNotifications: func.isRequired
}

export default NotificationPreferences
