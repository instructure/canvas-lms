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
import {bool, func} from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Button} from '@instructure/ui-buttons'
import CanvasModal from '@canvas/instui-bindings/react/Modal'
import contentShareShape from '@canvas/content-sharing/react/proptypes/contentShare'

const I18n = useI18nScope('content_share_preview_overlay')

PreviewModal.propTypes = {
  open: bool,
  share: contentShareShape,
  onDismiss: func,
}

export default function PreviewModal({open, share, onDismiss}) {
  function sharePreviewUrl() {
    if (!share) return null
    const downloadUrl = encodeURIComponent(share.content_export.attachment.url)
    return `${ENV.COMMON_CARTRIDGE_VIEWER_URL}?cartridge=${downloadUrl}`
  }

  function Footer() {
    return <Button onClick={onDismiss}>{I18n.t('Close')}</Button>
  }

  return (
    <CanvasModal
      open={open}
      size="fullscreen"
      padding="0"
      closeButtonSize="medium"
      label={I18n.t('Preview')}
      footer={Footer}
      onDismiss={onDismiss}
    >
      <iframe
        style={{width: '100%', height: '100%', border: 'none', display: 'block'}}
        title={I18n.t('Content Share Preview')}
        src={sharePreviewUrl()}
      />
    </CanvasModal>
  )
}
