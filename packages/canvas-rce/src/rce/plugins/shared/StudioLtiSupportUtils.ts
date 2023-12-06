/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {bool, shape} from 'prop-types'
import {EditorEvent, Events} from 'tinymce'

/**
 * Interface for content item's 'custom' field, specifically for what is expected to come from Studio
 *
 * Used to determine whether or not Studio embedded media should be resizable, and whether or not we
 * present controls for the user to modify the embedded media.
 */
export interface StudioContentItemCustomJson {
  source: 'studio'
  resizable?: boolean
  enableMediaOptions?: boolean
}

export interface StudioMediaOptionsAttributes {
  'data-studio-resizable': boolean
  'data-studio-tray-enabled': boolean
  'data-studio-convertible-to-link': boolean
}

export const parsedStudioOptionsPropType = shape({
  resizable: bool.isRequired,
  convertibleToLink: bool.isRequired,
})

export type ParsedStudioOptions = {
  resizable: boolean
  convertibleToLink: boolean
}

export function isStudioContentItemCustomJson(input: any): input is StudioContentItemCustomJson {
  return typeof input === 'object' && input.source === 'studio'
}

export function studioAttributesFrom(
  customJson: StudioContentItemCustomJson
): StudioMediaOptionsAttributes {
  return {
    'data-studio-resizable': customJson.resizable ?? false,
    'data-studio-tray-enabled': customJson.enableMediaOptions ?? false,
    'data-studio-convertible-to-link': true,
  }
}

export function displayStyleFrom(
  studioAttributes: StudioMediaOptionsAttributes | null
): 'inline-block' | '' {
  if (!studioAttributes) return ''

  return studioAttributes['data-studio-resizable'] || studioAttributes['data-studio-tray-enabled']
    ? 'inline-block'
    : ''
}

export function isStudioEmbeddedMedia(element: Element): boolean {
  // Borrowing this structure from isMediaElement in ContentSelection.js
  const tinymceIframeShim = element?.tagName === 'IFRAME' ? element?.parentElement : element

  if (tinymceIframeShim?.firstElementChild?.tagName !== 'IFRAME') {
    return false
  }

  return tinymceIframeShim.getAttribute('data-mce-p-data-studio-tray-enabled') === 'true'
}

export function parseStudioOptions(element: Element | null): ParsedStudioOptions {
  const tinymceIframeShim = element?.tagName === 'IFRAME' ? element?.parentElement : element
  return {
    resizable: tinymceIframeShim?.getAttribute('data-mce-p-data-studio-resizable') === 'true',
    convertibleToLink:
      tinymceIframeShim?.getAttribute('data-mce-p-data-studio-convertible-to-link') === 'true',
  }
}

/**
 * Tinymce adds an overlay when you click on an iframe inside the editor. It will by default
 * add resize handles to the corners of the overlay. The code that adds these handles won't
 * if the overlay has `data-mce-resize='false'` on it. Here, we force that behavior when the
 * underlying iframe has a `data-studio-resizable='false'`
 */
export function handleBeforeObjectSelected(e: EditorEvent<Events.ObjectSelectedEvent>): void {
  const targetElement = e.target as Element

  if (targetElement.getAttribute('data-mce-p-data-studio-resizable') === 'false') {
    targetElement.setAttribute('data-mce-resize', 'false')
  }
}
