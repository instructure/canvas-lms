/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {connect} from 'react-redux'
import {Alert} from '@instructure/ui-alerts'
import {Flex} from '@instructure/ui-flex'
import {Mask, Overlay} from '@instructure/ui-overlays'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'

import Header from './components/header/header'
import Body from './components/body'
import {StoreState, PacePlan} from './types'
import {getErrorMessage, getLoadingMessage, getShowLoadingOverlay} from './reducers/ui'
import {getPacePlan} from './reducers/pace_plans'

interface StoreProps {
  readonly errorMessage: string
  readonly loadingMessage: string
  readonly showLoadingOverlay: boolean
  readonly pacePlan: PacePlan
}

export class App extends React.Component<StoreProps> {
  renderErrorAlert() {
    if (this.props.errorMessage) {
      return (
        <Alert variant="error" closeButtonLabel="Close" margin="small">
          {this.props.errorMessage}
        </Alert>
      )
    }
  }

  render() {
    return (
      <View>
        <Overlay
          open={this.props.showLoadingOverlay}
          transition="fade"
          label={this.props.loadingMessage}
        >
          <Mask>
            <Spinner title="Loading" size="large" margin="0 0 0 medium" />
          </Mask>
        </Overlay>
        <View overflowX="auto" width="100%">
          <Flex as="div" direction="column">
            <View>
              {this.renderErrorAlert()}
              <Header />
            </View>
            <Body />
          </Flex>
        </View>
      </View>
    )
  }
}

const mapStateToProps = (state: StoreState): StoreProps => {
  return {
    errorMessage: getErrorMessage(state),
    loadingMessage: getLoadingMessage(state),
    showLoadingOverlay: getShowLoadingOverlay(state),
    pacePlan: getPacePlan(state)
  }
}

export default connect(mapStateToProps)(App)
