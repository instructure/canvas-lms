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

import {useEffect, useState} from 'react'

// TODO: for now keep in sync with packages/canvas-rce/src/rce/plugins/instructure_record/VideoOptionsTray/TrayController.js
export const DEFUALT_AUDIO_PLAYER_SIZE = {width: '300px', height: '2.813rem'}

export const DEFAULT_VIDEO_PLAYER_SIZE = {width: '300px', height: undefined}

// return the {playerWidth, playerHeight} based on the aspect ratio of the
// video file so that it fits w/in parentPanelRef
// Until @instructure/ui-media-player has an AudioPlayer, we're playing
// audio in the VideoPlayer, so we handle sizing that too.
export default function useSizeVideoPlayer(theFile, parentPanelRef, isLoading) {
  const [playerWidth, setPlayerWidth] = useState(DEFAULT_VIDEO_PLAYER_SIZE.width)
  const [playerHeight, setPlayerHeight] = useState(DEFAULT_VIDEO_PLAYER_SIZE.height)

  useEffect(() => {
    if (parentPanelRef.current && theFile) {
      if (isVideo(theFile.type)) {
        const player = parentPanelRef.current.querySelector('video')
        if (player) {
          const maxWidth = 0.75 * parentPanelRef.current.clientWidth
          if (player.loadedmetadata || player.readyState >= 1) {
            const width = sizeVideoPlayer(player, maxWidth)
            setPlayerWidth(width)
            setPlayerHeight(undefined)
          } else {
            player.addEventListener('loadedmetadata', () => {
              const width = sizeVideoPlayer(player, maxWidth)
              setPlayerWidth(width)
              setPlayerHeight(undefined)
            })
          }
        }
      } else if (isAudio(theFile.type)) {
        const player = parentPanelRef.current.querySelector('video')
        if (player) {
          setPlayerWidth(DEFUALT_AUDIO_PLAYER_SIZE.width)
          setPlayerHeight(DEFUALT_AUDIO_PLAYER_SIZE.height)
          player.style.height = DEFUALT_AUDIO_PLAYER_SIZE.height
        }
      }
    }
  }, [theFile, isLoading]) // eslint-disable-line react-hooks/exhaustive-deps

  return {playerWidth, playerHeight}
}

function isVideo(type) {
  return /^video/.test(type)
}

function isAudio(type) {
  return /^audio/.test(type)
}

// set the width of the video player such that the longest
// edge of the player is maxLen
export function sizeVideoPlayer(player, maxLen) {
  const width = player.videoWidth
  const height = player.videoHeight
  if (height > width) {
    return `${(maxLen / height) * width}px`
  } else {
    return `${maxLen}px`
  }
}
