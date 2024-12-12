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

import React, {type CSSProperties, useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {MediaPreviewModal} from './MediaPreviewModal'
import {Link} from '@instructure/ui-link'
import {Spinner} from '@instructure/ui-spinner'

const I18n = createI18nScope('block-editor')

export const MediaBlockPreviewThumbnail = ({
  attachmentId,
  src,
  title,
  onThumbnailLoad,
}: {
  attachmentId?: string
  src: string
  title: string
  onThumbnailLoad: () => void
}) => {
  const [openMediaPreview, setOpenMediaPreview] = useState(false)
  const [isLoaded, setIsLoaded] = useState(false)

  if (!attachmentId) {
    return null
  }

  const loadingStyle = {
    position: 'absolute',
    left: 0,
    top: 0,
    width: '100%',
    textAlign: 'center',
  } as CSSProperties

  return (
    <div style={{position: 'relative'}}>
      {!isLoaded && (
        <div style={loadingStyle}>
          <Spinner renderTitle={I18n.t('Loading')} size="small" />
        </div>
      )}
      <img
        className="media_thumbnail"
        style={{width: `100%`}}
        src={`/media_attachments/${attachmentId}/thumbnail`}
        alt={title || I18n.t('Media thumbnail')}
        onLoad={_ => {
          setIsLoaded(true)
          onThumbnailLoad()
        }}
      />
      <Link
        onClick={() => {
          setOpenMediaPreview(true)
        }}
      >
        {isLoaded && (
          <img
            style={{
              left: 'calc(50% - 70px)',
              top: 'calc(50% - 50px)',
              position: 'absolute',
            }}
            src="/images/play_overlay.png"
            alt=""
          />
        )}
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
