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

import {render} from '@canvas/react'
// TODO: use URL() in browser to parse URL
// eslint-disable-next-line import/no-nodejs-modules
import {parse} from 'url'
import ready from '@instructure/ready'
import {useScope as createI18nScope} from '@canvas/i18n'
import CanvasMediaPlayer from '@canvas/canvas-media-player'
import CanvasStudioPlayer from '@canvas/canvas-studio-player'
import {MediaInfo} from '@canvas/canvas-studio-player/react/types'
import {captionLanguageForLocale} from '@instructure/canvas-media'
import type {GlobalEnv} from '@canvas/global/env/GlobalEnv.d'
import {NoTranscript} from './components/NoTranscript'
import {isAsrGenerating} from './utils/isAsrGenerating'

import {createOnTranscriptEdit, onConfirmEditChanges} from './transcriptEditing'

declare const ENV: GlobalEnv & {
  media_object: MediaInfo
  attachment_id?: string
  attachment?: boolean
  current_user_roles?: string[]
  FEATURES: {
    consolidated_media_player_iframe?: boolean
  }
}

const I18n = createI18nScope('CanvasMediaPlayer')

const isStandalone = () => {
  return !window.frameElement && window.location === window?.top?.location
}

const isRceEditMode = () => {
  return window.parent.document.body.id === 'tinymce'
}

const addVerifier = (url: string, verifier: string | string[] | undefined): string => {
  if (Array.isArray(verifier)) verifier = verifier[0]
  if (typeof verifier == 'undefined') return url

  const parsedUrl = URL.parse(url)
  if (!parsedUrl) return url

  parsedUrl.searchParams.set('verifier', verifier)
  return parsedUrl.href
}

ready(() => {
  const container = document.getElementById('player_container')
  // get the media_id from something like
  //  `http://canvas.example.com/media_objects_iframe/m-48jGWTHdvcV5YPdZ9CKsqbtRzu1jURgu?type=video`
  // or
  //  `http://canvas.example.com/media_objects_iframe/?type=video&mediahref=url/to/file.mov`
  // or
  //  `http://canvas.example.com/media_attachments_iframe/12345678
  const media_id =
    ENV.media_object?.media_id || window.location.pathname.split('media_objects_iframe/').pop()
  const attachment_id = ENV.attachment_id
  const media_href_match = window.location.search.match(/mediahref=([^&]+)/)
  const media_object = ENV.media_object || {}
  const is_attachment = ENV.attachment
  const parsed_loc = parse(window.location.href, true)
  const is_video =
    /video/.test(media_object?.media_type) || /type=video/.test(window.location.search)
  let href_source

  if (media_href_match) {
    href_source = addVerifier(decodeURIComponent(media_href_match[1]), parsed_loc.query.verifier)

    if (is_video) {
      href_source = [href_source]
    }
  }

  const mediaTracks = media_object?.media_tracks?.map(track => {
    return {
      ...track,
      url: addVerifier(track.url, parsed_loc.query.verifier), // For CanvasStudioPlayer
      src: addVerifier(track.url, parsed_loc.query.verifier), // For CanvasMediaPlayer
      label: captionLanguageForLocale(track.locale),
      type: track.kind,
      language: track.locale,
      inherited: track.inherited,
    }
  })

  window.addEventListener(
    'message',
    event => {
      if (
        event?.data?.subject === 'reload_media' &&
        (media_id === event?.data?.media_object_id || attachment_id === event?.data?.attachment_id)
      ) {
        document.getElementsByTagName('video')[0].load()
        return
      }

      if (event?.data?.subject === 'media_tracks_request') {
        const tracks = mediaTracks?.map(t => ({
          locale: t.language,
          language: t.label,
          inherited: t.inherited,
          asr: t.asr,
          workflow_state: t.workflow_state,
        }))
        if (tracks) {
          event?.source?.postMessage(
            {subject: 'media_tracks_response', payload: tracks},
            {targetOrigin: event.origin},
          )
        }
        return
      }

      if (event.data?.subject === 'media_player.get_ready_state') {
        event.source?.postMessage(
          {
            subject: 'media_player.iframe_ready',
            mediaId: media_id,
          },
          {targetOrigin: event.origin},
        )
      }
    },
    false,
  )

  window?.top?.postMessage(
    {
      subject: 'media_player.iframe_ready',
      mediaId: media_id,
    },
    {targetOrigin: window?.top?.location.origin},
  )

  document.body.setAttribute('style', 'margin: 0; padding: 0; border-style: none')
  // if the user takes the video fullscreen and back, the documentElement winds up
  // with scrollbars, even though everything is the right size.
  document.documentElement.setAttribute('style', 'overflow: hidden;')
  const div = document.body.firstElementChild
  let explicitSize
  if (isStandalone()) {
    // we're standalone mode
    div?.setAttribute('style', 'width: 640px; max-width: 100%; margin: 16px auto;')
    explicitSize = {width: 640, height: 408}
  }

  const isAsrCaptioningImprovements = ENV.FEATURES?.rce_asr_captioning_improvements
  const isEditMode = isRceEditMode()
  const RCE_ENV = window.parent.parent.ENV

  const handleTranscriptEdit =
    isAsrCaptioningImprovements && isEditMode && attachment_id && RCE_ENV.JWT
      ? createOnTranscriptEdit(attachment_id, RCE_ENV.JWT)
      : undefined

  const handleConfirmEditChanges =
    isAsrCaptioningImprovements && isEditMode ? onConfirmEditChanges : undefined

  const aria_label = !media_object.title ? undefined : media_object.title
  const canManageTranscripts = (ENV.current_user_roles ?? []).some(
    r => r === 'teacher' || r === 'admin',
  )
  const isGenerating = isAsrGenerating(media_object?.media_tracks)
  // Get rid of processing state ASR tracks, since their content will be empty anyway.
  // append ASR track's label with "(Automatic)" to differentiate from human-created captions
  const playerTracks = mediaTracks
    ?.filter(t => !(t.asr && t.workflow_state === 'processing'))
    .map(t => (t.asr ? {...t, label: I18n.t('%{language} (Automatic)', {language: t.label})} : t))

  if (ENV.FEATURES?.consolidated_media_player_iframe) {
    render(
      <CanvasStudioPlayer
        media_id={media_id || ''}
        media_sources={href_source || media_object.media_sources}
        media_tracks={playerTracks}
        type={is_video ? 'video' : 'audio'}
        aria_label={aria_label}
        is_attachment={is_attachment}
        attachment_id={attachment_id}
        explicitSize={explicitSize}
        enableSidebar={isAsrCaptioningImprovements}
        openSidebar={isAsrCaptioningImprovements}
        onTranscriptEdit={handleTranscriptEdit}
        onConfirmEditChanges={handleConfirmEditChanges}
        kebabMenuElements={
          ENV.FEATURES?.rce_studio_embed_improvements
            ? [
                {
                  id: 'expand-view',
                  text: I18n.t('Expand View'),
                  showInOverlay: true,
                  overlayText: I18n.t('Expand'),
                  ariaLabel: I18n.t('Open immersive view with all media tools'),
                  icon: 'expand',
                  onClick: () => {
                    if (window.top) {
                      window.top.location.href = `/media_attachments/${attachment_id}/immersive_view`
                    }
                  },
                  order: 0,
                },
              ]
            : []
        }
        emptyTranscriptsComponent={
          isAsrCaptioningImprovements && is_video ? (
            <NoTranscript isGenerating={isGenerating} canManageTranscripts={canManageTranscripts} />
          ) : undefined
        }
      />,
      container,
    )
  } else {
    render(
      <CanvasMediaPlayer
        media_id={media_id || ''}
        media_sources={href_source || media_object.media_sources}
        media_tracks={mediaTracks}
        type={is_video ? 'video' : 'audio'}
        aria_label={aria_label}
        is_attachment={is_attachment}
        attachment_id={attachment_id}
      />,
      container,
    )
  }
})
