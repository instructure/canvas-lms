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

  let container: HTMLElement | null

  try {
    container = new DOMParser().parseFromString(inputHtml, 'text/html').querySelector('body')
  } catch (e) {
    return inputHtml
  }

  if (!container) {
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

  return container.innerHTML
}

export interface TransformRceContentForEditingOptions {
  origin: string
}
