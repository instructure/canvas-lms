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

import React, {useEffect, useState} from 'react'
import {connect} from 'react-redux'

import {Flex} from '@instructure/ui-flex'
import {Mask, Overlay} from '@instructure/ui-overlays'
import {Responsive} from '@instructure/ui-responsive'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'

import {actions} from './actions/ui'
import Body from './components/body'
import Footer from './components/footer'
import Header from './components/header/header'
import {ResponsiveSizes, StoreState} from './types'
import {getLoadingMessage, getShowLoadingOverlay} from './reducers/ui'
import UnpublishedChangesTrayContents from './components/unpublished_changes_tray_contents'
import {useScope as useI18nScope} from '@canvas/i18n'
import {getSummarizedChanges} from './reducers/course_paces'
import {coursePaceActions} from './actions/course_paces'
import {SummarizedChange} from './utils/change_tracking'
import {Tray} from '@instructure/ui-tray'
import Errors from './components/errors'

const I18n = useI18nScope('course_paces_app')

interface StoreProps {
  readonly loadingMessage: string
  readonly showLoadingOverlay: boolean
  readonly unpublishedChanges: SummarizedChange[]
}

interface DispatchProps {
  readonly pollForPublishStatus: typeof coursePaceActions.pollForPublishStatus
  readonly setResponsiveSize: typeof actions.setResponsiveSize
}

type ComponentProps = StoreProps & DispatchProps

type ResponsiveComponentProps = ComponentProps & {
  readonly responsiveSize: ResponsiveSizes
}

export const App: React.FC<ResponsiveComponentProps> = ({
  loadingMessage,
  setResponsiveSize,
  showLoadingOverlay,
  responsiveSize,
  pollForPublishStatus,
  unpublishedChanges
}) => {
  const [trayOpen, setTrayOpen] = useState(false)

  // Start polling for publish status on mount if applicable
  useEffect(() => {
    pollForPublishStatus()
  }, [pollForPublishStatus])

  useEffect(() => {
    setResponsiveSize(responsiveSize)
  }, [responsiveSize, setResponsiveSize])

  return (
    <View>
      <Overlay open={showLoadingOverlay} transition="fade" label={loadingMessage}>
        <Mask>
          <Spinner title="Loading" size="large" margin="0 0 0 medium" />
        </Mask>
      </Overlay>
      <Flex as="div" direction="column" margin="small">
        <View>
          <Errors />
          <Header handleDrawerToggle={() => setTrayOpen(!trayOpen)} />
        </View>
        <Body />
        <Footer />
        <Tray
          label={I18n.t('Unpublished Changes tray')}
          open={trayOpen}
          onDismiss={() => setTrayOpen(false)}
          placement={responsiveSize === 'small' ? 'bottom' : 'end'}
          shouldContainFocus
          shouldReturnFocus
          shouldCloseOnDocumentClick
        >
          <UnpublishedChangesTrayContents
            handleTrayDismiss={() => setTrayOpen(false)}
            changes={unpublishedChanges}
          />
        </Tray>
      </Flex>
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
    loadingMessage: getLoadingMessage(state),
    showLoadingOverlay: getShowLoadingOverlay(state),
    unpublishedChanges: getSummarizedChanges(state)
  }
}

export default connect(mapStateToProps, {
  pollForPublishStatus: coursePaceActions.pollForPublishStatus,
  setResponsiveSize: actions.setResponsiveSize
})(ResponsiveApp)
