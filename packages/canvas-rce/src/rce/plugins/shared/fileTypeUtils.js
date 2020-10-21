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

import {parse} from 'url'
import {
  IconDocumentLine,
  IconMsExcelLine,
  IconMsPptLine,
  IconMsWordLine,
  IconPdfLine,
  IconVideoLine,
  IconAudioLine
} from '@instructure/ui-icons'

export function getIconFromType(type) {
  if (isVideo(type)) {
    return IconVideoLine
  } else if (isAudio(type)) {
    return IconAudioLine
  }
  switch (type) {
    case 'application/msword':
    case 'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
      return IconMsWordLine
    case 'application/vnd.ms-powerpoint':
    case 'application/vnd.openxmlformats-officedocument.presentationml.presentation':
      return IconMsPptLine
    case 'application/pdf':
      return IconPdfLine
    case 'application/vnd.ms-excel':
    case 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet':
      return IconMsExcelLine
    default:
      return IconDocumentLine
  }
}

export function isImage(type) {
  return /^image/.test(type)
}

export function isAudioOrVideo(type) {
  return isVideo(type) || isAudio(type)
}

export function isVideo(type) {
  return /^video/.test(type)
}

export function isAudio(type) {
  return /^audio/.test(type)
}

export function isText(type) {
  return /^text/.test(type)
}

export function mediaPlayerURLFromFile(file) {
  // why oh why aren't we consistent?
  const content_type = file['content-type'] || file.content_type || file.type
  const type = content_type.replace(/\/.*$/, '')

  if (file.embedded_iframe_url) {
    return `${file.embedded_iframe_url}?type=${type}`
  }

  if (isAudioOrVideo(content_type)) {
    if (file.media_entry_id && file.media_entry_id !== 'maybe') {
      return `/media_objects_iframe/${file.media_entry_id}?type=${type}`
    }

    const parsed_url = parse(file.url || file.href, true)
    const verifier = parsed_url.query.verifier ? `&verifier=${parsed_url.query.verifier}` : ''
    return `/media_objects_iframe?mediahref=${parsed_url.pathname}${verifier}&type=${type}`
  }
  return undefined
}
