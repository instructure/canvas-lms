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
import {anchorTag, type ContentItemIframe, iframeTag, linkBody, safeUrl} from './helpers'

export type ResourceLinkContentItem = {
  type: 'ltiResourceLink'
  url: string
  custom?: Record<string, string>
  window?: {targetName: string}
  lookup_uuid?: string
  iframe?: ContentItemIframe
  title?: string
  errors?: Record<string, string>
  lineItem?: unknown
  text?: string
  assignment_id?: string
  available?: {
    startDateTime?: string
    endDateTime?: string
  }
  submission?: {
    startDateTime?: string
    endDateTime?: string
  }
}

const ltiEndpointParams = (lookupUuid?: string | null | undefined) => {
  let endpointParams = 'display=borderless'

  if (lookupUuid !== null && lookupUuid !== undefined) {
    endpointParams += `&resource_link_lookup_uuid=${lookupUuid}`
  }

  return endpointParams
}

export const resourceLinkContentItem = (
  options: Omit<ResourceLinkContentItem, 'type'>
): ResourceLinkContentItem => ({
  type: 'ltiResourceLink',
  ...options,
})

export const resourceLinkContentItemToHtmlString = (
  item: ResourceLinkContentItem,
  ltiEndpoint?: string,
  editorSelection?: string
) => {
  const url = safeUrl(`${ltiEndpoint}?${ltiEndpointParams(item.lookup_uuid)}`)
  if (typeof item.iframe !== 'undefined') {
    return iframeTag({
      title: item.title,
      iframe: {
        ...item.iframe,
        src: url,
      },
    })
  } else {
    const itemWithText =
      typeof editorSelection === 'string' && editorSelection !== ''
        ? {
            ...item,
            text: editorSelection,
          }
        : item
    return anchorTag(
      {
        ...item,
        url,
      },
      linkBody(itemWithText)
    )
  }
}
