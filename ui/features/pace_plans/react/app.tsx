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

import React, {useEffect} from 'react'
import {connect} from 'react-redux'

import {Alert} from '@instructure/ui-alerts'
import {Flex} from '@instructure/ui-flex'
import {Mask, Overlay} from '@instructure/ui-overlays'
import {Responsive} from '@instructure/ui-responsive'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'

import {actions} from './actions/ui'
import Header from './components/header/header'
import Body from './components/body'
import {ResponsiveSizes, StoreState} from './types'
import {getErrorMessage, getLoadingMessage, getShowLoadingOverlay} from './reducers/ui'

interface StoreProps {
  readonly errorMessage: string
  readonly loadingMessage: string
  readonly showLoadingOverlay: boolean
}

interface DispatchProps {
  readonly setResponsiveSize: typeof actions.setResponsiveSize
}

type ComponentProps = StoreProps & DispatchProps

type ResponsiveComponentProps = ComponentProps & {
  readonly responsiveSize: ResponsiveSizes
}

export const App: React.FC<ResponsiveComponentProps> = ({
  errorMessage,
  loadingMessage,
  setResponsiveSize,
  showLoadingOverlay,
  responsiveSize
}) => {
  useEffect(() => {
    setResponsiveSize(responsiveSize)
  }, [responsiveSize, setResponsiveSize])

  const renderErrorAlert = () => {
    if (errorMessage) {
      return (
        <Alert variant="error" closeButtonLabel="Close" margin="small">
          {errorMessage}
        </Alert>
      )
    }
  }

  return (
    <View>
      <Overlay open={showLoadingOverlay} transition="fade" label={loadingMessage}>
        <Mask>
          <Spinner title="Loading" size="large" margin="0 0 0 medium" />
        </Mask>
      </Overlay>
      <View overflowX="auto" width="100%">
        <Flex as="div" direction="column">
          <View>
            {renderErrorAlert()}
            <Header />
          </View>
          <Body />
        </Flex>
      </View>
    </View>
  )
}

export const ResponsiveApp: React.FC<ComponentProps> = props => (
  <Responsive
    query={{
      small: {maxWidth: '40rem'},
      large: {minWidth: '40rem'}
    }}
    props={{
      small: {responsiveSize: 'small'},
      large: {responsiveSize: 'large'}
    }}
  >
    {({responsiveSize}) => <App responsiveSize={responsiveSize} {...props} />}
  </Responsive>
)

const mapStateToProps = (state: StoreState): StoreProps => {
  return {
    errorMessage: getErrorMessage(state),
    loadingMessage: getLoadingMessage(state),
    showLoadingOverlay: getShowLoadingOverlay(state)
  }
}

export default connect(mapStateToProps, {
  setResponsiveSize: actions.setResponsiveSize
})(ResponsiveApp)
