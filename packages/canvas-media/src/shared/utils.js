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

export const NON_PREVIEWABLE_TYPES = [
  'audio/x-ms-wma',
  'video/avi',
  'video/x-msvideo',
  'video/x-ms-wma',
  'video/x-ms-wmv'
]

export const isPreviewable = type => !NON_PREVIEWABLE_TYPES.includes(type)

export function isVideo(type) {
  return /^video/.test(type)
}

export function isAudio(type) {
  return /^audio/.test(type)
}

// return the desired size of the video player in CSS units
// constrained to the container's size
// If the container is larger than the video, will stretch it to fill
// the available space
export function sizeMediaPlayer(player, type, container) {
  if (isAudio(type)) {
    return AUDIO_PLAYER_SIZE
  }

  const sz = {
    width: player.videoWidth,
    height: player.videoHeight
  }
  if (container?.width && container?.height) {
    if (sz.width > sz.height) {
      sz.width = container.width
      sz.height = (player.videoHeight / player.videoWidth) * sz.width
    } else {
      sz.height = container.height
      sz.width = (player.videoWidth / player.videoHeight) * sz.height
    }

    if (sz.height > container.height) {
      sz.width *= container.height / sz.height
      sz.height = container.height
    }
  }

  sz.width = `${Math.round(sz.width)}px`
  sz.height = `${Math.round(sz.height)}px`
  return sz
}
