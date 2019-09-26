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
  switch(type) {
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
