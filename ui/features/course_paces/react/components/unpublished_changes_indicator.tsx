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
import {Link} from '@instructure/ui-link'
import {useScope as createI18nScope} from '@canvas/i18n'
import {getPacePublishing, getUnpublishedChangeCount} from '../reducers/course_paces'
import {getBlackoutDatesSyncing} from '../shared/reducers/blackout_dates'
import type {StoreState} from '../types'
import {connect} from 'react-redux'
import {getCategoryError, getSyncing} from '../reducers/ui'
import {Spinner} from '@instructure/ui-spinner'
import {PresentationContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

const I18n = createI18nScope('unpublished_changes_button_props')

type StateProps = {
  readonly changeCount: number
  readonly blackoutDatesSyncing: boolean
  readonly pacePublishing: boolean
  readonly isSyncing: boolean
  readonly publishError?: string
}

type PassedProps = {
  onClick?: () => void
  onUnpublishedNavigation?: (e: BeforeUnloadEvent) => void
  margin?: any // type from Link props; passed through
  readonly newPace: boolean
}

export type UnpublishedChangesIndicatorProps = StateProps & PassedProps

const text = (changeCount: number) => {
  if (changeCount < 0) throw Error(`changeCount cannot be negative (${changeCount})`)
  if (changeCount === 0) {
    return I18n.t('No pending changes')
  }

  return I18n.t(
    {
      one: '1 unsaved change',
      other: '%{count} unsaved changes',
    },
    {count: changeCount},
  )
}

// Show browser warning about unsaved changes per
// https://developer.mozilla.org/en-US/docs/Web/API/WindowEventHandlers/onbeforeunload
const triggerBrowserWarning = (e: BeforeUnloadEvent) => {
  // Preventing default triggers prompt in Firefox & Safari
  e.preventDefault()
  // Return value must be set to trigger prompt in Chrome & Edge
  e.returnValue = ''
}

export const UnpublishedChangesIndicator = ({
  changeCount,
  margin,
  newPace,
  onClick,
  blackoutDatesSyncing,
  pacePublishing,
  isSyncing,
  publishError,
  onUnpublishedNavigation = triggerBrowserWarning,
}: UnpublishedChangesIndicatorProps) => {
  const hasChanges = changeCount > 0

  useEffect(() => {
    if (hasChanges || newPace) {
      window.addEventListener('beforeunload', onUnpublishedNavigation)
      return () => window.removeEventListener('beforeunload', onUnpublishedNavigation)
    }
  }, [hasChanges, newPace, onUnpublishedNavigation])

  if (publishError !== undefined) {
    return (
      <View margin={margin}>
        <Text color="danger">{I18n.t('Publishing error')}</Text>
      </View>
    )
  }

  let publishingMessage
  if (pacePublishing || isSyncing) {
    publishingMessage = I18n.t('Publishing...')
  } else if (blackoutDatesSyncing) {
    publishingMessage = I18n.t('Saving blackout dates...')
  }

  if (isSyncing) {
    return (
      <View>
        {
          <Text>{publishingMessage}</Text>
        }
      </View>
    )
  }

  if (newPace && changeCount === 0) {
    return (
      <View margin={margin}>
        <Text data-testid="publish-status-button">{I18n.t('Pace is new and unpublished')}</Text>
      </View>
    )
  }

  return changeCount ? (
    <Link
      isWithinText={false}
      as="button"
      data-testid="publish-status-button"
      onClick={onClick}
      margin={margin}
    >
      {text(changeCount)}
    </Link>
  ) : (
    <View margin={margin} data-testid="publish-status">
      {text(changeCount)}
    </View>
  )
}

const mapStateToProps = (state: StoreState) => ({
  changeCount: getUnpublishedChangeCount(state),
  blackoutDatesSyncing: getBlackoutDatesSyncing(state),
  pacePublishing: getPacePublishing(state),
  isSyncing: getSyncing(state),
  publishError: getCategoryError(state, ['publish', 'blackout_dates']),
})

export default connect(mapStateToProps)(UnpublishedChangesIndicator)
