/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

export function makeMarkerEditable(editor, targetSelector) {
  // Make the body non-editable
  editor.getBody().setAttribute('contenteditable', 'false')

  // Make the target editable if it exists
  const target = editor.dom.select(targetSelector)[0]
  if (!target) return

  target.setAttribute('contenteditable', 'true')

  // Put the cursor inside the target
  // target.innerHTML = ' '
  editor.selection.setCursorLocation(target, 0)
}

export function makeBodyEditable(editor, targetSelector) {
  // If the body is editable, no need to do anything
  if (editor.getBody().getAttribute('contenteditable') === 'true') return

  const bookmark = editor.selection.getBookmark()

  // Make the tinymce body editable once again
  editor.getBody().setAttribute('contenteditable', 'true')

  // Transform the marker
  const marker = editor.dom.select(targetSelector)[0]
  if (!marker) return

  editor.selection.moveToBookmark(bookmark)
}
