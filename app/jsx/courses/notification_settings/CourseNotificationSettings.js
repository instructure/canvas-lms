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

import I18n from 'i18n!courses'
import React, {Component} from 'react'
import PleaseWaitWristWatch from './SVG/PleaseWaitWristWatch.svg'

import {Checkbox} from '@instructure/ui-checkbox'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'

export default class CourseNotificationSettings extends Component {
  state = {
    enabled: true
  }

  handleClick = () => {
    this.setState(prevState => {
      return {enabled: !prevState.enabled}
    })
  }

  render() {
    return (
      <Flex direction="column">
        <Flex.Item>
          <Heading>{I18n.t('Course Notification Settings')}</Heading>
        </Flex.Item>
        <Flex.Item margin="large 0 small 0" padding="xx-small">
          <Checkbox
            data-testid="enable-notifications-toggle"
            label={I18n.t('Enable Notifications')}
            size="small"
            variant="toggle"
            checked={this.state.enabled}
            onChange={this.handleClick}
          />
        </Flex.Item>
        <Flex.Item>
          <Text>
            {this.state.enabled
              ? I18n.t(
                  'You are currently receiving notifications for this course. To disable course notifications, use the toggle above.'
                )
              : I18n.t(
                  'You will not receive any course notifications at this time. To enable course notifications, use the toggle above.'
                )}
          </Text>
        </Flex.Item>
        <Flex.Item margin="large 0 medium 0">
          <div style={{textAlign: 'center'}}>
            <Text size="large">
              {I18n.t(
                'Granular course notification settings will be configurable here in the future.'
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
}
