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

import React, {useState} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {MediaPreviewModal} from './MediaPreviewModal'
import {Link} from '@instructure/ui-link'

const I18n = useI18nScope('block-editor/media-block')

export const MediaBlockPreviewThumbnail = ({
  attachmentId,
  src,
  title,
}: {
  attachmentId?: string
  src: string
  title: string
}) => {
  const [openMediaPreview, setOpenMediaPreview] = useState(false)

  if (!attachmentId) {
    return null
  }

  return (
    <div style={{position: 'relative'}}>
      <img
        style={{width: '320px', minHeight: '100px'}}
        src={`/media_attachments/${attachmentId}/thumbnail`}
        alt={title || I18n.t('Media thumbnail')}
      />
      <Link
        onClick={() => {
          setOpenMediaPreview(true)
        }}
      >
        <img
          style={{
            left: 'calc(50% - 70px)',
            top: 'calc(50% - 50px)',
            position: 'absolute',
          }}
          src="/images/play_overlay.png"
          alt=""
        />
      </Link>
      <iframe style={{display: 'none'}} title={title || ''} src={src} />
      <MediaPreviewModal
        open={openMediaPreview}
        attachmentId={attachmentId}
        close={() => {
          setOpenMediaPreview(false)
        }}
      />
    </div>
  )
}
