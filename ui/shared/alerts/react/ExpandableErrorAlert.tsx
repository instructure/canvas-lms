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

import React, {RefObject, useCallback, useEffect, useRef, useState} from 'react'
import {Alert, AlertProps} from '@instructure/ui-alerts'
import {useScope as useI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {ToggleDetails} from '@instructure/ui-toggle-details'
import {FocusRegionManager} from '@instructure/ui-a11y-utils'
import getLiveRegion from '@canvas/instui-bindings/react/liveRegion'

const I18n = useI18nScope('app_shared_components_expandable_error_alert')

export type ExpandableErrorAlertProps = Omit<
  AlertProps,
  'variant' | 'liveRegion' | 'renderCloseButtonLabel' | 'hasShadow'
> & {
  /**
   * The raw details of the error.
   */
  error?: string
  /**
   * Whether or not the alert can be closed (defaults to `false`). If enabled, a close button is displayed, with "Close" as the label.
   */
  closeable?: boolean
  /**
   * If provided, this text will be announced immediately by the user's screen reader.
   */
  liveRegionText?: string
  /**
   * Whether or not to transfer focus to the alert upon rendering.
   */
  transferFocus?: boolean
  /**
   * If `transferFocus` is true, focus will be transferred to this target. If this ref is `undefined`, focus will instead be transferred to the `div` containing `children`.
   */
  focusRef?: RefObject<HTMLElement>
}

export const ExpandableErrorAlert = ({
  error,
  closeable,
  liveRegionText,
  transferFocus,
  focusRef,
  children,
  onDismiss,
  ...alertProps
}: ExpandableErrorAlertProps) => {
  const [open, setOpen] = useState(true)
  const childrenRef = useRef<HTMLDivElement>(null)

  const handleDismiss = useCallback(() => {
    setOpen(false)
    if (onDismiss) onDismiss()
  }, [onDismiss])

  useEffect(() => {
    if (transferFocus) {
      const ref = (focusRef || childrenRef).current
      if (ref === null) throw new Error('childrenRef did not appear as expected')
      FocusRegionManager.focusRegion(ref, {
        onBlur: () => {},
        onDismiss: () => {},
      })
    }
    // We only ever want to transfer focus one time
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  return (
    <div>
      {/* This is to modify the alert contents that are added to the live region. The `Alert` component just uses
      `props.children` for the content that is appended there, which is a problem if the children contain content that
       is interactive and not useful to be read aloud as part of the live region announcement (ex: a Retry button). */}
      {liveRegionText && (
        <Alert liveRegion={getLiveRegion} open={open} screenReaderOnly={true}>
          {liveRegionText}
        </Alert>
      )}
      <Alert
        {...alertProps}
        variant="error"
        renderCloseButtonLabel={closeable ? I18n.t('Close') : undefined}
        onDismiss={handleDismiss}
      >
        <div ref={childrenRef} tabIndex={-1}>
          {children}
        </div>
        {error && (
          <View as="div" margin="x-small 0 0">
            <ToggleDetails summary={I18n.t('Error details')} size="small">
              <View as="div" maxHeight="12rem" margin="x-small 0 0" overflowY="auto">
                <pre>
                  <code>{error}</code>
                </pre>
              </View>
            </ToggleDetails>
          </View>
        )}
      </Alert>
    </div>
  )
}
