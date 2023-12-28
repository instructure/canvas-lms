//
// Copyright (C) 2021 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import mime from 'mime/lite'

export const extensionFromString = string => {
  const ext = string?.split('.')?.pop()?.split('?')?.shift()
  return mime.getType(ext) != null ? ext : null
}

export const findContentExtension = contentItem =>
  (contentItem?.mediaType && mime.getExtension(contentItem.mediaType)) ||
  extensionFromString(contentItem.url) ||
  extensionFromString(contentItem.title) ||
  extensionFromString(contentItem.text)
