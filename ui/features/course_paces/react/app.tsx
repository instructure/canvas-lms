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
import PaceModal from './components/pace_modal'
import PacePicker from './components/header/pace_picker'
import CoursePaceEmpty from './components/course_pace_table/course_pace_empty'
import {ResponsiveSizes, StoreState, CoursePace} from './types'
import {getLoadingMessage, getShowLoadingOverlay, getShowPaceModal} from './reducers/ui'
import UnpublishedChangesTrayContents from './components/unpublished_changes_tray_contents'
import {useScope as useI18nScope} from '@canvas/i18n'
import {getSummarizedChanges, getCoursePace} from './reducers/course_paces'
import {coursePaceActions} from './actions/course_paces'
import {SummarizedChange} from './utils/change_tracking'
import {Tray} from '@instructure/ui-tray'
import Errors from './components/errors'

const {Item: FlexItem} = Flex as any

const I18n = useI18nScope('course_paces_app')

interface StoreProps {
  readonly loadingMessage: string
  readonly showLoadingOverlay: boolean
  readonly modalOpen: boolean
  readonly unpublishedChanges: SummarizedChange[]
  readonly coursePace: CoursePace
}

interface DispatchProps {
  readonly pollForPublishStatus: typeof coursePaceActions.pollForPublishStatus
  readonly setResponsiveSize: typeof actions.setResponsiveSize
  readonly hidePaceModal: typeof actions.hidePaceModal
}

type ComponentProps = StoreProps & DispatchProps

type ResponsiveComponentProps = ComponentProps & {
  readonly responsiveSize: ResponsiveSizes
}

export const App: React.FC<ResponsiveComponentProps> = ({
  loadingMessage,
  setResponsiveSize,
  showLoadingOverlay,
  hidePaceModal,
  modalOpen,
  responsiveSize,
  pollForPublishStatus,
  unpublishedChanges,
  coursePace,
}) => {
  const [trayOpen, setTrayOpen] = useState(false)

  // Start polling for publish status on mount if applicable
  useEffect(() => {
    pollForPublishStatus()
  }, [pollForPublishStatus])

  const [isBlueprintLocked, setIsBlueprintLocked] = useState(false)

  useEffect(() => {
    setResponsiveSize(responsiveSize)
  }, [responsiveSize, setResponsiveSize])

  const handleModalClose = () => {
    hidePaceModal()
  }

  const renderApp = () => {
    if (window.ENV.FEATURES.course_paces_redesign) {
      return (
        <>
          <Flex as="section" alignItems="end" wrap="wrap">
            <FlexItem margin="0 0 small">
              <Header
                coursePace={coursePace}
                isBlueprintLocked={isBlueprintLocked}
                setIsBlueprintLocked={setIsBlueprintLocked}
                handleDrawerToggle={() => setTrayOpen(!trayOpen)}
                responsiveSize={responsiveSize}
              />
              {!coursePace.id && coursePace.context_type === 'Course' ? (
                <CoursePaceEmpty responsiveSize={responsiveSize} />
              ) : (
                <PacePicker />
              )}
            </FlexItem>
          </Flex>
          <PaceModal
            isOpen={modalOpen}
            isBlueprintLocked={isBlueprintLocked}
            changes={unpublishedChanges}
            responsiveSize={responsiveSize}
            onClose={() => handleModalClose()}
            handleDrawerToggle={() => setTrayOpen(!trayOpen)}
          />
        </>
      )
    } else {
      return (
        <>
          <View>
            <Errors />
            <Header
              isBlueprintLocked={isBlueprintLocked}
              setIsBlueprintLocked={setIsBlueprintLocked}
              handleDrawerToggle={() => setTrayOpen(!trayOpen)}
            />
          </View>
          <Body blueprintLocked={isBlueprintLocked} />
          <Footer blueprintLocked={isBlueprintLocked} responsiveSize={responsiveSize} />
          <Tray
            label={I18n.t('Unpublished Changes tray')}
            open={trayOpen}
            onDismiss={() => setTrayOpen(false)}
            placement={responsiveSize === 'small' ? 'bottom' : 'end'}
            shouldContainFocus={true}
            shouldReturnFocus={true}
            shouldCloseOnDocumentClick={true}
          >
            <UnpublishedChangesTrayContents
              handleTrayDismiss={() => setTrayOpen(false)}
              changes={unpublishedChanges}
            />
          </Tray>
        </>
      )
    }
  }

  return (
    <View>
      <Overlay open={showLoadingOverlay} transition="fade" label={loadingMessage}>
        <Mask theme={{zIndex: 10001 /* to appear over the fullscreen modal */}}>
          <Spinner renderTitle="Loading" size="large" margin="0 0 0 medium" />
        </Mask>
      </Overlay>
      <Flex as="div" direction="column" margin="small">
        {renderApp()}
      </Flex>
    </View>
  )
}

export const ResponsiveApp: React.FC<ComponentProps> = props => (
  <Responsive
    query={{
      small: {maxWidth: '40rem'},
      large: {minWidth: '40rem'},
    }}
    props={{
      small: {responsiveSize: 'small'},
      large: {responsiveSize: 'large'},
    }}
  >
    {({responsiveSize}) => <App responsiveSize={responsiveSize} {...props} />}
  </Responsive>
)

const mapStateToProps = (state: StoreState): StoreProps => {
  return {
    loadingMessage: getLoadingMessage(state),
    showLoadingOverlay: getShowLoadingOverlay(state),
    modalOpen: getShowPaceModal(state),
    unpublishedChanges: getSummarizedChanges(state),
    coursePace: getCoursePace(state),
  }
}

export default connect(mapStateToProps, {
  pollForPublishStatus: coursePaceActions.pollForPublishStatus,
  setResponsiveSize: actions.setResponsiveSize,
  hidePaceModal: actions.hidePaceModal,
})(ResponsiveApp)
