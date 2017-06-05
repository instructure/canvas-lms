/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import PropTypes from 'prop-types'
import I18n from 'i18n!blueprint_settings'
import { connect } from 'react-redux'
import { bindActionCreators } from 'redux'
import select from 'jsx/shared/select'
import $ from 'jquery'

import Checkbox from 'instructure-ui/lib/components/Checkbox'
import TextArea from 'instructure-ui/lib/components/TextArea'
import Typography from 'instructure-ui/lib/components/Typography'
import ScreenReaderContent from 'instructure-ui/lib/components/ScreenReaderContent'

import actions from '../actions'
import propTypes from '../propTypes'
import MigrationStates from '../migrationStates'

const MAX_NOTIFICATION_MESSAGE_LENGTH = 140

export default class MigrationOptions extends React.Component {
  static propTypes = {
    migrationStatus: propTypes.migrationState.isRequired,
    willSendNotification: PropTypes.bool.isRequired,
    willIncludeCustomNotificationMessage: PropTypes.bool.isRequired,
    willIncludeCourseSettings: PropTypes.bool.isRequired,
    notificationMessage: PropTypes.string.isRequired,
    enableSendNotification: PropTypes.func.isRequired,
    includeCustomNotificationMessage: PropTypes.func.isRequired,
    includeCourseSettings: PropTypes.func.isRequired,
    setNotificationMessage: PropTypes.func.isRequired,
  }

  handleSendNotificationChange = (event) => {
    this.props.enableSendNotification(event.target.checked)
  }

  handleIncludeCourseSettingsChange = (event) => {
    this.props.includeCourseSettings(event.target.checked)
  }

  handleAddAMessageChange = (event) => {
    this.props.includeCustomNotificationMessage(event.target.checked)
  }

  handleChangeMessage = (event) => {
    const msg = event.target.value.slice(0, MAX_NOTIFICATION_MESSAGE_LENGTH);
    if (msg.length === MAX_NOTIFICATION_MESSAGE_LENGTH) {
      $.screenReaderFlashMessage(
        I18n.t('You have reached the limit of %{len} characters in the notification message', {len: MAX_NOTIFICATION_MESSAGE_LENGTH})
      )
    }
    this.props.setNotificationMessage(msg)
  }

  render () {
    const isDisabled = MigrationStates.isLoadingState(this.props.migrationStatus)
    return (
      <div className="bcs__history-notification">
        <div className="bcs__history-settings">
          <Checkbox
            label={I18n.t('Include Course Settings')}
            checked={this.props.willIncludeCourseSettings}
            onChange={this.handleIncludeCourseSettingsChange}
            size="small"
            disabled={isDisabled}
          />
          <Checkbox
            label={I18n.t('Send Notification')}
            checked={this.props.willSendNotification}
            onChange={this.handleSendNotificationChange}
            size="small"
            disabled={isDisabled}
          />
        </div>
        {this.props.willSendNotification ?
          <div className="bcs__history-notification__add-message">
            <Checkbox
              label={I18n.t('Add a Message')}
              checked={this.props.willIncludeCustomNotificationMessage}
              onChange={this.handleAddAMessageChange}
              inline
              size="small"
              disabled={isDisabled}
            />
            <Typography as="span" color="secondary" size="small">({this.props.notificationMessage.length}/140)</Typography>
          </div> : null
        }
        {this.props.willSendNotification && this.props.willIncludeCustomNotificationMessage ?
          <div className="bcs__history-notification__message">
            <TextArea
              label={<ScreenReaderContent>{I18n.t('Message text')}</ScreenReaderContent>}
              autoGrow={false}
              resize="vertical"
              inline
              value={this.props.notificationMessage}
              onChange={this.handleChangeMessage}
              disabled={isDisabled}
            />
          </div> : null
        }
      </div>
    )
  }
}

const connectState = state =>
  select(state, [
    'migrationStatus',
    'willSendNotification',
    'willIncludeCustomNotificationMessage',
    'notificationMessage',
    'willIncludeCourseSettings'
  ])
const connectActions = dispatch => bindActionCreators(actions, dispatch)
export const ConnectedMigrationOptions = connect(connectState, connectActions)(MigrationOptions)
