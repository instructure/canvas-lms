/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import React from 'react'
import {Overlay, Mask} from '@instructure/ui-overlays'
import {Spinner} from '@instructure/ui-spinner'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('differentiated_modules')

export interface LoadingOverlayProps {
  showLoadingOverlay: boolean
  mountNode: HTMLElement | null
}

export default function LoadingOverlay({showLoadingOverlay, mountNode}: LoadingOverlayProps) {
  return (
    <Overlay
      data-testid="loading-overlay"
      open={showLoadingOverlay}
      transition="fade"
      label={I18n.t('Loading')}
      mountNode={mountNode}
    >
      <Mask>
        <Spinner renderTitle="Loading" size="large" margin="0 0 0 medium" />
      </Mask>
    </Overlay>
  )
}
