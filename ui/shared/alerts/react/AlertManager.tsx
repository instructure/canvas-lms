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
import React, {createContext, type PropsWithChildren} from 'react'
import getLiveRegion from '@canvas/instui-bindings/react/liveRegion'

export type AlertManagerContextType = {
  setOnFailure: (alertMessage: string, screenReaderOnly?: boolean) => void
  setOnSuccess: (alertMessage: string, screenReaderOnly?: boolean) => void
}

export const AlertManagerContext = createContext<AlertManagerContextType>({
  setOnFailure: () => {},
  setOnSuccess: () => {},
})

type AlertManagerState = {
  alertStatus?: 'error' | 'success'
  alertMessage?: string
  key: number
  screenReaderOnly: boolean
}

export default class AlertManager extends React.Component<
  PropsWithChildren<{}>,
  AlertManagerState
> {
  state: AlertManagerState = {
    key: 0,
    screenReaderOnly: true,
  }

  closeAlert = () => {
    this.setState({
      alertMessage: undefined,
      alertStatus: undefined,
      screenReaderOnly: true,
    })
  }

  setOnFailure = (alertMessage: string, screenReaderOnly = false) => {
    this.setState(prevState => ({
      alertMessage,
      alertStatus: 'error',
      key: prevState.key + 1,
      screenReaderOnly,
    }))
  }

  setOnSuccess = (alertMessage: string, screenReaderOnly = true) => {
    this.setState(prevState => ({
      alertMessage,
      alertStatus: 'success',
      key: prevState.key + 1,
      screenReaderOnly,
    }))
  }

  renderAlert() {
    const ALERT_TIMEOUT = 5000
    if (this.state.alertStatus === 'success') {
      return (
        <Alert
          variant="success"
          liveRegion={getLiveRegion}
          onDismiss={this.closeAlert}
          screenReaderOnly={this.state.screenReaderOnly}
          timeout={ALERT_TIMEOUT}
        >
          {this.state.alertMessage}
        </Alert>
      )
    } else if (this.state.alertStatus === 'error') {
      return (
        <Alert
          liveRegion={getLiveRegion}
          margin="small"
          onDismiss={this.closeAlert}
          timeout={ALERT_TIMEOUT}
          screenReaderOnly={this.state.screenReaderOnly}
          variant="error"
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
          setOnSuccess: this.setOnSuccess,
        }}
      >
        {this.state.alertStatus && (
          <div
            key={this.state.key}
            style={{
              left: '26%',
              maxWidth: '1125px',
              position: 'fixed',
              right: '120px',
              top: '80px',
              zIndex: 101,
            }}
          >
            {this.renderAlert()}
          </div>
        )}
        {this.props.children}
      </AlertManagerContext.Provider>
    )
  }
}
