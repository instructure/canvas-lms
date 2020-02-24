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
import ready from '@instructure/ready'
import CanvasMediaPlayer from '../shared/media/CanvasMediaPlayer'
import closedCaptionLanguages from '../shared/closedCaptionLanguages'

ready(() => {
  // get the media_id from something like
  //  `http://canvas.example.com/media_objects_iframe/m-48jGWTHdvcV5YPdZ9CKsqbtRzu1jURgu`
  // or
  //  `http://canvas.example.com/media_objects_iframe/?href=http://url/to/file.mov`
  const media_id = window.location.pathname.split('media_objects_iframe/').pop()
  const media_href_match = window.location.search.match(/mediahref=([^&]+)/)
  const is_audio = /type=audio/.test(window.location.search)
  let type = is_audio ? 'audio' : 'video'
  let href_source

  if (media_href_match) {
    if (is_audio) {
      type = 'audio'
      href_source = decodeURIComponent(media_href_match[1])
    } else {
      href_source = [decodeURIComponent(media_href_match[1])]
    }
  }

  document.body.setAttribute('style', 'margin: 0; padding: 0; border-style: none')

  const div = document.body.firstElementChild
  const media_object = ENV.media_object || {}

  const mediaTracks = media_object?.media_tracks.map(track => {
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
      type={type}
    />,
    document.body.appendChild(div)
  )
})
