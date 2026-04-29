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

function validateAndExtractYouTubeUrl(input) {
  if (!input || typeof input !== 'string') {
    return {isValid: false, embedUrl: null}
  }

  const trimmedInput = input.trim()

  const patterns = [
    /^(?:https?:\/\/)?(?:www\.|m\.)?(?:youtube\.com\/watch\?v=|youtu\.be\/)([a-zA-Z0-9_-]+)(?:[&?][^\s]*)?$/,
    /^(?:https?:\/\/)?(?:www\.)?youtube\.com\/embed\/([a-zA-Z0-9_-]+)(?:[?][^\s]*)?$/,
    /<iframe[^>]*src=["'](?:https?:\/\/)?(?:www\.)?youtube\.com\/embed\/([a-zA-Z0-9_-]+)[^"']*["'][^>]*>/,
  ]

  for (const pattern of patterns) {
    const match = trimmedInput.match(pattern)
    if (match && match[1]) {
      const videoId = match[1]
      return {
        isValid: true,
        embedUrl: `https://www.youtube.com/embed/${videoId}`,
      }
    }
  }

  return {isValid: false, embedUrl: null}
}

export function validateVideoUrl(input) {
  if (!input || typeof input !== 'string') {
    return {isValid: false, embedUrl: null}
  }

  const youTubeRegexp = /(?:https?:\/\/)?(?:www\.|m\.)?(?:youtube\.com|youtu\.be)/i
  if (youTubeRegexp.test(input)) {
    return validateAndExtractYouTubeUrl(input)
  }

  return {isValid: false, embedUrl: null}
}
