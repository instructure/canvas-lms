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

export default function getPosition(editor, markerSelector) {
  const containerBoundingClientRect = editor
    .getContainer()
    .querySelector('iframe')
    .getBoundingClientRect()
  const markerBoundingClientRect = tinymce.dom
    .DomQuery(markerSelector, editor.contentDocument)[0]
    .getBoundingClientRect()

  return {
    left: containerBoundingClientRect.left + markerBoundingClientRect.left,
    top: containerBoundingClientRect.top + markerBoundingClientRect.top,
    right: containerBoundingClientRect.right + markerBoundingClientRect.right,
    bottom: containerBoundingClientRect.bottom + markerBoundingClientRect.bottom,
    height: markerBoundingClientRect.height,
    width: markerBoundingClientRect.width,
  }
}
