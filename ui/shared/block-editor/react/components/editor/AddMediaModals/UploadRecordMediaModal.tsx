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
import UploadMedia from '@instructure/canvas-media'
import {
  UploadMediaStrings,
  MediaCaptureStrings,
  SelectStrings,
} from '@canvas/upload-media-translations'
import {useScope as createI18nScope} from '@canvas/i18n'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {type GlobalEnv} from '@canvas/global/env/GlobalEnv'

const I18n = createI18nScope('block-editor')

declare const ENV: GlobalEnv

export function UploadRecordMediaModal({
  open,
  onSubmit,
  onDismiss,
}: {
  open: boolean
  onSubmit: ({attachment_id, iframe_url}: {attachment_id?: string; iframe_url?: string}) => void
  onDismiss: () => void
}) {
  return (
    <>
      <UploadMedia
        onUploadComplete={(err: any, data: any) => {
          if (err) {
            return showFlashError(I18n.t('Media upload failed'))(err)
          }
          onSubmit({
            attachment_id: data.mediaObject.media_object.attachment_id,
            iframe_url: data.mediaObject.embedded_iframe_url,
          })
        }}
        onDismiss={onDismiss}
        rcsConfig={{
          contextId: ENV.current_context?.id,
          contextType: ENV.current_context?.type,
        }}
        open={open}
        tabs={{record: true, upload: true}}
        uploadMediaTranslations={{UploadMediaStrings, MediaCaptureStrings, SelectStrings}}
        liveRegion={() => document.getElementById('flash_screenreader_holder')}
        userLocale={ENV.LOCALE}
      />
    </>
  )
}
