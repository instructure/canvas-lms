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
import {parse} from 'url'
import ready from '@instructure/ready'
import CanvasMediaPlayer from './react/CanvasMediaPlayer'
import closedCaptionLanguages from '@canvas/util/closedCaptionLanguages'

ready(() => {
  // get the media_id from something like
  //  `http://canvas.example.com/media_objects_iframe/m-48jGWTHdvcV5YPdZ9CKsqbtRzu1jURgu?type=video`
  // or
  //  `http://canvas.example.com/media_objects_iframe/?type=video&mediahref=url/to/file.mov`
  const media_id = window.location.pathname.split('media_objects_iframe/').pop()
  const media_href_match = window.location.search.match(/mediahref=([^&]+)/)
  const media_object = ENV.media_object || {}
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

  document.body.setAttribute('style', 'margin: 0; padding: 0; border-style: none')
  // if the user takes the video fullscreen and back, the documentElement winds up
  // with scrollbars, even though everything is the right size.
  document.documentElement.setAttribute('style', 'overflow: hidden;')
  const div = document.body.firstElementChild
  if (!window.frameElement) {
    // we're standalone
    if (is_video) {
      // CanvasMediaPlayer leaves room for the 16px vertical margin.
      div.setAttribute('style', 'width: 640px; max-width: 100%; margin: 16px auto;')
    } else {
      div.setAttribute('style', 'width: 320px; height: 14.25rem; margin: 1rem auto;')
    }
  }

  const mediaTracks = media_object?.media_tracks?.map(track => {
    return {
      src: `/media_objects/${media_object.media_id}/media_tracks/${track.id}`,
      label: closedCaptionLanguages[track.locale] || track.locale,
      type: track.kind,
      language: track.locale
    }
  })

  ReactDOM.render(
    <CanvasMediaPlayer
      media_id={media_id}
      media_sources={href_source || media_object.media_sources}
      media_tracks={mediaTracks}
      type={is_video ? 'video' : 'audio'}
    />,
    document.getElementById('player_container')
  )
})
