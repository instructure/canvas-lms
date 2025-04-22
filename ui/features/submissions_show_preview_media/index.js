//
// Copyright (C) 2014 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import $ from 'jquery'
import '@canvas/media-comments'
import CanvasStudioPlayer from '@canvas/canvas-studio-player'
import React from 'react'
import {createRoot} from 'react-dom/client'

function isConsolidatedMediaPlayerEnabled() {
  return ENV?.FEATURES?.consolidated_media_player
}

function renderStudioMediaPlayer(domId, media_id, type) {
  const root = createRoot(document.getElementById(domId))
  root?.render(
    React.createElement(CanvasStudioPlayer, {
      media_id: media_id,
      type: type === 'audio' ? 'audio' : 'video',
      explicitSize: {width: 480, height: 300},
    }),
  )
}

$(document).ready(() => {
  $('.play_media_recording_link').click(function (event) {
    event.preventDefault()
    const id = $('.media_comment_id:first').text()

    if (isConsolidatedMediaPlayerEnabled()) {
      const type = $('.play_media_recording_link').data('media_comment_type')
      const domId = 'box_content'

      renderStudioMediaPlayer(domId, id, type)
    } else {
      $('#media_recording_box .box_content').mediaComment('show_inline', id)
    }
    $(this).remove()
  })

  $('.play_media_recording_link').mediaCommentThumbnail()

  if (ENV.FEATURES?.discussion_checkpoints) {
    $('#discussion_temporary_toggle').click(function (event) {
      event.preventDefault()
      window.parent.postMessage(
        {
          subject: 'SG.switchToFullContext',
        },
        '*',
      )
    })
  }

  function getEntryId(str) {
    const match = str.match(/entryId=([^&]+)$/)
    return match ? match[1] : null
  }

  if (ENV.FEATURES?.discussion_checkpoints) {
    $("a[id^='discussion_link_entryId']").click(function (event) {
      const entryId = getEntryId(event.target.id)
      if (entryId) {
        window.parent.postMessage(
          {
            subject: `SG.switchToFullContext&entryId=${entryId}`,
          },
          '*',
        )
      }
    })
  }

  const discussionPreviewIframe = $('#discussion_preview_iframe')
  discussionPreviewIframe.on('load', function () {
    const iframeWindow = discussionPreviewIframe[0].contentWindow
    if (iframeWindow) {
      iframeWindow.addEventListener('message', function (event) {
        if (event.data && event.data.subject === 'SG.switchToIndividualPosts') {
          window.parent.postMessage(
            {
              subject: 'SG.switchToIndividualPosts',
            },
            '*',
          )
        }
      })
    }
  })
})
