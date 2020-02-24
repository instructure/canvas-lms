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

import {AlertManagerContext} from '../../shared/components/AlertManager'
import axios from 'axios'
import errorShipUrl from 'jsx/shared/svg/ErrorShip.svg'
import GenericErrorPage from '../../shared/components/GenericErrorPage'
import I18n from 'i18n!courses'
import LoadingIndicator from '../../shared/LoadingIndicator'
import PleaseWaitWristWatch from './SVG/PleaseWaitWristWatch.svg'
import React, {Component} from 'react'

import {Checkbox} from '@instructure/ui-checkbox'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'

export default class CourseNotificationSettings extends Component {
  state = {
    errored: false,
    loading: true,
    enabled: true
  }

  componentDidMount() {
    this.getNotificationsEnabled()
  }

  getNotificationsEnabled = async () => {
    const resp = await axios.get(
      `/api/v1/users/self/courses/${ENV.COURSE.id}/notifications_enabled`
    )
    this.setState({
      errored: resp?.status !== 200,
      loading: false,
      enabled: resp?.data?.enabled
    })
  }

  updateNotificationsEnabled = async () => {
    // optimistically toggle button while waiting for response
    this.setState(prevState => ({enabled: !prevState.enabled}))

    try {
      const resp = await axios.put(
        `/api/v1/users/self/courses/${ENV.COURSE.id}/enable_notifications`,
        {enable: !this.state.enabled}
      )
      if (resp?.status !== 200) {
        this.handleError()
        return
      }

      this.setState({
        enabled: resp?.data?.enabled
      })
    } catch (error) {
      this.handleError(error.message)
    }
  }

  handleError = () => {
    this.context.setOnFailure(I18n.t('Failed to update course notification settings'))
    this.setState(prevState => ({enabled: !prevState.enabled}))
  }

  render() {
    if (this.state.loading) {
      return <LoadingIndicator />
    }

    if (this.state.errored) {
      return (
        <GenericErrorPage
          imageUrl={errorShipUrl}
          errorSubject={I18n.t('Course Notification Settings initial query error')}
          errorCategory={I18n.t('Course Notification Settings Error Page')}
        />
      )
    }

    return (
      <Flex direction="column">
        <Flex.Item overflowY="visible">
          <Heading>{I18n.t('Course Notification Settings')}</Heading>
        </Flex.Item>
        <Flex.Item margin="large 0 small 0" padding="xx-small">
          <Checkbox
            data-testid="enable-notifications-toggle"
            label={I18n.t('Enable Notifications')}
            size="small"
            variant="toggle"
            checked={this.state.enabled}
            onChange={this.updateNotificationsEnabled}
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

CourseNotificationSettings.contextType = AlertManagerContext
