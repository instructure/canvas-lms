/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {useTranslation} from '@canvas/i18next'
import {Button} from '@instructure/ui-buttons'
import {CanvasModal} from '@instructure/platform-instui-bindings'
import {canvasErrorComponent} from '@canvas/error-page-utils'
import type {ContentShare} from '../types'

export interface PreviewModalProps {
  open?: boolean
  share?: ContentShare | null
  onDismiss?: () => void
}

export default function PreviewModal({
  open,
  share,
  onDismiss,
}: PreviewModalProps): React.JSX.Element {
  const {t} = useTranslation('content_share_preview_overlay')

  function sharePreviewUrl(): string | null {
    if (!share || !share.content_export?.attachment?.url) return null
    const downloadUrl = encodeURIComponent(share.content_export.attachment.url)
    // @ts-expect-error - COMMON_CARTRIDGE_VIEWER_URL not in GlobalEnv types
    return `${ENV.COMMON_CARTRIDGE_VIEWER_URL}?cartridge=${downloadUrl}`
  }

  function Footer(): React.JSX.Element {
    return <Button onClick={onDismiss}>{t('Close')}</Button>
  }

  return (
    <CanvasModal
      open={open}
      size="fullscreen"
      padding="0"
      closeButtonSize="medium"
      label={t('Preview')}
      footer={Footer}
      onDismiss={onDismiss}
      closeButtonLabel={t('Close')}
      errorComponent={canvasErrorComponent()}
    >
      <iframe
        style={{width: '100%', height: '100%', border: 'none', display: 'block'}}
        title={t('Content Share Preview')}
        src={sharePreviewUrl() || undefined}
      />
    </CanvasModal>
  )
}
