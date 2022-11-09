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

// copied from canvas-lms/ui/shared/features/doc-previews/jquery/index.js
export const previewableMimeTypes = [
  'application/vnd.openxmlformats-officedocument.wordprocessingml.template',
  'application/vnd.oasis.opendocument.spreadsheet',
  'application/vnd.sun.xml.writer',
  'application/excel',
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'text/rtf',
  'application/vnd.openxmlformats-officedocument.spreadsheetml.template',
  'application/vnd.sun.xml.impress',
  'application/vnd.sun.xml.calc',
  'application/vnd.ms-excel',
  'application/msword',
  'application/mspowerpoint',
  'application/rtf',
  'application/vnd.oasis.opendocument.presentation',
  'application/vnd.oasis.opendocument.text',
  'application/vnd.openxmlformats-officedocument.presentationml.template',
  'application/vnd.openxmlformats-officedocument.presentationml.slideshow',
  'text/plain',
  'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'application/postscript',
  'application/pdf',
  'application/vnd.ms-powerpoint',
]

export function isPreviewable(type) {
  return previewableMimeTypes.includes(type)
}
