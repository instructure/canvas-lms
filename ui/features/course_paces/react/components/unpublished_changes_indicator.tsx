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
import {CondensedButton} from '@instructure/ui-buttons'
import {useScope as useI18nScope} from '@canvas/i18n'
import {getCoursePace, getPacePublishing, getUnpublishedChangeCount} from '../reducers/course_paces'
import {StoreState} from '../types'
import {connect} from 'react-redux'
import {getCategoryError} from '../reducers/ui'
import {Spinner} from '@instructure/ui-spinner'
import {PresentationContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

const I18n = useI18nScope('unpublished_changes_button_props')

type StateProps = {
  changeCount: number
  pacePublishing: boolean
  newPace: boolean
  publishError?: string
}

export type UnpublishedChangesIndicatorProps = StateProps & {
  onClick?: () => void
  onUnpublishedNavigation?: (e: BeforeUnloadEvent) => void
  margin?: any // type from CondensedButtonProps; passed through
}

const text = (changeCount: number) => {
  if (changeCount < 0) throw Error(`changeCount cannot be negative (${changeCount})`)
  if (changeCount === 0) return I18n.t('All changes published')

  return I18n.t(
    {
      one: '1 unpublished change',
      other: '%{count} unpublished changes'
    },
    {count: changeCount}
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
  pacePublishing,
  publishError,
  onUnpublishedNavigation = triggerBrowserWarning
}: UnpublishedChangesIndicatorProps) => {
  const hasChanges = changeCount > 0

  useEffect(() => {
    if (hasChanges) {
      window.addEventListener('beforeunload', onUnpublishedNavigation)
      return () => window.removeEventListener('beforeunload', onUnpublishedNavigation)
    }
  }, [hasChanges, onUnpublishedNavigation])

  if (newPace) return null

  if (publishError !== undefined) {
    return (
      <View margin={margin}>
        <Text color="danger">{I18n.t('Publishing error')}</Text>
      </View>
    )
  }

  if (pacePublishing) {
    return (
      <View>
        <Spinner size="x-small" margin="0 x-small 0" renderTitle={I18n.t('Publishing pace...')} />
        <PresentationContent>
          <Text>{I18n.t('Publishing pace...')}</Text>
        </PresentationContent>
      </View>
    )
  }

  return changeCount ? (
    <CondensedButton data-testid="publish-status-button" onClick={onClick} margin={margin}>
      {text(changeCount)}
    </CondensedButton>
  ) : (
    <View margin={margin} data-testid="publish-status">
      {text(changeCount)}
    </View>
  )
}

const mapStateToProps = (state: StoreState) => ({
  changeCount: getUnpublishedChangeCount(state),
  pacePublishing: getPacePublishing(state),
  newPace: !getCoursePace(state)?.id,
  publishError: getCategoryError(state, 'publish')
})

export default connect(mapStateToProps)(UnpublishedChangesIndicator)
