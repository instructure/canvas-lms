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
import {type Node} from '@craftjs/core'
import VideoOptionsTray from '@instructure/canvas-rce/es/rce/plugins/instructure_record/VideoOptionsTray/index'
import {saveClosedCaptionsForAttachment} from '@instructure/canvas-media'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {type MediaBlockProps} from './types'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'

import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('block-editor')

export default function BlockEditorVideoOptionsTray({
  open,
  node,
  setOpenTray,
  setProp,
}: {
  open: boolean
  node: Node
  setOpenTray: (args: boolean) => void
  setProp: (args: any) => void
}) {
  const videoContainer = node?.dom?.querySelector('iframe')
  const _subtitleListener = new AbortController()

  let attachmentId: string

  if (videoContainer) {
    attachmentId = videoContainer
      .getAttribute('src')
      ?.match(/\/media_attachments_iframe\/(\d+)/)?.[1] as string
  }

  const applyOptions = ({titleText, subtitles}: {titleText: string; subtitles: any[]}) => {
    videoContainer?.setAttribute('title', titleText)

    doFetchApi({
      path: `/api/v1/media_attachments/${attachmentId}?user_entered_title=${encodeURIComponent(
        titleText,
      )}`,
      method: 'PUT',
      headers: {'Content-Type': 'application/json'},
    })
      .then(() => {
        saveClosedCaptionsForAttachment(attachmentId as string, subtitles, {}, null)
        setProp((prps: MediaBlockProps) => {
          prps.title = titleText || undefined
        })
        // @ts-expect-error
        videoContainer?.contentWindow.location.reload()
        setOpenTray(false)
      })
      .catch((err: Error) => {
        showFlashError(I18n.t('Could not save media info'))(err)
      })
  }

  const requestSubtitlesFromIframe = (cb: any) => {
    window.addEventListener(
      'message',
      event => {
        if (event?.data?.subject === 'media_tracks_response') {
          cb(event?.data?.payload)
        }
      },
      {signal: _subtitleListener.signal},
    )

    videoContainer?.contentWindow?.postMessage(
      {subject: 'media_tracks_request'},
      window.location.toString(),
    )
  }

  return (
    open && (
      <VideoOptionsTray
        open={open}
        onRequestClose={() => {
          setOpenTray(false)
        }}
        onSave={onSaveProps => {
          applyOptions(onSaveProps)
        }}
        // @ts-expect-error
        trayProps={{}}
        // @ts-expect-error
        videoOptions={{
          titleText: videoContainer?.getAttribute('title') || '',
        }}
        // @ts-expect-error
        requestSubtitlesFromIframe={(cb: any) => requestSubtitlesFromIframe(cb)}
        forBlockEditorUse={true}
      />
    )
  )
}
