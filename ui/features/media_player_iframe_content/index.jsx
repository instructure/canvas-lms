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
import ReactDOM from 'react-dom'
// TODO: use URL() in browser to parse URL
// eslint-disable-next-line import/no-nodejs-modules
import {parse} from 'url'
import ready from '@instructure/ready'
import CanvasMediaPlayer from '@canvas/canvas-media-player'
import {captionLanguageForLocale} from '@instructure/canvas-media'

const isStandalone = () => {
  return !window.frameElement && window.location === window.top.location
}

ready(() => {
  // get the media_id from something like
  //  `http://canvas.example.com/media_objects_iframe/m-48jGWTHdvcV5YPdZ9CKsqbtRzu1jURgu?type=video`
  // or
  //  `http://canvas.example.com/media_objects_iframe/?type=video&mediahref=url/to/file.mov`
  // or
  //  `http://canvas.example.com/media_attachments_iframe/12345678
  let media_id = window.location.pathname.split('media_objects_iframe/').pop()
  // This covers a timing issue between canvas/RCE when the media_links_use_attachment flag is flipped off
  if (media_id?.includes('media_attachments_iframe') && ENV?.media_object?.media_id) {
    media_id = ENV.media_object.media_id
  }
  const attachment_id = ENV.attachment_id
  const media_href_match = window.location.search.match(/mediahref=([^&]+)/)
  const media_object = ENV.media_object || {}
  const is_attachment = ENV.attachment
  const parsed_loc = parse(window.location.href, true)
  const is_video =
    /video/.test(media_object?.media_type) || /type=video/.test(window.location.search)
  let href_source

  if (media_href_match) {
    href_source = decodeURIComponent(media_href_match[1])
    if (parsed_loc.query.verifier) {
      const delim = href_source.indexOf('?') > 0 ? '&' : '?'
      href_source = `${href_source}${delim}verifier=${parsed_loc.query.verifier}`
    }

    if (is_video) {
      href_source = [href_source]
    }
  }

  const mediaTracks = media_object?.media_tracks?.map(track => {
    return {
      id: track.id,
      src: track.url,
      label: captionLanguageForLocale(track.locale),
      type: track.kind,
      language: track.locale,
      inherited: track.inherited,
    }
  })

  window.addEventListener(
    'message',
    event => {
      if (event?.data?.subject === 'reload_media' && media_id === event?.data?.media_object_id) {
        document.getElementsByTagName('video')[0].load()
      } else if (event?.data?.subject === 'media_tracks_request') {
        const tracks = mediaTracks?.map(t => ({
          locale: t.language,
          language: t.label,
          inherited: t.inherited,
        }))
        if (tracks)
          event.source.postMessage(
            {subject: 'media_tracks_response', payload: tracks},
            event.origin
          )
      }
    },
    false
  )

  document.body.setAttribute('style', 'margin: 0; padding: 0; border-style: none')
  // if the user takes the video fullscreen and back, the documentElement winds up
  // with scrollbars, even though everything is the right size.
  document.documentElement.setAttribute('style', 'overflow: hidden;')
  const div = document.body.firstElementChild
  if (isStandalone()) {
    // we're standalone mode
    if (is_video) {
      // CanvasMediaPlayer leaves room for the 16px vertical margin.
      div.setAttribute('style', 'width: 640px; max-width: 100%; margin: 16px auto;')
    } else {
      div.setAttribute('style', 'width: 320px; height: 14.25rem; margin: 1rem auto;')
    }
  }

  const aria_label = !media_object.title ? undefined : media_object.title
  ReactDOM.render(
    <CanvasMediaPlayer
      media_id={media_id}
      media_sources={href_source || media_object.media_sources}
      media_tracks={mediaTracks}
      type={is_video ? 'video' : 'audio'}
      aria_label={aria_label}
      is_attachment={is_attachment}
      attachment_id={attachment_id}
    />,
    document.getElementById('player_container')
  )
})
