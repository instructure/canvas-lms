/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import {Mask, Overlay} from '@instructure/ui-overlays'
import {Spinner} from '@instructure/ui-spinner'
import {useRef} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import type {LoadingSaveOverlayProps} from '../types'

const I18n = createI18nScope('discovery_page')

export function LoadingSaveOverlay({
  isLoading,
  isLoadingConfig,
  mountNode,
}: LoadingSaveOverlayProps) {
  const maskRef = useRef<Element | null>(null)

  const renderTitle = isLoadingConfig
    ? I18n.t('Loading configuration')
    : I18n.t('Saving configuration')

  return (
    <Overlay
      data-testid="loading-save-overlay"
      defaultFocusElement={() => maskRef.current}
      label={renderTitle}
      mountNode={mountNode}
      open={isLoading}
      shouldCloseOnEscape={false}
      shouldContainFocus={true}
      transition="fade"
    >
      <Mask
        elementRef={el => {
          maskRef.current = el
        }}
      >
        <Spinner renderTitle={renderTitle} size="large" margin="0 0 0 medium" />
      </Mask>
    </Overlay>
  )
}
