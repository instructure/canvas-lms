/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import {relativeHttpUrlForHostname} from '../util/url-util'

export const attributeNamesToUrlRelativize = ['href', 'cite', 'src', 'data']
export const attributeNamesToRemove = ['data-api-endpoint', 'data-api-returntype']

/**
 * Transforms a block of HTML for use within the Rich Content Editor, normalizing content to remove extraneous
 * things added by the server.
 *
 * @param inputHtml
 * @param options
 */
export function transformRceContentForEditing(
  inputHtml: string | null | undefined,
  options: TransformRceContentForEditingOptions
) {
  if (!inputHtml) {
    // It's important to return null/undefined here if that was passed in, otherwise tests fail because
    // the change-detection logic doesn't work correctly.
    return inputHtml
  }

  const container = document.createElement('div')

  try {
    // Note we're doing this instead of using a DOMParser because the DOMParser semantics are different than how we
    // actually use user html, which is to insert it into the page.
    // Specifically, user content that includes malformed <html>,<body>,<head>, etc... tags will be parsed differently.
    container.innerHTML = inputHtml
  } catch (e) {
    return inputHtml
  }

  // Relativize URLs in attribute
  for (const attributeName of attributeNamesToUrlRelativize) {
    container.querySelectorAll(`[${attributeName}]`).forEach(element => {
      const attributeValue = element.getAttribute(attributeName)

      if (attributeValue) {
        element.setAttribute(
          attributeName,
          relativeHttpUrlForHostname(attributeValue, options.origin)
        )
      }
    })
  }

  // Remove extraneous attributes
  container
    .querySelectorAll(attributeNamesToRemove.map(it => `[${it}]`).join(','))
    .forEach(element => {
      for (const attributeName of attributeNamesToRemove) {
        element.removeAttribute(attributeName)
      }
    })

  // fixup LTI iframe launches to use the `in_rce` display type
  container.querySelectorAll('iframe[src]').forEach(element => {
    const src = element.getAttribute('src')
    if (src?.includes('display=borderless')) {
      element.setAttribute('src', src.replace('display=borderless', 'display=in_rce'))
    }
  })

  return container.innerHTML
}

export interface TransformRceContentForEditingOptions {
  origin: string
}
