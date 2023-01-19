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
import {EditorEvent} from 'tinymce'

export type TinyClipboardEvent = EditorEvent<ClipboardEvent>
export type TinyDragEvent = EditorEvent<DragEvent>
export type RCEClipOrDragEvent = (TinyClipboardEvent | TinyDragEvent) & {
  instructure_handled_already?: boolean
}

// Microsoft word will include an image of the text being pasted on the clipboard
// Let's look at the text/html to see if it's word before deciding to paste the image
// Assumes we've already confirmed that cbdata includes files
export function isMicrosoftWordContentInEvent(event: RCEClipOrDragEvent): boolean {
  const cbdata =
    event.type === 'paste'
      ? (event as EditorEvent<ClipboardEvent>).clipboardData
      : (event as EditorEvent<DragEvent>).dataTransfer
  if (cbdata?.files[0].type.indexOf('image/') === 0 && cbdata.types.includes('text/html')) {
    const html = cbdata.getData('text/html')
    return isMicrosoftWordContent(html)
  }
  return false
}

export function isMicrosoftWordContent(html: string): boolean {
  if (html) {
    const parser = new DOMParser()
    const doc = parser.parseFromString(html, 'text/html')

    return (
      Array.from(doc.documentElement.attributes).some(attr =>
        /schemas[-.]microsoft[-.]com/.test(attr.value)
      ) || /<o:|class="Mso/.test(doc.body.innerHTML || '')
    )
  }
  return false
}
