/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import React, {useState, useRef} from 'react'
import {connect} from 'react-redux'

import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {IconButton} from '@instructure/ui-buttons'
import {IconXSolid} from '@instructure/ui-icons'
import {Modal} from '@instructure/ui-modal'
import {TruncateText} from '@instructure/ui-truncate-text'
import {Tray} from '@instructure/ui-tray'
import {useScope as useI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'

import BlueprintLock from './header/blueprint_lock'
import Body from './body'
import Errors from './errors'
import Footer from './footer'
import ProjectedDates from './header/projected_dates/projected_dates'
import Settings from './header/settings/settings'
import UnpublishedChangesTrayContents from './unpublished_changes_tray_contents'
import UnpublishedWarningModal from './header/unpublished_warning_modal'

import {coursePaceActions} from '../actions/course_paces'
import {CoursePace, ResponsiveSizes, StoreState} from '../types'
import {getCoursePace, getUnappliedChangesExist} from '../reducers/course_paces'
import {getResponsiveSize} from '../reducers/ui'
import {SummarizedChange} from '../utils/change_tracking'

const I18n = useI18nScope('course_paces_modal')

interface StoreProps {
  readonly coursePace: CoursePace
  readonly unappliedChangesExist: boolean
}

interface DispatchProps {
  onResetPace: typeof coursePaceActions.onResetPace
}

interface PassedProps {
  readonly changes?: SummarizedChange[]
  readonly isBlueprintLocked: boolean
  readonly responsiveSize: ResponsiveSizes
  readonly isOpen: boolean
  readonly onClose: () => void
}

const {Item: FlexItem} = Flex as any

export const PaceModal: React.FC<PassedProps & DispatchProps & StoreProps> = props => {
  const [isBlueprintLocked, setIsBlueprintLocked] = useState(props.isBlueprintLocked)
  const [pendingContext, setPendingContext] = useState('')
  const [trayOpen, setTrayOpen] = useState(false)
  const closeButtonRef = useRef<HTMLElement | null>(null)

  const modalTitle = () => {
    if (!props.coursePace) {
      return I18n.t('Loading...')
    }

    if (props.coursePace.context_type === 'Course') {
      return I18n.t('Course Pace')
    } else if (props.coursePace.context_type === 'Section') {
      return I18n.t('Section Pace')
    } else if (props.coursePace.context_type === 'Enrollment') {
      return I18n.t('Student Pace')
    }
  }

  const handleClose = () => {
    if (props.unappliedChangesExist) {
      setPendingContext(props.coursePace.context_type)
    } else {
      props.onClose()
    }
  }

  const focusOnCloseButton = () => {
    if (closeButtonRef.current) {
      closeButtonRef.current.focus()
    }
  }

  const handleTrayDismiss = resetFocus => {
    setTrayOpen(false)
    if (resetFocus) {
      focusOnCloseButton()
    }
  }

  return (
    <Modal
      open={props.isOpen}
      onDismiss={handleClose}
      size="fullscreen"
      label={modalTitle()}
      shouldCloseOnDocumentClick={true}
      overflow="fit"
    >
      <Modal.Header>
        <Flex>
          <FlexItem shouldGrow={true} shouldShrink={true} align="center">
            <Heading level="h2">
              <TruncateText>{modalTitle()}</TruncateText>
            </Heading>
          </FlexItem>
          <FlexItem>
            <IconButton
              withBackground={false}
              withBorder={false}
              renderIcon={IconXSolid}
              screenReaderLabel={I18n.t('Close')}
              onClick={handleClose}
              elementRef={e => (closeButtonRef.current = e)}
            />
          </FlexItem>
        </Flex>
      </Modal.Header>
      <Modal.Body padding="large">
        <Flex as="div" direction="column" margin="small">
          <View>
            <Errors />
          </View>
          <Flex as="section" justifyItems="end">
            <Settings
              isBlueprintLocked={
                props.isBlueprintLocked && props.coursePace.context_type === 'Course'
              }
              margin="0 0 0 small"
            />
            <BlueprintLock
              newPace={!props.coursePace.id}
              contextIsCoursePace={props.coursePace.context_type === 'Course'}
              setIsBlueprintLocked={setIsBlueprintLocked}
            />
          </Flex>
          <ProjectedDates key={`${props.coursePace.context_type}-${props.coursePace.context_id}`} />
          <Body blueprintLocked={isBlueprintLocked} />
          <Tray
            label={I18n.t('Unpublished Changes tray')}
            open={trayOpen}
            onDismiss={handleTrayDismiss}
            placement={props.responsiveSize === 'small' ? 'bottom' : 'end'}
            shouldContainFocus={true}
            shouldReturnFocus={true}
            shouldCloseOnDocumentClick={true}
          >
            <UnpublishedChangesTrayContents
              handleTrayDismiss={handleTrayDismiss}
              changes={props.changes}
            />
          </Tray>
        </Flex>
        <UnpublishedWarningModal
          open={!!pendingContext}
          onCancel={() => {
            setPendingContext('')
          }}
          onConfirm={() => {
            setPendingContext('')
            props.onResetPace()
            props.onClose()
          }}
          contextType={props.coursePace.context_type}
        />
      </Modal.Body>
      <Modal.Footer theme={{padding: '0'}}>
        <Footer
          blueprintLocked={isBlueprintLocked}
          handleCancel={handleClose}
          handleDrawerToggle={() => setTrayOpen(!trayOpen)}
          responsiveSize={props.responsiveSize}
          focusOnClose={focusOnCloseButton}
        />
      </Modal.Footer>
    </Modal>
  )
}

const mapStateToProps = (state: StoreState) => {
  return {
    coursePace: getCoursePace(state),
    responsiveSize: getResponsiveSize(state),
    unappliedChangesExist: getUnappliedChangesExist(state),
  }
}

export default connect(mapStateToProps, {
  onResetPace: coursePaceActions.onResetPace,
})(PaceModal)
