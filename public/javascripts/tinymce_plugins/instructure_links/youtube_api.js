/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

export default class YouTubeApi {

  fetchYouTubeTitle (id, cb) {
    const jwt = ENV.JWT
    const appHost = ENV.RICH_CONTENT_APP_HOST
    const url = `//${appHost}/api/youtube_title?vid_id=${id}`
    $.ajax({
        headers: {Authorization: `Bearer ${jwt}`},
        url: url
      })
      .success((data) => {
        if (data.id === id) {
          cb(data.title)
        }
      })
      .error((err) => {
        cb(null, err)
      })
  }

  titleYouTubeText ($link) {
    const id = $.youTubeID($link.attr('href'))
    this.fetchYouTubeTitle(id, (vidTitle, err) => {
      if (err) {
        console.error(`failed to get video title from youtube for "${id}":`, err.responseText)
        const yttFailCnt = (+$link.attr('data-ytt-failcnt') || 0) + 1
        $link.attr('data-ytt-failcnt', yttFailCnt)
      } else {
        $link.text(vidTitle)
        $link.attr('data-preview-alt', vidTitle)
      }
    })
  }
}
