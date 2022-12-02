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

import Body from '../body'
import Errors from '../errors'
import Footer from '../footer'
import UnpublishedChangesTrayContents from '../unpublished_changes_tray_contents'
import UnpublishedWarningModal from '../header/unpublished_warning_modal'

import {coursePaceActions} from '../../actions/course_paces'
import {actions as uiActions} from '../../actions/ui'

import {
  CoursePace,
  OptionalDate,
  PaceContext,
  PaceDuration,
  ResponsiveSizes,
  Section,
  StoreState,
} from '../../types'
import {
  getCompression,
  getCoursePace,
  getCoursePaceItems,
  getPaceDuration,
  getPaceName,
  getPlannedEndDate,
  getUnappliedChangesExist,
} from '../../reducers/course_paces'
import {getResponsiveSize} from '../../reducers/ui'
import {SummarizedChange} from '../../utils/change_tracking'
import PaceModalHeading from './heading'
import {getSelectedPaceContext} from '../../reducers/pace_contexts'
import {getEnrolledSection} from '../../reducers/enrollments'
import PaceModalStats from './stats'
import {generateModalLauncherId} from '../../utils/utils'

const I18n = useI18nScope('course_paces_modal')

interface StoreProps {
  readonly coursePace: CoursePace
  readonly unappliedChangesExist: boolean
  readonly paceName: string
  readonly selectedPaceContext: PaceContext
  readonly enrolledSection: Section
  readonly assignmentsCount: number
  readonly paceDuration: PaceDuration
  readonly plannedEndDate: OptionalDate
  readonly compression: number
  readonly compressDates: any
  readonly uncompressDates: any
}

interface DispatchProps {
  onResetPace: typeof coursePaceActions.onResetPace
  clearCategoryError: typeof uiActions.clearCategoryError
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
    let title
    if (!props.coursePace) {
      return I18n.t('Loading...')
    }

    if (props.coursePace.context_type === 'Course') {
      title = I18n.t('Course Pace')
    } else if (props.coursePace.context_type === 'Section') {
      title = I18n.t('Section Pace')
    } else if (props.coursePace.context_type === 'Enrollment') {
      title = I18n.t('Student Pace')
    }
    return `${title}: ${props.paceName}`
  }

  const restoreFocus = () => {
    const launcherId = generateModalLauncherId(props.selectedPaceContext)
    document.getElementById(launcherId)?.focus()
  }

  const handleClose = () => {
    if (props.unappliedChangesExist) {
      setPendingContext(props.coursePace.context_type)
    } else {
      props.clearCategoryError('publish')
      props.onClose()
      restoreFocus()
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
            <Heading data-testid="course-pace-title" level="h2">
              <TruncateText>{modalTitle()}</TruncateText>
            </Heading>
          </FlexItem>
          <FlexItem>
            <IconButton
              data-testid="course-pace-edit-close-x"
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
      <Modal.Body padding={props.responsiveSize === 'small' ? 'none small' : 'none large'}>
        <View
          as="div"
          className="pace-redesign-inner-modal"
          maxWidth={props.responsiveSize === 'small' ? '100%' : '80%'}
          margin="none auto"
        >
          <Flex as="div" direction="column" margin="small">
            <View>
              <Errors />
            </View>
            <PaceModalHeading
              enrolledSection={props.enrolledSection}
              isBlueprintLocked={props.isBlueprintLocked}
              coursePace={props.coursePace}
              paceContext={props.selectedPaceContext}
              contextName={props.paceName}
              setIsBlueprintLocked={setIsBlueprintLocked}
            />
            <PaceModalStats
              coursePace={props.coursePace}
              assignments={props.assignmentsCount}
              paceDuration={props.paceDuration}
              plannedEndDate={props.plannedEndDate}
              compressDates={props.compressDates}
              uncompressDates={props.uncompressDates}
              compression={props.compression}
              responsiveSize={props.responsiveSize}
            />
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
        </View>
        <UnpublishedWarningModal
          open={!!pendingContext}
          onCancel={() => {
            setPendingContext('')
          }}
          onConfirm={() => {
            setPendingContext('')
            props.onResetPace()
            props.clearCategoryError('publish')
            props.onClose()
            restoreFocus()
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
    paceName: getPaceName(state),
    selectedPaceContext: getSelectedPaceContext(state),
    assignmentsCount: getCoursePaceItems(state).length,
    paceDuration: getPaceDuration(state),
    plannedEndDate: getPlannedEndDate(state),
    compression: getCompression(state),
    enrolledSection:
      state.paceContexts.selectedContextType === 'student_enrollment'
        ? getEnrolledSection(state, parseInt(state.paceContexts.selectedContext?.item_id || '', 10))
        : null,
  }
}

export default connect(mapStateToProps, {
  onResetPace: coursePaceActions.onResetPace,
  compressDates: coursePaceActions.compressDates,
  uncompressDates: coursePaceActions.uncompressDates,
  clearCategoryError: uiActions.clearCategoryError,
})(PaceModal)
