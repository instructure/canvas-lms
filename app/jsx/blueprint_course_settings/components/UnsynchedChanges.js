import React, { Component } from 'react'
import I18n from 'i18n!blueprint_settings'
import { connect } from 'react-redux'
import { bindActionCreators } from 'redux'
import select from 'jsx/shared/select'

import Alert from 'instructure-ui/lib/components/Alert'
import Heading from 'instructure-ui/lib/components/Heading'
import Checkbox from 'instructure-ui/lib/components/Checkbox'

import UnsynchedChange from './UnsynchedChange'

import actions from '../actions'
import propTypes from '../propTypes'

const { func, bool } = React.PropTypes

export default class UnsynchedChanges extends Component {
  static propTypes = {
    unsynchedChanges: propTypes.unsynchedChanges,
    willSendNotification: bool.isRequired,
    enableSendNotification: func.isRequired,
  }

  static defaultProps = {
    unsynchedChanges: [],
  }

  handleSendNotificationClick = (event) => {
    const enabled = event.target.checked
    this.props.enableSendNotification(enabled)
  }

  maybeRenderChanges () {
    return (
      this.props.unsynchedChanges.length === 0
      ?
        <Alert variant="info">{I18n.t('There are no unsynched changes')}</Alert>
      :
        this.renderChanges()
    )
  }

  renderChanges () {
    return (
      <div className="bcs__history-item bcs__unsynched-changes">
        <header className="bcs__history-item__title">
          <Heading level="h3">
            {I18n.t('%{count} Unsynched Changes', {count: this.props.unsynchedChanges.length})}
          </Heading>
        </header>
        {this.props.unsynchedChanges.map(change =>
          (<UnsynchedChange key={change.asset_id} change={change} />)
        )}
        <div className="bcs__history-notification">
          <div>
            <Checkbox
              label={I18n.t('Send Notification')}
              checked={this.props.willSendNotification}
              onChange={this.handleSendNotificationClick}
            />
          </div>
        </div>
      </div>
    )
  }

  render () {
    return (
      <div className="bcs__history">
        {this.maybeRenderChanges()}
      </div>
    )
  }
}

const connectState = state =>
  select(state, [
    'hasLoadedUnsynchedChanges',
    'isLoadingUnsynchedChanges',
    'unsynchedChanges',
    'willSendNotification',
  ])
const connectActions = dispatch => bindActionCreators(actions, dispatch)
export const ConnectedUnsynchedChanges = connect(connectState, connectActions)(UnsynchedChanges)
