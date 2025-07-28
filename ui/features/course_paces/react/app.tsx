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
import PaceContent from './components/content'
import CoursePaceEmpty from './components/course_pace_table/course_pace_empty'
import type {ResponsiveSizes, StoreState, CoursePace} from './types'
import {
  getLoadingMessage,
  getShowLoadingOverlay,
  getShowPaceModal,
  getIsSyncing,
} from './reducers/ui'
import UnpublishedChangesTrayContents from './components/unpublished_changes_tray_contents'
import {useScope as createI18nScope} from '@canvas/i18n'
import {getSummarizedChanges, getCoursePace, getPacePublishing} from './reducers/course_paces'
import {coursePaceActions} from './actions/course_paces'
import type {SummarizedChange} from './utils/change_tracking'
import {Tray} from '@instructure/ui-tray'
import Errors from './components/errors'
import PaceModal from './components/pace_modal'

const I18n = createI18nScope('course_paces_app')

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
  readonly setBlueprintLocked: typeof actions.setBlueprintLocked
  readonly hidePaceModal: typeof actions.hidePaceModal
}

type ComponentProps = StoreProps & DispatchProps

export type ResponsiveComponentProps = ComponentProps & {
  readonly responsiveSize: ResponsiveSizes
}

export const App = ({
  loadingMessage,
  setResponsiveSize,
  setBlueprintLocked,
  showLoadingOverlay,
  hidePaceModal,
  modalOpen,
  responsiveSize,
  pollForPublishStatus,
  unpublishedChanges,
  coursePace,
}: ResponsiveComponentProps) => {
  const [trayOpen, setTrayOpen] = useState(false)

  // Start polling for publish status on mount if applicable
  useEffect(() => {
    pollForPublishStatus()
  }, [pollForPublishStatus])

  useEffect(() => {
    setResponsiveSize(responsiveSize)
  }, [responsiveSize, setResponsiveSize])

  useEffect(() => {
    setBlueprintLocked(
      window.ENV.MASTER_COURSE_DATA?.restricted_by_master_course &&
        window.ENV.MASTER_COURSE_DATA?.is_master_course_child_content &&
        coursePace.context_type === 'Course',
    )
  }, [])

  const handleModalClose = () => {
    hidePaceModal()
  }

  const renderApp = () => {
    return (
      <>
        <Flex as="section" alignItems="end" wrap="wrap">
          <Flex.Item margin="0 0 small">
            <Header
              handleDrawerToggle={() => setTrayOpen(!trayOpen)}
              responsiveSize={responsiveSize}
            />
            {!coursePace.id && coursePace.context_type === 'Course' ? (
              <CoursePaceEmpty responsiveSize={responsiveSize} />
            ) : (
              // Make sure changes have finished before updating contexts
              <PaceContent />
            )}
          </Flex.Item>
        </Flex>
        <PaceModal
          isOpen={modalOpen}
          changes={unpublishedChanges}
          onClose={() => handleModalClose()}
        />
      </>
    )
  }

  return (
    <View>
      <Overlay open={showLoadingOverlay} transition="fade" label={loadingMessage}>
        <Mask themeOverride={{zIndex: 10001 /* to appear over the fullscreen modal */}}>
          <Spinner renderTitle="Loading" size="large" margin="0 0 0 medium" />
        </Mask>
      </Overlay>
      <Flex as="div" direction="column" margin="small none small small">
        {renderApp()}
      </Flex>
    </View>
  )
}

export const ResponsiveApp = (props: ComponentProps) => (
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
    {responsiveProps => (
      <App responsiveSize={responsiveProps!.responsiveSize as ResponsiveSizes} {...props} />
    )}
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
  setBlueprintLocked: actions.setBlueprintLocked,
  setResponsiveSize: actions.setResponsiveSize,
  hidePaceModal: actions.hidePaceModal,
})(ResponsiveApp)
