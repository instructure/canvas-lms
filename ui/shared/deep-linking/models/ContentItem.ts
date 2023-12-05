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
  type ResourceLinkContentItem,
  resourceLinkContentItemToHtmlString,
} from './ResourceLinkContentItem'
import {
  type HtmlFragmentContentItem,
  htmlFragmentContentItemToHtmlString,
} from './HtmlFragmentContentItem'
import {type ImageContentItem, imageContentItemToHtmlString} from './ImageContentItem'
import {type LinkContentItem, linkContentItemToHtmlString} from './LinkContentItem'

export type ContentItem =
  | ResourceLinkContentItem
  | LinkContentItem
  | HtmlFragmentContentItem
  | ImageContentItem

const assertNever = (item: never): void => {
  // eslint-disable-next-line no-console
  console.error(`Could not process content item`, item)
}

export const contentItemToHtmlString =
  (context: {ltiEndpoint?: string; editorSelection?: string}) =>
  (item: ContentItem): string => {
    switch (item.type) {
      case 'html':
        return htmlFragmentContentItemToHtmlString(item)
      case 'image':
        return imageContentItemToHtmlString(item)
      case 'link':
        return linkContentItemToHtmlString(item, context.editorSelection)
      case 'ltiResourceLink':
        return resourceLinkContentItemToHtmlString(
          item,
          context.ltiEndpoint,
          context.editorSelection
        )
      default:
        assertNever(item)
        return ''
    }
  }
