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

import {makeBodyEditable} from './contentEditable'
import {MARKER_SELECTOR, MARKER_ID} from './constants'

function shouldRestoreFromKeyEvent(event, editor) {
  const {which} = event
  const keyCodes = {
    backspace: 8,
    enter: 13
  }

  // Enter key was pressed
  if (which === keyCodes.enter) return true

  // Nothing but a backspace key press can restore
  // body editability at this point
  if (which !== keyCodes.backspace) return false

  // Backspace key was pressed. Check to see if
  // the user was attempting to backspace out
  // of the mention span
  const {endOffset, startOffset} = editor.selection.getRng()
  return (endOffset === 1 && startOffset === 1) || (endOffset === 0 && startOffset === 0)
}

/**
 * Restores editability to the tinymce body.
 *
 * If the content being inserted contains the marker
 * element, this function is a no op
 *
 * @param Event e
 */
export const onSetContent = e => {
  // If the content being inserted is not the marker and
  // due to a paste
  if (!e.content.includes(MARKER_ID) && !e.paste) {
    makeBodyEditable(e.target, MARKER_SELECTOR)
  }
}

/**
 * Restores editability to the tinymce body.
 *
 * Only takes effect when the keydown event is
 * outside of the marker element OR if the keydown
 * event is a backspace / enter
 *
 * @param Event e
 */
export const onKeyDown = e => {
  const editor = e.editor || tinymce.activeEditor
  // If the user is typing outside the marker,\
  // or types an "enter" or "backspace" within the marker
  if (editor.selection.getNode().id !== MARKER_ID || shouldRestoreFromKeyEvent(e, editor)) {
    makeBodyEditable(editor, MARKER_SELECTOR)
  }
}

/**
 * Restores editability to the tinymce body.
 *
 * Only fires if the target of the mousedown event is
 * outside of the marker element
 * @param Event e
 */
export const onMouseDown = e => {
  const editor = e.editor || tinymce.activeEditor

  if (e.target.id !== MARKER_ID) {
    makeBodyEditable(editor, MARKER_SELECTOR)
  }
}
