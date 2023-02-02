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

import {CategoryErrors, ResponsiveSizes, StoreState} from '../types'
import {getErrors, getResponsiveSize} from '../reducers/ui'
import {coursePaceActions} from '../actions/course_paces'
import {connect} from 'react-redux'
import React, {createRef, ReactNode, RefObject} from 'react'
import {ExpandableErrorAlert} from '@canvas/alerts/react/ExpandableErrorAlert'
import {useScope as useI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Button} from '@instructure/ui-buttons'

const I18n = useI18nScope('course_paces_errors')

type StoreProps = {
  errors: CategoryErrors
  responsiveSize: ResponsiveSizes
}

type DispatchProps = {
  syncUnpublishedChanges: typeof coursePaceActions.syncUnpublishedChanges
}

export type ErrorsProps = StoreProps & DispatchProps

export const Errors = ({errors, responsiveSize, syncUnpublishedChanges}: ErrorsProps) => {
  const alerts = Object.entries(errors).map(([category, error]) => {
    const result: {
      category: string
      summary?: string
      contents?: ReactNode
      error: string
      shouldTransferFocus?: boolean
      focusRef?: RefObject<HTMLElement>
    } = {category, error}
    result.shouldTransferFocus = !!error

    switch (category) {
      case 'publish':
      case 'blackout_dates':
        {
          const msg =
            category === 'publish'
              ? I18n.t('There was an error publishing your course pace.')
              : I18n.t('There was an error saving your blackout dates')
          result.focusRef = createRef()
          result.contents = (
            <>
              <div ref={result.focusRef} tabIndex={-1}>
                {msg}
              </div>
              <Button color="primary" margin="x-small 0 0" onClick={syncUnpublishedChanges}>
                {I18n.t('Retry')}
              </Button>
            </>
          )
          result.shouldTransferFocus = true
        }
        break
      case 'resetToLastPublished':
        result.contents = result.summary = I18n.t(
          'There was an error resetting to the previous pace.'
        )
        break
      case 'loading':
        result.contents = result.summary = I18n.t('There was an error loading the pace.')
        break
      case 'autosaving':
        result.contents = result.summary = I18n.t('There was an error saving your changes.')
        break
      case 'relinkToParent':
        result.contents = result.summary = I18n.t('There was an error linking pace.')
        break
      case 'checkPublishStatus':
        result.contents = result.summary = I18n.t(
          'There was an error checking pace publishing status.'
        )
        break
      default:
        result.contents = result.summary = I18n.t('An error has occurred.')
    }

    // Summary doesn't need to be announced if we are focusing the alert
    if (result.shouldTransferFocus) delete result.summary

    return result
  })

  return (
    <View as="div" maxWidth={responsiveSize !== 'small' ? '55%' : '100%'} margin="0 auto 0 auto">
      {alerts.map(a => (
        <ExpandableErrorAlert
          key={a.category}
          margin="small 0"
          error={window.INST.environment !== 'production' ? a.error : undefined}
          closeable={a.category !== 'publish'}
          liveRegionText={a.summary}
          transferFocus={a.shouldTransferFocus}
          focusRef={a.focusRef}
        >
          {a.contents}
        </ExpandableErrorAlert>
      ))}
    </View>
  )
}

const mapStateToProps = (state: StoreState): StoreProps => {
  return {
    errors: getErrors(state),
    responsiveSize: getResponsiveSize(state),
  }
}

export default connect(mapStateToProps, {
  syncUnpublishedChanges: coursePaceActions.syncUnpublishedChanges,
})(Errors)
