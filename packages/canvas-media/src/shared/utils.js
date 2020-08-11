/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

export const AUDIO_PLAYER_SIZE = {width: '320px', height: '14.25rem'}

export function isVideo(type) {
  return /^video/.test(type)
}

export function isAudio(type) {
  return /^audio/.test(type)
}

// return the desired size of the video player in CSS units
// constrained to the container's size
// Note: Landscape videos are not constrained to the container's height
//       This is because if the player is in a window, and the window
//       resizes wider, the container div gets wider, but the height
//       doesn't grow, so we let the video grow, which will expand its
//       container's height. This works for the media player use-case
//       where the player is either in an iframe with the correct aspect
//       ratio anyway, or is in window.top
export function sizeMediaPlayer(player, type, container, expandToFill) {
  if (isAudio(type)) {
    return AUDIO_PLAYER_SIZE
  }

  const sz = {
    width: player.videoWidth,
    height: player.videoHeight
  }
  if (expandToFill) {
    if (sz.width > sz.height) {
      sz.width = container.width
      sz.height = (player.videoHeight / player.videoWidth) * sz.width
    } else {
      sz.height = container.height
      sz.width = (player.videoWidth / player.videoHeight) * sz.height
    }
  } else {
    // scale the player so it does not overflow its container
    if (sz.width > container.width) {
      const wscale = container.width / sz.width
      sz.width *= wscale
      sz.height *= wscale
    }
    // if is a portrait video, may have to scale the height
    if (sz.height > sz.width && sz.height > container.height) {
      const hscale = container.height / sz.height
      sz.width *= hscale
      sz.height *= hscale
    }
  }

  sz.width = `${Math.round(sz.width)}px`
  sz.height = `${Math.round(sz.height)}px`
  return sz
}
