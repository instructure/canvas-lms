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
import {useScope as useI18nScope} from '@canvas/i18n'
import {connect} from 'react-redux'
import {bindActionCreators} from 'redux'
import select from '@canvas/obj-select'
import $ from 'jquery'
import '@canvas/rails-flash-notifications'

import {FormFieldGroup} from '@instructure/ui-form-field'
import {Checkbox} from '@instructure/ui-checkbox'
import {TextArea} from '@instructure/ui-text-area'
import {Text} from '@instructure/ui-text'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

import actions from '@canvas/blueprint-courses/react/actions'
import propTypes from '@canvas/blueprint-courses/react/propTypes'
import MigrationStates from '@canvas/blueprint-courses/react/migrationStates'

const I18n = useI18nScope('blueprint_settingsMigrationOptions')

const MAX_NOTIFICATION_MESSAGE_LENGTH = 140
const WARNING_MESSAGE_LENGTH = 126

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

  UNSAFE_componentWillReceiveProps(newProps) {
    if (
      newProps.notificationMessage !== this.props.notificationMessage &&
      newProps.notificationMessage.length > WARNING_MESSAGE_LENGTH
    ) {
      $.screenReaderFlashMessage(
        I18n.t('%{count} of %{max} maximum characters', {
          count: newProps.notificationMessage.length,
          max: MAX_NOTIFICATION_MESSAGE_LENGTH,
        })
      )
    }
  }

  handleSendNotificationChange = event => {
    this.props.enableSendNotification(event.target.checked)
  }

  handleIncludeCourseSettingsChange = event => {
    this.props.includeCourseSettings(event.target.checked)
  }

  handleAddAMessageChange = event => {
    this.props.includeCustomNotificationMessage(event.target.checked)
  }

  handleChangeMessage = event => {
    if (event.target.value.length > MAX_NOTIFICATION_MESSAGE_LENGTH) {
      setTimeout(() => {
        $.screenReaderFlashMessage(
          I18n.t('You have reached the limit of %{len} characters in the notification message', {
            len: MAX_NOTIFICATION_MESSAGE_LENGTH,
          })
        )
      }, 600)
    }
    const msg = event.target.value.slice(0, MAX_NOTIFICATION_MESSAGE_LENGTH)
    this.props.setNotificationMessage(msg)
  }

  render() {
    const isDisabled = MigrationStates.isLoadingState(this.props.migrationStatus)

    return (
      <FormFieldGroup
        description={<ScreenReaderContent>{I18n.t('History Settings')}</ScreenReaderContent>}
        layout="stacked"
        rowSpacing="small"
      >
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
        {this.props.willSendNotification ? (
          <div className="bcs__history-notification__add-message">
            <Checkbox
              label={
                <div>
                  <Text size="small">{I18n.t('Add a Message ')}</Text>
                  <Text
                    aria-label={I18n.t('%{chars} written, max character length %{len}', {
                      chars: this.props.notificationMessage.length,
                      len: MAX_NOTIFICATION_MESSAGE_LENGTH,
                    })}
                    color="secondary"
                    size="small"
                    role="presentation"
                  >
                    (
                    {I18n.t('%{len}/%{maxLen}', {
                      len: this.props.notificationMessage.length,
                      maxLen: MAX_NOTIFICATION_MESSAGE_LENGTH,
                    })}
                    )
                  </Text>
                </div>
              }
              checked={this.props.willIncludeCustomNotificationMessage}
              onChange={this.handleAddAMessageChange}
              inline={true}
              size="small"
              disabled={isDisabled}
            />
          </div>
        ) : null}
        {this.props.willSendNotification && this.props.willIncludeCustomNotificationMessage ? (
          <div className="bcs__history-notification__message">
            <TextArea
              label={<ScreenReaderContent>{I18n.t('Message text')}</ScreenReaderContent>}
              autoGrow={false}
              resize="vertical"
              inline={true}
              value={this.props.notificationMessage}
              onChange={this.handleChangeMessage}
              disabled={isDisabled}
            />
          </div>
        ) : null}
      </FormFieldGroup>
    )
  }
}

const connectState = state =>
  select(state, [
    'migrationStatus',
    'willSendNotification',
    'willIncludeCustomNotificationMessage',
    'notificationMessage',
    'willIncludeCourseSettings',
  ])
const connectActions = dispatch => bindActionCreators(actions, dispatch)
export const ConnectedMigrationOptions = connect(connectState, connectActions)(MigrationOptions)
