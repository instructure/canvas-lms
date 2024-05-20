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
import {
  anchorTag,
  type ContentItemIframe,
  type ContentItemThumbnail,
  iframeTag,
  linkBody,
} from './helpers'

export type LinkContentItem = {
  type: 'link'
  url: string
  title?: string
  text?: string
  icon?: string
  thumbnail?: ContentItemThumbnail
  iframe?: ContentItemIframe
  custom?: string
  lookup_uuid?: string
  errors?: Record<string, string>
}

export const linkContentItem = (item: {
  url: string
  title?: string
  text?: string
  icon?: string
  thumbnail?: ContentItemThumbnail
  iframe?: ContentItemIframe
  custom?: string
  lookup_uuid?: string
}): LinkContentItem => ({
  type: 'link',
  ...item,
})

export const linkContentItemToHtmlString = (item: LinkContentItem, selection?: string) => {
  if (item.iframe && item.iframe.src) {
    return iframeTag({
      title: item.title,
      iframe: item.iframe,
    })
  } else {
    const itemWithText =
      typeof selection === 'string' && selection !== ''
        ? {
            ...item,
            text: selection,
          }
        : item
    return anchorTag(itemWithText, linkBody(itemWithText))
  }
}
