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

import React, {useCallback} from 'react'
import {connect} from 'react-redux'
import {useScope as useI18nScope} from '@canvas/i18n'

import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Spinner} from '@instructure/ui-spinner'
import {Tooltip} from '@instructure/ui-tooltip'

import {StoreState} from '../types'
import {getAutoSaving, getShowLoadingOverlay, getSyncing} from '../reducers/ui'
import {coursePaceActions} from '../actions/course_paces'
import {
  getPacePublishing,
  getUnpublishedChangeCount,
  isNewPace,
  isSectionPace,
  isStudentPace,
} from '../reducers/course_paces'
import {getBlackoutDatesSyncing, getBlackoutDatesUnsynced} from '../shared/reducers/blackout_dates'

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
}

interface DispatchProps {
  onResetPace: typeof coursePaceActions.onResetPace
  syncUnpublishedChanges: typeof coursePaceActions.syncUnpublishedChanges
}

interface PassedProps {
  readonly blueprintLocked: boolean
}

type ComponentProps = StoreProps & DispatchProps & PassedProps

export const Footer: React.FC<ComponentProps> = ({
  autoSaving,
  pacePublishing,
  blackoutDatesSyncing,
  isSyncing,
  syncUnpublishedChanges,
  onResetPace,
  showLoadingOverlay,
  studentPace,
  sectionPace,
  newPace,
  unpublishedChanges,
  blueprintLocked,
}) => {
  const handlePublish = useCallback(() => {
    syncUnpublishedChanges()
  }, [syncUnpublishedChanges])

  if (studentPace) return null

  const cancelDisabled = autoSaving || isSyncing || showLoadingOverlay || !unpublishedChanges
  const pubDisabled =
    !newPace && (cancelDisabled || (blueprintLocked && !sectionPace && !studentPace))

  // This wrapper div attempts to roughly match the dimensions of the publish button
  let publishLabel = I18n.t('Publish')
  if (pacePublishing || isSyncing) {
    publishLabel = (
      <div style={{display: 'inline-block', margin: '-0.5rem 0.9rem'}}>
        <Spinner size="x-small" renderTitle={I18n.t('Publishing pace...')} />
      </div>
    )
  } else if (blackoutDatesSyncing) {
    publishLabel = (
      <div style={{display: 'inline-block', margin: '-0.5rem 0.9rem'}}>
        <Spinner size="x-small" renderTitle={I18n.t('Saving blackout dates...')} />
      </div>
    )
  }

  let cancelTip, pubTip
  if (autoSaving || isSyncing) {
    cancelTip = I18n.t('You cannot cancel while publishing')
    pubTip = I18n.t('You cannot publish while publishing')
  } else if (showLoadingOverlay) {
    cancelTip = I18n.t('You cannot cancel while loading the pace')
    pubTip = I18n.t('You cannot publish while loading the pace')
  } else if (blueprintLocked) {
    pubTip = I18n.t('You cannot edit a locked pace')
  } else if (newPace) {
    cancelTip = I18n.t('There are no pending changes to cancel')
  } else {
    cancelTip = I18n.t('There are no pending changes to cancel')
    pubTip = I18n.t('There are no pending changes to publish')
  }
  return (
    <Flex as="section" justifyItems="end">
      <Tooltip
        renderTip={cancelDisabled && cancelTip}
        on={cancelDisabled ? ['hover', 'focus'] : []}
      >
        <Button
          color="secondary"
          margin="0 small 0"
          onClick={() => cancelDisabled || onResetPace()}
        >
          {I18n.t('Cancel')}
        </Button>
      </Tooltip>
      <Tooltip renderTip={pubDisabled && pubTip} on={pubDisabled ? ['hover', 'focus'] : []}>
        <Button
          color="primary"
          disabled={blueprintLocked && !sectionPace && !studentPace}
          onClick={() => pubDisabled || handlePublish()}
        >
          {publishLabel}
        </Button>
      </Tooltip>
    </Flex>
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
  }
}

export default connect(mapStateToProps, {
  onResetPace: coursePaceActions.onResetPace,
  syncUnpublishedChanges: coursePaceActions.syncUnpublishedChanges,
})(Footer)
