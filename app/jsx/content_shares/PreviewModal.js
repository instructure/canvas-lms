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
import I18n from 'i18n!content_share_preview_overlay'
import {Button} from '@instructure/ui-buttons'
import CanvasModal from 'jsx/shared/components/CanvasModal'

export default function PreviewModal({open, onDismiss}) {
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
        src={ENV.COMMON_CARTRIDGE_VIEWER_URL}
      />
    </CanvasModal>
  )
}
