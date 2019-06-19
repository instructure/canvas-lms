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

const FILE_DOWNLOAD_PATH_REGEX = /^\/(courses\/\d+\/)?files\/\d+\/download$/

export const LINK_TYPE = 'link'
export const FILE_LINK_TYPE = 'file-link'
export const IMAGE_EMBED_TYPE = 'image-embed'
export const VIDEO_EMBED_TYPE = 'video-embed'
export const TEXT_TYPE = 'text'
export const NONE_TYPE = 'none'

function asImageEmbed($element) {
  const nodeName = $element.nodeName.toLowerCase()
  if (nodeName !== 'img') {
    return null
  }

  const altText = $element.alt || ''

  return {
    altText,
    isDecorativeImage: altText === '' && $element.getAttribute('data-is-decorative') === 'true',
    type: IMAGE_EMBED_TYPE,
    url: $element.src
  }
}

function asLink($element) {
  const nodeName = $element.nodeName.toLowerCase()
  if (nodeName !== 'a' || !$element.href) {
    return null
  }

  const path = new URL($element.href).pathname
  const type = FILE_DOWNLOAD_PATH_REGEX.test(path) ? FILE_LINK_TYPE : LINK_TYPE
  const displayAs = $element.classList.contains('auto_open') ? 'embed' : 'link'

  return {
    displayAs,
    text: $element.textContent,
    type,
    isPreviewable: $element.hasAttribute('data-canvas-previewable'),
    url: $element.href
  }
}

function asVideoElement($element) {
  if (!$element.id) {
    return null
  }

  if ($element.childElementCount !== 1) {
    return null
  }

  if (!$element.id.includes("media_object") ||  $element.children[0].tagName !== "IFRAME") {
    return null
  }

  return {
    type: VIDEO_EMBED_TYPE,
    id: $element.id.split("_")[2]
  }
}

function asText(editor) {
  const text = editor && editor.selection.getContent()
  if (!text) {
    return null
  }

  return {
    text: editor.selection.getContent(),
    type: 'TEXT_TYPE'
  }
}

function asNone() {
  return {type: NONE_TYPE}
}

export function getContentFromElement($element, editor) {
  if (!($element && $element.nodeName)) {
    return asNone()
  }

  const content = asLink($element) || asImageEmbed($element) || asVideoElement($element) || asText(editor) || asNone()
  content.$element = $element
  return content
}

export function getContentFromEditor(editor) {
  let $element
  if (editor && editor.selection) {
    $element = editor.selection.getNode()
  }

  if ($element == null) {
    return asNone()
  }

  return getContentFromElement($element, editor)
}
