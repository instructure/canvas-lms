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

import React, {useEffect, useState} from 'react'
import {connect} from 'react-redux'

import {CloseButton, CondensedButton} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

import {useScope as useI18nScope} from '@canvas/i18n'

import {SummarizedChange} from '../utils/change_tracking'
import {ResetPaceWarningModal} from './reset_pace_warning_modal'
import {coursePaceActions} from '../actions/course_paces'
import {StoreState} from '../types'
import {getAutoSaving, getShowLoadingOverlay, getSyncing} from '../reducers/ui'
import {getSummarizedChanges} from '../reducers/course_paces'

const I18n = useI18nScope('unpublished_changes_tray_contents')

// the INSTUI <List as="ol"> has a bug where the item numbering
// is not in a hanging indent, so when list items wrap they
// wrap all the way under the number, which does not look correct.
// This styles a vanilla html OL until INSTUI fixes their bug.
function styleList() {
  if (document.getElementById('course_pace_changes_list_style')) return
  const styl = document.createElement('style')
  styl.id = 'course_pace_changes_list_style'
  styl.textContent = `
  ol.course_pace_changes {
    margin: 0 0 1.5rem;
    padding: 0;
    counter-reset: item;
  }

  ol.course_pace_changes>li {
    margin: 0 0 .5rem 2rem;
    text-indent: -2rem;
    list-style-type: none;
    counter-increment: item;
  }

  ol.course_pace_changes>li::before {
    display: inline-block;
    width: 1.5rem;
    margin-inline-end: 0.5rem;
    font-weight: bold;
    text-align: right;
    content: counter(item) ".";
  }
  `
  document.head.appendChild(styl)
}

// Doing this to avoid TS2339 errors-- remove once we're on InstUI 8
// const {Item} = List as any

interface StoreProps {
  readonly autoSaving: boolean
  readonly isSyncing: boolean
  readonly showLoadingOverlay: boolean
  readonly unpublishedChanges: SummarizedChange[]
}

interface DispatchProps {
  onResetPace: typeof coursePaceActions.onResetPace
}

interface PassedProps {
  handleTrayDismiss: (resetFocus: boolean) => void
}

type ComponentProps = StoreProps & DispatchProps & PassedProps

export const UnpublishedChangesTrayContents = ({
  autoSaving,
  isSyncing,
  showLoadingOverlay,
  onResetPace,
  unpublishedChanges,
  handleTrayDismiss,
}: ComponentProps) => {
  const [isResetWarningModalOpen, setResetWarningModalOpen] = useState(false)
  const cancelDisabled =
    autoSaving || isSyncing || showLoadingOverlay || unpublishedChanges.length === 0

  useEffect(() => {
    styleList()
  }, [])

  const handleResetConfirmed = () => {
    onResetPace()
    handleTrayDismiss(true)
  }

  return (
    <View as="div" width="20rem" margin="0 auto large" padding="small">
      <CloseButton
        data-testid="tray-close-button"
        placement="end"
        offset="small"
        onClick={() => handleTrayDismiss(false)}
        screenReaderLabel={I18n.t('Close')}
      />
      <View as="header" margin="0 0 medium">
        <h4>
          <Text weight="bold">{I18n.t('Unpublished Changes')}</Text>
        </h4>
      </View>
      <ol className="course_pace_changes">
        {unpublishedChanges.map(
          c =>
            c.summary && (
              <li key={c.id} style={{overflowWrap: 'break-word'}}>
                {c.summary}
              </li>
            )
        )}
      </ol>
      {window.ENV.FEATURES.course_paces_redesign && (
        <CondensedButton
          data-testid="reset-all-button"
          interaction={cancelDisabled ? 'disabled' : 'enabled'}
          onClick={() => setResetWarningModalOpen(true)}
          margin="small 0 0"
        >
          {I18n.t('Reset all')}
        </CondensedButton>
      )}
      <ResetPaceWarningModal
        open={isResetWarningModalOpen}
        onCancel={() => setResetWarningModalOpen(false)}
        onConfirm={handleResetConfirmed}
      />
    </View>
  )
}

const mapStateToProps = (state: StoreState): StoreProps => {
  return {
    autoSaving: getAutoSaving(state),
    isSyncing: getSyncing(state),
    showLoadingOverlay: getShowLoadingOverlay(state),
    unpublishedChanges: getSummarizedChanges(state),
  }
}

export default connect(mapStateToProps, {
  onResetPace: coursePaceActions.onResetPace,
})(UnpublishedChangesTrayContents)
