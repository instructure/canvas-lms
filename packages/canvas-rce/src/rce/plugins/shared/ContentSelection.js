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

import {fromImageEmbed, fromVideoEmbed} from '../instructure_image/ImageEmbedOptions'

const FILE_DOWNLOAD_PATH_REGEX = /^\/(courses\/\d+\/)?files\/\d+\/download$/

export const LINK_TYPE = 'link'
export const FILE_LINK_TYPE = 'file-link'
export const IMAGE_EMBED_TYPE = 'image-embed'
export const VIDEO_EMBED_TYPE = 'video-embed'
export const TEXT_TYPE = 'text'
export const NONE_TYPE = 'none'
export const DISPLAY_AS_LINK = 'link'
export const DISPLAY_AS_EMBED = 'embed'
export const DISPLAY_AS_EMBED_DISABLED = 'embed-disabled'

export function asImageEmbed($element) {
  const nodeName = $element.nodeName.toLowerCase()
  if (nodeName !== 'img') {
    return null
  }

  return {
    ...fromImageEmbed($element),
    $element,
    type: IMAGE_EMBED_TYPE
  }
}

export function asLink($element, editor) {
  let $link = $element
  if ($link.tagName !== 'A') {
    // the user may have selected some text that is w/in a link
    // but didn't include the <a>. Let's see if that's true
    $link = editor.dom.getParent($link, 'a[href]')
  }

  if (!$link || $link.tagName !== 'A' || !$link.href) {
    return null
  }

  const path = new URL($link.href).pathname
  const type = FILE_DOWNLOAD_PATH_REGEX.test(path) ? FILE_LINK_TYPE : LINK_TYPE
  let displayAs = DISPLAY_AS_LINK
  if ($link.classList.contains('auto_open')) {
    displayAs = DISPLAY_AS_EMBED
  } else if ($link.classList.contains('inline_disabled')) {
    displayAs = DISPLAY_AS_EMBED_DISABLED
  }

  return {
    $element: $link,
    displayAs,
    text: editor.selection.getContent() || $link.textContent,
    type,
    isPreviewable: $link.hasAttribute('data-canvas-previewable'),
    url: $link.href
  }
}

// the video element is a bit tricky.
// tinymce won't let me add many attributes to the iframe,
// even though I've listed them in tinymce.config.js
// extended_valid_elements.
// we have to rely on the span tinymce wraps around the iframe
// and it's attributes, even though this could change with future
// tinymce releases.
// see https://github.com/tinymce/tinymce/issues/5181
export function asVideoElement($element) {
  if (!isVideoElement($element)) {
    return null
  }

  return {
    ...fromVideoEmbed($element),
    $element,
    type: VIDEO_EMBED_TYPE,
    id: $element.getAttribute('data-mce-p-data-media-id')
  }
}

function asText($element, editor) {
  const text = editor && editor.selection.getContent({format: 'text'})
  if (!text) {
    return null
  }

  return {
    $element,
    text,
    type: TEXT_TYPE
  }
}

function asNone($element) {
  return {
    $element: $element || null,
    type: NONE_TYPE
  }
}

export function getContentFromElement($element, editor) {
  if (!($element && $element.nodeName)) {
    return asNone()
  }

  const content =
    asLink($element, editor) ||
    asImageEmbed($element) ||
    asVideoElement($element) ||
    asText($element, editor) ||
    asNone($element)
  return content
}

export function getContentFromEditor(editor, expandSelection = false) {
  let $element
  if (editor && editor.selection) {
    // tinymce selects the element around the cursor, whether it's
    // content is selected in the copy/paste sense or not.
    // We want to include this content if it's _really_ selected,
    // or if editing the surrounding link, but not if creating a new link
    if (expandSelection || !editor.selection.isCollapsed()) {
      $element = editor.selection.getNode()
    }
  }

  if ($element == null) {
    return asNone()
  }

  return getContentFromElement($element, editor)
}

// if the selection is somewhere w/in a <a>,
// find the <a> and return it's info
export function getLinkContentFromEditor(editor) {
  const $element = editor.selection.getNode()
  return $element ? asLink($element, editor) : null
}

export function isFileLink($element, editor) {
  return !!asLink($element, editor)
}

export function isImageEmbed($element) {
  return !!asImageEmbed($element)
}

export function isVideoElement($element) {
  // the video is hosted in an iframe, but tinymce
  // wraps it in a span with swizzled attribute names
  if (!$element.getAttribute) {
    return false
  }

  if ($element.firstElementChild?.tagName !== 'IFRAME') {
    return false
  }

  const media_obj_id = $element.getAttribute('data-mce-p-data-media-id')
  if (!media_obj_id) {
    return false
  }

  const media_type = $element.getAttribute('data-mce-p-data-media-type')
  if (media_type !== 'video') {
    return false
  }

  return true
}
