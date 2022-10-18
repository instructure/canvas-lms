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

import offset from 'bloody-offset'

// the editor's iframe
function editorIframe(editor) {
  return editor.getContainer().querySelector('iframe')
}

function box(el) {
  const b = el.getBoundingClientRect()
  return {
    top: b.top,
    left: b.left,
    width: b.right - b.left,
    height: b.bottom - b.top,
  }
}

//
// the shape of the target's sillhouette on the editor's container. have to
// subtract out the iframe's scroll since the target's position is relative to
// the iframe's _document_, not its visible window.
export default function indicatorRegion(editor, target, offsetFn = offset) {
  const iframe = editorIframe(editor)
  const outerShape = offsetFn(iframe)
  const innerShape = box(target)
  return {
    width: innerShape.width,
    height: innerShape.height,
    left: outerShape.left + innerShape.left,
    top: outerShape.top + innerShape.top,
  }
}
