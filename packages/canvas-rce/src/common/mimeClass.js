/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

export function fileEmbed(file) {
  const fileMimeClass = mimeClass(file)

  if (fileMimeClass === 'image') {
    return {type: 'image'}
  } else if (fileMimeClass === 'video' || fileMimeClass === 'audio') {
    return {type: fileMimeClass}
  } else if (file.preview_url) {
    return {type: 'scribd'}
  } else {
    return {type: 'file'}
  }
}

export function mimeClass(file) {
  if (file.mime_class) {
    return file.mime_class
  } else {
    const contentType = getContentType(file)
    // NOTE: Keep this list in sync with what's in canvas-lms/app/models/attachment.rb
    return contentMapping(contentType) || file.mime_class || 'file'
  }
}

export function contentMapping(contentType) {
  return {
    'text/html': 'html',
    'text/x-csharp': 'code',
    'text/xml': 'code',
    'text/css': 'code',
    text: 'text',
    'text/plain': 'text',
    'application/rtf': 'doc',
    'text/rtf': 'doc',
    'application/vnd.oasis.opendocument.text': 'doc',
    'application/pdf': 'pdf',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document': 'doc',
    'application/vnd.apple.pages': 'doc',
    'application/x-docx': 'doc',
    'application/msword': 'doc',
    'application/vnd.ms-powerpoint': 'ppt',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation': 'ppt',
    'applicatoin/vnd.apple.key': 'ppt',
    'application/vnd.ms-excel': 'xls',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet': 'xls',
    'application/vnd.apple.numbers': 'xls',
    'application/vnd.oasis.opendocument.spreadsheet': 'xls',
    'image/jpeg': 'image',
    'image/pjpeg': 'image',
    'image/png': 'image',
    'image/gif': 'image',
    'image/bmp': 'image',
    'image/svg+xml': 'image',
    'image/webp': 'image',
    'application/x-rar': 'zip',
    'application/x-rar-compressed': 'zip',
    'application/x-zip': 'zip',
    'application/x-zip-compressed': 'zip',
    'application/xml': 'code',
    'application/zip': 'zip',
    'audio/mp3': 'audio',
    'audio/mpeg': 'audio',
    'audio/basic': 'audio',
    'audio/mid': 'audio',
    'audio/3gpp': 'audio',
    'audio/x-aiff': 'audio',
    'audio/x-m4a': 'audio',
    'audio/x-mpegurl': 'audio',
    'audio/x-ms-wma': 'audio',
    'audio/x-pn-realaudio': 'audio',
    'audio/x-wav': 'audio',
    'audio/mp4': 'audio',
    'audio/wav': 'audio',
    'audio/webm': 'audio',
    'audio/*': 'audio',
    audio: 'audio',
    'video/mpeg': 'video',
    'video/quicktime': 'video',
    'video/x-la-asf': 'video',
    'video/x-ms-asf': 'video',
    'video/x-ms-wma': 'audio',
    'video/x-ms-wmv': 'video',
    'video/x-msvideo': 'video',
    'video/x-sgi-movie': 'video',
    'video/3gpp': 'video',
    'video/mp4': 'video',
    'video/webm': 'video',
    'video/avi': 'video',
    'video/*': 'video',
    video: 'video',
    'application/x-shockwave-flash': 'flash',
  }[contentType]
}

function getContentType(file) {
  return file['content-type'] || file.content_type || file.type
}
