/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import {Alert} from '@instructure/ui-alerts'
import React from 'react'

export const AlertManagerContext = React.createContext({
  setOnFailure: {},
  setOnSuccess: {}
})

export default class AlertManager extends React.Component {
  state = {
    alertStatus: null,
    alertMessage: null
  }

  closeAlert = () => {
    this.setState({
      alertMessage: null,
      alertStatus: null
    })
  }

  setOnFailure = alertMessage => {
    this.setState({
      alertMessage,
      alertStatus: 'error'
    })
  }

  setOnSuccess = alertMessage => {
    this.setState({
      alertMessage,
      alertStatus: 'success'
    })
  }

  renderAlert() {
    const ALERT_TIMEOUT = 5000
    if (this.state.alertStatus === 'success') {
      return (
        <Alert
          screenReaderOnly
          liveRegion={() => document.getElementById('flash_screenreader_holder')}
          onDismiss={this.closeAlert}
          timeout={ALERT_TIMEOUT}
        >
          {this.state.alertMessage}
        </Alert>
      )
    } else if (this.state.alertStatus === 'error') {
      return (
        <Alert
          variant="error"
          margin="small"
          timeout={ALERT_TIMEOUT}
          liveRegion={() => document.getElementById('flash_screenreader_holder')}
          onDismiss={this.closeAlert}
        >
          {this.state.alertMessage}
        </Alert>
      )
    }
  }

  render() {
    return (
      <AlertManagerContext.Provider
        value={{
          setOnFailure: this.setOnFailure,
          setOnSuccess: this.setOnSuccess
        }}
      >
        {this.state.alertStatus && this.renderAlert()}
        {this.props.children}
      </AlertManagerContext.Provider>
    )
  }
}
