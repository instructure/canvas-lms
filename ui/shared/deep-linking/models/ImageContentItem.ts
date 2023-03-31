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

import {anchorTag, imageTag, linkThumbnail} from './helpers'

export interface ImageContentItem {
  type: 'image'
  url: string
  title?: string
  thumbnail?: string
  text?: string
  width?: string | number
  height?: string | number
  errors?: Record<string, string>
}

export const imageContentItem = (options: {
  url: string
  title?: string
  thumbnail?: string
  text?: string
  width?: string | number
  height?: string | number
}): ImageContentItem => ({
  type: 'image',
  ...options,
})

export const imageContentItemToHtmlString = (item: ImageContentItem) => {
  if (typeof item.thumbnail !== 'undefined') {
    return anchorTag(item, linkThumbnail(item.thumbnail, item.text))
  } else {
    const {url, text, width, height} = item
    return imageTag(url, text, width, height)
  }
}
