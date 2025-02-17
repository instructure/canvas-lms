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

import React, { useState, useRef, useEffect } from 'react'
import { connect } from 'react-redux'

import { Flex } from '@instructure/ui-flex'
import { Responsive } from '@instructure/ui-responsive'
import { Heading } from '@instructure/ui-heading'
import { IconButton } from '@instructure/ui-buttons'
import { IconXSolid } from '@instructure/ui-icons'
import { Modal } from '@instructure/ui-modal'
import { TruncateText } from '@instructure/ui-truncate-text'
import { Tray } from '@instructure/ui-tray'
import { useScope as createI18nScope } from '@canvas/i18n'
import { View } from '@instructure/ui-view'

import Body from '../body'
import Errors from '../errors'
import Footer from '../footer'
import UnpublishedChangesTrayContents from '../unpublished_changes_tray_contents'
import UnpublishedWarningModal from '../header/unpublished_warning_modal'

import { coursePaceActions } from '../../actions/course_paces'
import { actions as uiActions } from '../../actions/ui'

import type {
  CoursePace,
  OptionalDate,
  Pace,
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
import { isBulkEnrollment , getSelectedPaceContext } from '../../reducers/pace_contexts'
import { getResponsiveSize } from '../../reducers/ui'
import type { SummarizedChange } from '../../utils/change_tracking'
import PaceModalHeading from './heading'
import { getEnrolledSection } from '../../reducers/enrollments'
import PaceModalStats from './stats'
import { generateModalLauncherId } from '../../utils/utils'
import TimeSelection from './TimeSelection'
import WeightedAssignmentsTray from '../header/settings/WeightedAssignmentsTray'
import { Alert } from '@instructure/ui-alerts'

const I18n = createI18nScope('course_paces_modal')

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
  readonly isBulkEnrollment: boolean
}

interface DispatchProps {
  onResetPace: typeof coursePaceActions.onResetPace
  clearCategoryError: typeof uiActions.clearCategoryError
  readonly setOuterResponsiveSize: typeof uiActions.setOuterResponsiveSize
}

interface PassedProps {
  readonly changes?: SummarizedChange[]
  readonly isOpen: boolean
  readonly onClose: () => void
}

type ComponentProps = PassedProps & DispatchProps & StoreProps

export type ResponsiveComponentProps = ComponentProps & {
  readonly outerResponsiveSize: ResponsiveSizes
  responsiveSize: ResponsiveSizes
}

export const PaceModal = ({
  outerResponsiveSize,
  setOuterResponsiveSize,
  ...props
}: ResponsiveComponentProps) => {
  const [pendingContext, setPendingContext] = useState('')
  const [trayOpen, setTrayOpen] = useState(false)
  const closeButtonRef = useRef<HTMLElement | null>(null)

  useEffect(() => {
    setOuterResponsiveSize(outerResponsiveSize)
  }, [outerResponsiveSize, setOuterResponsiveSize])

  const modalTitle = () => {
    let title
    if (!props.coursePace) {
      return I18n.t('Loading...')
    }

    if(props.isBulkEnrollment) {
      return I18n.t('Bulk Edit Student Pacing')
    } else if (props.coursePace.context_type === 'Course') {
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

  // @ts-expect-error
  const handleTrayDismiss = resetFocus => {
    setTrayOpen(false)
    if (resetFocus) {
      focusOnCloseButton()
    }
  }

  const renderMasteryPathWarning = () => {
    if (!ENV.FEATURES.course_pace_pacing_with_mastery_paths || !ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED) {
      return null
    }
    return (
      <Alert variant="warning" margin="small">
        All assignments in any Mastery Path are not assigned to all students.
        As a student progresses through any Mastery Path, assignments will be assigned based on a student&apos;s performance.
      </Alert>
    )
  }

  const headerSection = window.ENV.FEATURES.course_pace_time_selection ? (
    <TimeSelection
      coursePace={props.coursePace}
      appliedPace={props.selectedPaceContext?.applied_pace as Pace}
      responsiveSize={props.responsiveSize}
    />
  ) : (
    <PaceModalStats
      appliedPace={props.selectedPaceContext?.applied_pace as Pace}
      coursePace={props.coursePace}
      assignments={props.assignmentsCount}
      paceDuration={props.paceDuration}
      plannedEndDate={props.plannedEndDate}
      compressDates={props.compressDates}
      uncompressDates={props.uncompressDates}
      compression={props.compression}
      responsiveSize={outerResponsiveSize}
    />
  )

  return (
    <Modal
      open={props.isOpen}
      size="fullscreen"
      label={modalTitle()}
      shouldCloseOnDocumentClick={true}
      overflow="fit"
      aria-modal={true}
    >
      <Modal.Header>
        <Flex>
          <Flex.Item shouldGrow={true} shouldShrink={true} align="center">
            <Heading data-testid="course-pace-title" level="h2">
              <TruncateText>{modalTitle()}</TruncateText>
            </Heading>
          </Flex.Item>
          <Flex.Item>
            <IconButton
              data-testid="course-pace-edit-close-x"
              withBackground={false}
              withBorder={false}
              renderIcon={IconXSolid}
              screenReaderLabel={I18n.t('Close')}
              onClick={handleClose}
              // @ts-expect-error
              elementRef={e => (closeButtonRef.current = e)}
            />
          </Flex.Item>
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
              coursePace={props.coursePace}
              paceContext={props.selectedPaceContext}
              contextName={props.paceName}
            />
            {renderMasteryPathWarning()}
            {headerSection}
            <Body />
            <Tray
              label={I18n.t('Unpublished Changes tray')}
              open={trayOpen}
              onDismiss={handleTrayDismiss}
              placement={outerResponsiveSize === 'small' ? 'bottom' : 'end'}
              shouldContainFocus={true}
              shouldReturnFocus={true}
              shouldCloseOnDocumentClick={false}
            >
              <UnpublishedChangesTrayContents
                handleTrayDismiss={handleTrayDismiss}
                // @ts-expect-error
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
        {window.ENV.FEATURES.course_pace_weighted_assignments && <WeightedAssignmentsTray />}
      </Modal.Body>
      <Modal.Footer themeOverride={{ padding: '0' }}>
        <Footer
          handleCancel={handleClose}
          handleDrawerToggle={() => setTrayOpen(!trayOpen)}
          responsiveSize={outerResponsiveSize}
          focusOnClose={focusOnCloseButton}
        />
      </Modal.Footer>
    </Modal>
  )
}

export const ResponsivePaceModal = (props: ComponentProps) => (
  <Responsive
    match="media"
    query={{
      small: { maxWidth: '80rem' },
      large: { minWidth: '80rem' },
    }}
    props={{
      small: { responsiveSize: 'small' },
      large: { responsiveSize: 'large' },
    }}
  >
    {/* @ts-expect-error */}
    {({ responsiveSize }) => <PaceModal outerResponsiveSize={responsiveSize} {...props} />}
  </Responsive>
)

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
    isBulkEnrollment: isBulkEnrollment(state),
  }
}

export default connect(mapStateToProps, {
  onResetPace: coursePaceActions.onResetPace,
  compressDates: coursePaceActions.compressDates,
  uncompressDates: coursePaceActions.uncompressDates,
  clearCategoryError: uiActions.clearCategoryError,
  setOuterResponsiveSize: uiActions.setOuterResponsiveSize,
  // @ts-expect-error
})(ResponsivePaceModal)
