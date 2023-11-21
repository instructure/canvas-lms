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

import {format, parse} from 'url'
import {absoluteToRelativeUrl} from '../../../common/fileUrl'
import {
  IconAudioLine,
  IconDocumentLine,
  IconMsExcelLine,
  IconMsPptLine,
  IconMsWordLine,
  IconPdfLine,
  IconVideoLine,
} from '@instructure/ui-icons'
import RCEGlobals from '../../RCEGlobals'

export function getIconFromType(type) {
  if (isVideo(type)) {
    return IconVideoLine
  } else if (isAudio(type)) {
    return IconAudioLine
  }
  switch (type) {
    case 'application/msword':
    case 'application/vnd.apple.pages':
    case 'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
      return IconMsWordLine
    case 'application/vnd.ms-powerpoint':
    case 'application/vnd.apple.keynote':
    case 'application/vnd.openxmlformats-officedocument.presentationml.presentation':
      return IconMsPptLine
    case 'application/pdf':
      return IconPdfLine
    case 'application/vnd.ms-excel':
    case 'application/vnd.apple.numbers':
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

export function isIWork(filename) {
  return [/.pages$/i, /.key$/i, /.numbers$/i].some(regex => regex.test(filename))
}

export function getIWorkType(filename) {
  const tokens = filename.split('.')
  if (tokens.length <= 1) return ''
  const lastToken = tokens[tokens.length - 1]
  switch (lastToken.toLowerCase()) {
    case 'pages':
      return 'application/vnd.apple.pages'
    case 'key':
      return 'application/vnd.apple.keynote'
    case 'numbers':
      return 'application/vnd.apple.numbers'
    default:
      return ''
  }
}

export function mediaPlayerURLFromFile(file, canvasOrigin) {
  // why oh why aren't we consistent?
  const content_type = file['content-type'] || file.content_type || file.type
  const type = content_type.replace(/\/.*$/, '')

  if (
    RCEGlobals.getFeatures()?.media_links_use_attachment_id &&
    isAudioOrVideo(content_type) &&
    file.id
  ) {
    const url = parse(`/media_attachments_iframe/${file.id}`, true)
    url.query.type = type
    url.query.embedded = true
    if (file.uuid && file.contextType == 'User') {
      url.query.verifier = file.uuid
    } else if (file.url || file.href) {
      const parsed_url = parse(file.url || file.href, true)
      if (parsed_url.query.verifier) {
        url.query.verifier = parsed_url.query.verifier
      }
    }
    return format(url)
  }

  if (file.embedded_iframe_url) {
    const url = new URL(file.embedded_iframe_url, canvasOrigin)

    if (url.searchParams.has('type')) {
      return `${absoluteToRelativeUrl(file.embedded_iframe_url, canvasOrigin)}`
    }

    return `${absoluteToRelativeUrl(file.embedded_iframe_url, canvasOrigin)}?type=${type}`
  }

  if (isAudioOrVideo(content_type)) {
    const mediaEntryId = file.media_entry_id || file.embed?.id || file.mediaEntryId

    if (mediaEntryId && mediaEntryId !== 'maybe') {
      return `/media_objects_iframe/${mediaEntryId}?type=${type}`
    }

    const parsed_url = parse(file.url || file.href, true)
    const verifier = parsed_url.query.verifier ? `&verifier=${parsed_url.query.verifier}` : ''
    return `/media_objects_iframe?mediahref=${parsed_url.pathname}${verifier}&type=${type}`
  }
  return undefined
}
