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
import {MARKER_SELECTOR, MARKER_ID, KEY_CODES} from './constants'
import broadcastMessage, {inputChangeMessage, navigationMessage} from './broadcastMessage'

function shouldRestoreFromKeyEvent(event, editor) {
  const {which} = event

  // Enter key was pressed
  if (which === KEY_CODES.enter) return true

  // Nothing but a backspace key press can restore
  // body editability at this point
  if (which !== KEY_CODES.backspace) return false

  // Backspace key was pressed. Check to see if
  // the user was attempting to backspace out
  // of the mention span
  const {endOffset, startOffset} = editor.selection.getRng()
  return (endOffset === 1 && startOffset === 1) || (endOffset === 0 && startOffset === 0)
}

function isMentionsNavigationEvent(event, editor) {
  const {which} = event

  if (!inMentionsMarker(editor)) return false

  return which === KEY_CODES.up || which === KEY_CODES.down
}

function inMentionsMarker(editor) {
  return editor.selection.getNode().id === MARKER_ID
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

  // Should the event move the cursor out of
  // the mentions marker and restore editability
  // to the body?
  //
  // or
  //
  // Is the current node already outside the
  // mentions marker?
  if (!inMentionsMarker(editor) || shouldRestoreFromKeyEvent(e, editor)) {
    makeBodyEditable(editor, MARKER_SELECTOR)
  }

  // Should the event control the mentions suggestion
  // list rather than the editor?
  if (isMentionsNavigationEvent(e, editor)) {
    // Don't move the cursor please
    e.preventDefault()

    // Broadcast the event to mentions components
    broadcastMessage(navigationMessage(e), [editor.getWin(), window])
  }
}

/**
 * Handles key up events
 *
 * If the current node is the mentions marker,
 * this function will emit a "input change"
 * message
 *
 * @param Event e
 */
export const onKeyUp = e => {
  const editor = e.editor || tinymce.activeEditor

  // Navigation messages are broadcast on key down.
  // Prevent message duplication by returning early
  if (isMentionsNavigationEvent(e, editor)) return

  if (inMentionsMarker(editor)) {
    broadcastMessage(inputChangeMessage(editor.selection.getNode().innerHTML), [
      editor.getWin(),
      window
    ])
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
