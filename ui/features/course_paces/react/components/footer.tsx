// @ts-nocheck
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

import React, {useCallback, useState} from 'react'
import {connect} from 'react-redux'
import {useScope as useI18nScope} from '@canvas/i18n'

import {Button, IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {IconTrashLine} from '@instructure/ui-icons'
import {Spinner} from '@instructure/ui-spinner'
import {Tooltip} from '@instructure/ui-tooltip'
import {View} from '@instructure/ui-view'

import {ResponsiveSizes, StoreState} from '../types'
import {
  getAnyActiveRequests,
  getAutoSaving,
  getShowLoadingOverlay,
  getSyncing,
  getBlueprintLocked,
} from '../reducers/ui'
import {coursePaceActions} from '../actions/course_paces'
import {
  getIsUnpublishedNewPace,
  getPacePublishing,
  getUnpublishedChangeCount,
  isNewPace,
  isSectionPace,
  isStudentPace,
  getPaceName,
} from '../reducers/course_paces'
import {getBlackoutDatesSyncing, getBlackoutDatesUnsynced} from '../shared/reducers/blackout_dates'
import UnpublishedChangesIndicator from './unpublished_changes_indicator'
import {RemovePaceWarningModal} from './remove_pace_warning_modal'

const I18n = useI18nScope('course_paces_footer')

interface StoreProps {
  readonly autoSaving: boolean
  readonly pacePublishing: boolean
  readonly blackoutDatesSyncing: boolean
  readonly isSyncing: boolean
  readonly blackoutDatesUnsynced: boolean
  readonly showLoadingOverlay: boolean
  readonly sectionPace: boolean
  readonly studentPace: boolean
  readonly newPace: boolean
  readonly unpublishedChanges: boolean
  readonly anyActiveRequests: boolean
  readonly isUnpublishedNewPace: boolean
  readonly paceName: string
  readonly blueprintLocked: boolean | undefined
}

interface DispatchProps {
  onResetPace: typeof coursePaceActions.onResetPace
  syncUnpublishedChanges: typeof coursePaceActions.syncUnpublishedChanges
  removePace: typeof coursePaceActions.removePace
}

interface PassedProps {
  readonly handleCancel: () => void
  readonly handleDrawerToggle?: () => void
  readonly responsiveSize: ResponsiveSizes
  readonly focusOnClose?: () => void
}

type ComponentProps = StoreProps & DispatchProps & PassedProps

export const Footer = ({
  autoSaving,
  pacePublishing,
  blackoutDatesSyncing,
  isSyncing,
  syncUnpublishedChanges,
  handleCancel,
  onResetPace,
  showLoadingOverlay,
  studentPace,
  sectionPace,
  newPace,
  unpublishedChanges,
  handleDrawerToggle,
  responsiveSize,
  removePace,
  anyActiveRequests,
  focusOnClose,
  isUnpublishedNewPace,
  paceName,
  blueprintLocked,
}: ComponentProps) => {
  const [isRemovePaceModalOpen, setRemovePaceModalOpen] = useState(false)
  const useRedesign = window.ENV.FEATURES.course_paces_redesign
  const userIsMasquerading = window.ENV.IS_MASQUERADING
  const allowStudentPaces = window.ENV.FEATURES.course_paces_for_students

  const handlePublish = useCallback(() => {
    syncUnpublishedChanges()
  }, [syncUnpublishedChanges])

  if (studentPace && !allowStudentPaces) return null

  const handlePublishClicked = () => {
    handlePublish()
    if (useRedesign && focusOnClose) {
      focusOnClose()
    }
  }

  const isCoursePace = !sectionPace && !studentPace
  const cancelDisabled = useRedesign
    ? anyActiveRequests
    : autoSaving || isSyncing || showLoadingOverlay || !unpublishedChanges
  const pubDisabled = useRedesign
    ? !newPace &&
      (!unpublishedChanges || autoSaving || isSyncing || showLoadingOverlay || blueprintLocked)
    : !newPace && (cancelDisabled || blueprintLocked)
  const removeDisabled = autoSaving || isSyncing || showLoadingOverlay || pacePublishing

  // This wrapper div attempts to roughly match the dimensions of the publish button
  let publishLabel = I18n.t('Publish')
  if (useRedesign) {
    if (newPace) {
      publishLabel = I18n.t('Create Pace')
    } else {
      publishLabel = I18n.t('Apply Changes')
    }
  }

  const handleCancelClick = () => {
    if (useRedesign) {
      handleCancel()
    } else {
      cancelDisabled || onResetPace()
    }
  }

  const handleRemovePaceClicked = () => {
    if (!removeDisabled) {
      setRemovePaceModalOpen(true)
    }
  }

  const handleRemovePaceConfirmed = () => {
    setRemovePaceModalOpen(false)
    removePace()
  }

  if (pacePublishing || isSyncing) {
    publishLabel = (
      <div style={{display: 'inline-block', margin: '-0.5rem 0.9rem'}}>
        <Spinner size="x-small" renderTitle={I18n.t('Publishing...')} />
      </div>
    )
  } else if (blackoutDatesSyncing) {
    publishLabel = (
      <div style={{display: 'inline-block', margin: '-0.5rem 0.9rem'}}>
        <Spinner size="x-small" renderTitle={I18n.t('Saving blackout dates...')} />
      </div>
    )
  }

  let cancelTip, pubTip, removeTip
  if (autoSaving || isSyncing) {
    cancelTip = I18n.t('You cannot cancel while publishing')
    pubTip = I18n.t('You cannot publish while publishing')
    removeTip = I18n.t('You cannot remove the pace while publishing')
  } else if (showLoadingOverlay) {
    cancelTip = I18n.t('You cannot cancel while loading the pace')
    pubTip = I18n.t('You cannot publish while loading the pace')
    removeTip = I18n.t('You cannot remove the pace while it is still loading')
  } else if (blueprintLocked) {
    pubTip = I18n.t('You cannot edit a locked pace')
    removeTip = I18n.t('You cannot remove a locked pace')
  } else if (newPace) {
    cancelTip = I18n.t('There are no pending changes to cancel')
  } else {
    cancelTip = I18n.t('There are no pending changes to cancel')
    pubTip = I18n.t('There are no pending changes to publish')
  }

  const removePaceLabel = I18n.t('Remove Pace')
  const showRemovePaceButton = useRedesign && !isCoursePace && !newPace && !isUnpublishedNewPace
  const showCondensedView = useRedesign && responsiveSize === 'small'
  const removePaceButtonProps = {
    onClick: handleRemovePaceClicked,
    interaction: useRedesign && removeDisabled ? ('disabled' as const) : ('enabled' as const),
  }

  const renderChangesIndicator = () => {
    if (useRedesign && (!studentPace || (studentPace && allowStudentPaces))) {
      return <UnpublishedChangesIndicator newPace={newPace} onClick={handleDrawerToggle} />
    }
  }

  return (
    <View as="div" width="100%" margin={useRedesign && userIsMasquerading ? '0 0 x-large' : '0'}>
      {showCondensedView && (
        <View as="div" textAlign="center" borderWidth="0 0 small 0" padding="xx-small">
          {renderChangesIndicator()}
        </View>
      )}
      <Flex as="section" justifyItems="space-between" margin="small">
        <RemovePaceWarningModal
          open={isRemovePaceModalOpen}
          onCancel={() => setRemovePaceModalOpen(false)}
          onConfirm={handleRemovePaceConfirmed}
          contextType={studentPace ? 'Enrollment' : 'Section'}
          paceName={paceName}
        />
        <Flex.Item>
          {showRemovePaceButton && (
            <Tooltip
              renderTip={removeDisabled ? removeTip : ''}
              on={removeDisabled && !useRedesign ? ['hover', 'focus'] : []}
            >
              {showCondensedView ? (
                <IconButton
                  screenReaderLabel={removePaceLabel}
                  renderIcon={IconTrashLine}
                  {...removePaceButtonProps}
                />
              ) : (
                <Button
                  data-testid="remove-pace-button"
                  color="secondary"
                  {...removePaceButtonProps}
                >
                  {removePaceLabel}
                </Button>
              )}
            </Tooltip>
          )}
        </Flex.Item>
        <Flex.Item>
          {!showCondensedView && renderChangesIndicator()}
          <Tooltip
            renderTip={cancelDisabled ? cancelTip : ''}
            on={cancelDisabled && !useRedesign ? ['hover', 'focus'] : []}
          >
            <Button
              color="secondary"
              margin="0 small 0"
              onClick={handleCancelClick}
              interaction={useRedesign && cancelDisabled ? 'disabled' : 'enabled'}
            >
              {useRedesign ? I18n.t('Close') : I18n.t('Cancel')}
            </Button>
          </Tooltip>
          <Tooltip
            renderTip={pubDisabled ? pubTip : ''}
            on={pubDisabled && !useRedesign ? ['hover', 'focus'] : []}
          >
            <Button
              data-testid="apply-or-create-pace-button"
              color="primary"
              onClick={() => pubDisabled || handlePublishClicked()}
              interaction={(useRedesign && pubDisabled) || blueprintLocked ? 'disabled' : 'enabled'}
            >
              {publishLabel}
            </Button>
          </Tooltip>
        </Flex.Item>
      </Flex>
    </View>
  )
}

const mapStateToProps = (state: StoreState): StoreProps => {
  return {
    autoSaving: getAutoSaving(state),
    pacePublishing: getPacePublishing(state),
    blackoutDatesSyncing: getBlackoutDatesSyncing(state),
    isSyncing: getSyncing(state),
    blackoutDatesUnsynced: getBlackoutDatesUnsynced(state),
    showLoadingOverlay: getShowLoadingOverlay(state),
    studentPace: isStudentPace(state),
    sectionPace: isSectionPace(state),
    newPace: isNewPace(state),
    unpublishedChanges: getUnpublishedChangeCount(state) !== 0,
    anyActiveRequests: getAnyActiveRequests(state),
    isUnpublishedNewPace: getIsUnpublishedNewPace(state),
    paceName: getPaceName(state),
    blueprintLocked: getBlueprintLocked(state),
  }
}

export default connect(mapStateToProps, {
  onResetPace: coursePaceActions.onResetPace,
  syncUnpublishedChanges: coursePaceActions.syncUnpublishedChanges,
  removePace: coursePaceActions.removePace,
})(Footer)
