/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {useScope as createI18nScope} from '@canvas/i18n'
import {Modal} from '@instructure/ui-modal'
import {CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import CanvasMediaPlayer from '@canvas/canvas-media-player'
import CanvasStudioPlayer from '@canvas/canvas-studio-player'
import {type GlobalEnv} from '@canvas/global/env/GlobalEnv'

const I18n = createI18nScope('block-editor')

declare const ENV: GlobalEnv & {FEATURES: {consolidated_media_player_iframe: boolean}}

export const MediaPreviewModal = ({
  open,
  attachmentId,
  close,
}: {
  open: boolean
  attachmentId: string
  close: () => void
}) => {
  return (
    <Modal open={open} onDismiss={close} label="Link" size="auto" variant="inverse">
      <Modal.Header>
        <Heading>{I18n.t('Media Preview')}</Heading>
        <CloseButton
          placement="end"
          onClick={close}
          screenReaderLabel="Close"
          color="primary-inverse"
        />
      </Modal.Header>
      <Modal.Body padding="none">
        <div>
          {ENV.FEATURES?.consolidated_media_player_iframe ? (
            <CanvasMediaPlayer type="video" is_attachment={true} attachment_id={attachmentId} />
          ) : (
            <CanvasStudioPlayer
              media_id=""
              type="video"
              is_attachment={true}
              attachment_id={attachmentId}
            />
          )}
        </div>
      </Modal.Body>
    </Modal>
  )
}
