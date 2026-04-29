/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

export function findMediaPlayerIframe(elem: Element | null) {
  if (!elem) return null

  if (elem.tagName === 'IFRAME') {
    // we have the iframe
    return elem
  }
  if (elem.firstElementChild?.tagName === 'IFRAME') {
    // we have the shim tinymce puts around the iframe
    return elem.firstElementChild
  }
  if (elem.classList.contains('mce-shim')) {
    // tinymce puts a <span class='mce-shin'> after the iframe (since v5, I think)
    const prevSibling = elem.previousSibling
    if (prevSibling && 'tagName' in prevSibling && (prevSibling as Element).tagName === 'IFRAME') {
      return prevSibling as HTMLIFrameElement
    }
  }
  return null
}
