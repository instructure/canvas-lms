/*
 * Copyright (C) 2013 - present Instructure, Inc.
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

import $ from 'jquery'
import '@canvas/media-comments'
import ready from '@instructure/ready'
import {createRoot} from 'react-dom/client'
import CanvasStudioPlayer from '@canvas/canvas-studio-player/react/CanvasStudioPlayer'

type MediaPlayerAttributes = {
  media_entry_id: string
  type: string
  attachment_id: string
  download_url: string
  bp_locked_attachment: boolean
}

function isConsolidatedMediaPlayerEnabled() {
  return ENV?.FEATURES?.consolidated_media_player
}

function renderCanvasMediaPlayer(domId: string, data: MediaPlayerAttributes) {
  $(`#${domId}`).mediaComment(
    'show_inline',
    data.media_entry_id || 'maybe',
    data.type,
    data.download_url,
    data.attachment_id,
    data.bp_locked_attachment,
  )
}

function renderStudioMediaPlayer(domId: string, data: MediaPlayerAttributes) {
  $(`#${domId}`).css({
    color: 'unset',
  })
  const root = createRoot(document.getElementById(domId)!)
  root.render(
    <CanvasStudioPlayer
      media_id={data.media_entry_id}
      type={data.type === 'audio' ? 'audio' : 'video'}
      attachment_id={data.attachment_id}
      explicitSize={{width: 550, height: 400}}
      hideUploadCaptions={data.bp_locked_attachment}
    />
  )
}

ready(() => {
  const domId = 'media_preview'
  const $preview = $(`#${domId}`)
  const data = $preview.data() as MediaPlayerAttributes

  if (isConsolidatedMediaPlayerEnabled()) {
    renderStudioMediaPlayer(domId, data)
  } else {
    renderCanvasMediaPlayer(domId, data)
  }

  if ((ENV as any)?.NEW_FILES_PREVIEW) {
    $preview.css({
      margin: '0',
      padding: '0',
      position: 'absolute',
      top: '50%',
      left: '50%',
      '-webkit-transform': 'translate(-50%, -50%)',
      transform: 'translate(-50%, -50%)',
    })
  }
})
