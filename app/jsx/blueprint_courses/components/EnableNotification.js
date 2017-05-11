import React from 'react'
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

export default class EnableNotification extends React.Component {
  static propTypes = {
    migrationStatus: propTypes.migrationState.isRequired,
    willSendNotification: React.PropTypes.bool.isRequired,
    willIncludeCustomNotificationMessage: React.PropTypes.bool.isRequired,
    notificationMessage: React.PropTypes.string.isRequired,
    enableSendNotification: React.PropTypes.func.isRequired,
    includeCustomNotificationMessage: React.PropTypes.func.isRequired,
    setNotificationMessage: React.PropTypes.func.isRequired,
  }

  handleSendNotificationChange = (event) => {
    this.props.enableSendNotification(event.target.checked)
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
        <div className="bcs__history-notification__enable">
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
              isBlock={false}
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
              isBlock
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
  ])
const connectActions = dispatch => bindActionCreators(actions, dispatch)
export const ConnectedEnableNotification = connect(connectState, connectActions)(EnableNotification)
