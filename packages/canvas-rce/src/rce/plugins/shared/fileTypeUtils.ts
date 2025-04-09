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
import RCEGlobals, {type Features} from '../../RCEGlobals'

type FileType = {
  'content-type'?: string
  content_type?: string
  contextId?: string
  contextType?: string
  embed?: {
    id: string
  }
  embedded_iframe_url?: string
  href?: string
  id?: string
  media_entry_id?: string
  mediaEntryId?: string
  type?: string
  url?: string
  uuid?: string
}

export function getIconFromType(type: string) {
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

export function isImage(type: string) {
  return /^image/.test(type)
}

export function isAudioOrVideo(type: string) {
  return isVideo(type) || isAudio(type)
}

export function isVideo(type: string) {
  return /^video/.test(type)
}

export function isAudio(type: string) {
  return /^audio/.test(type)
}

export function isText(type: string) {
  return /^text/.test(type)
}

export function isIWork(filename: string) {
  return [/.pages$/i, /.key$/i, /.numbers$/i].some(regex => regex.test(filename))
}

export function getIWorkType(filename: string) {
  const tokens = filename.split('.')
  if (tokens.length <= 1) return ''
  const lastToken = tokens[tokens.length - 1].toLowerCase()
  switch (lastToken) {
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

export function mediaPlayerURLFromFile(file: FileType, canvasOrigin?: string) {
  // why oh why aren't we consistent?
  const content_type = file['content-type'] || file.content_type || file.type
  if (typeof content_type !== 'string') throw new Error('Invalid content type')

  const type = content_type.replace(/\/.*$/, '')
  const baseOrigin = canvasOrigin ?? window.location.origin

  if (isAudioOrVideo(content_type) && file.id) {
    const url = new URL(`/media_attachments_iframe/${file.id}`, baseOrigin)
    url.searchParams.set('type', type)
    url.searchParams.set('embedded', 'true')

    if (
      file.uuid &&
      (file.contextType === 'User' ||
        (canvasOrigin &&
          canvasOrigin !== window.location.origin &&
          RCEGlobals.getFeatures()?.file_verifiers_for_quiz_links))
    ) {
      url.searchParams.set('verifier', file.uuid)
    } else if (file.url || file.href) {
      const href = file.url || file.href
      if (typeof href !== 'string') {
        throw new Error('Invalid URL')
      }
      const parsedUrl = new URL(href, baseOrigin)
      const verifier = parsedUrl.searchParams.get('verifier')
      if (verifier) {
        url.searchParams.set('verifier', verifier)
      }
    }

    return url.toString().replace(baseOrigin, '')
  }

  if (file.embedded_iframe_url) {
    const embedUrl = new URL(file.embedded_iframe_url, baseOrigin)
    if (embedUrl.searchParams.has('type')) {
      return absoluteToRelativeUrl(file.embedded_iframe_url, canvasOrigin)
    }
    const relative = absoluteToRelativeUrl(file.embedded_iframe_url, canvasOrigin)
    return `${relative}?type=${type}`
  }

  if (isAudioOrVideo(content_type)) {
    const mediaEntryId = file.media_entry_id || file.embed?.id || file.mediaEntryId
    if (mediaEntryId && mediaEntryId !== 'maybe') {
      return `/media_objects_iframe/${mediaEntryId}?type=${type}`
    }

    const href = file.url || file.href
    if (typeof href !== 'string') {
      throw new Error('Invalid URL')
    }
    const parsedUrl = new URL(href, baseOrigin)
    const verifier = parsedUrl.searchParams.get('verifier')
    const verifierParam = verifier ? `&verifier=${verifier}` : ''
    return `/media_objects_iframe?mediahref=${parsedUrl.pathname}${verifierParam}&type=${type}`
  }

  return undefined
}
