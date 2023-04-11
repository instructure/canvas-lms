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
import React from 'react'
import ReactDom from 'react-dom'
import {makeBodyEditable} from './contentEditable'
import {insertMentionFor} from './edit'
import {
  MARKER_SELECTOR,
  MARKER_ID,
  MENTION_MENU_ID,
  MENTION_MENU_SELECTOR,
  KEY_CODES,
} from './constants'
import MentionsUI from './components/MentionAutoComplete/MentionsUI'
import broadcastMessage, {inputChangeMessage, navigationMessage} from './broadcastMessage'

// track the currently selected user
let currentMentionsSelection

function shouldRestoreFromKeyEvent(event, editor) {
  const {which} = event

  // Enter key was pressed
  if (which === KEY_CODES.enter || which === KEY_CODES.tab) {
    const activeDescendant = editor.dom
      .select(MARKER_SELECTOR)[0]
      ?.getAttribute('aria-activedescendant')

    // If an active descendant is present, the user currently
    // has a user in the mentions suggestion component active.
    //
    // In this case, "enter" should select the user from the
    // list, not restore editability to the tinymce body
    if (activeDescendant) {
      event.preventDefault()
      return onMentionsExit(editor, true)
    }
  }

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

  return (
    which === KEY_CODES.up ||
    which === KEY_CODES.down ||
    which === KEY_CODES.enter ||
    which === KEY_CODES.tab ||
    which === KEY_CODES.escape
  )
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
  const editor = e.editor || tinymce.activeEditor

  // If the content being inserted is not the marker and
  // due to a paste
  if (!e.content.includes(MARKER_ID) && !e.paste) {
    onMentionsExit(editor)
  }

  // If content being set is the marker, load the menu
  // react component
  if (e.content.includes(MARKER_ID)) {
    if (!document.querySelector(MENTION_MENU_SELECTOR)) {
      const elm = document.createElement('span')
      elm.id = MENTION_MENU_ID
      editor.getContainer().parentNode.appendChild(elm)
      ReactDom.render(
        <MentionsUI
          rceRef={editor.getBody()}
          onFocusedUserChange={onFocusedUserChange}
          onExited={onMentionsExit}
          editor={editor}
        />,
        elm
      )
    }
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
    onMentionsExit(editor)
    return
  }

  // Should the event control the mentions suggestion
  // list rather than the editor?
  if (isMentionsNavigationEvent(e, editor)) {
    // Don't move the cursor please
    e.preventDefault()

    // If the user pressed the 'escape' key
    if (e.which === KEY_CODES.escape) {
      return onMentionsExit(editor)
    }

    // Do nothing if the user was selecting a suggestion
    if (e.which === KEY_CODES.enter || e.which === KEY_CODES.tab) return

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

  // "Enter" and "Tab" indicates a selection, not an input change
  if (e.which === KEY_CODES.enter || e.white === KEY_CODES.tab) return

  if (inMentionsMarker(editor)) {
    broadcastMessage(inputChangeMessage(editor.selection.getNode().textContent), [
      editor.getWin(),
      window,
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
    onMentionsExit(editor)
  }
}

/**
 * Closes the menu when the editor loses focus
 * @param Event e
 */
export const onWindowMouseDown = e => {
  const editor = e.editor || tinymce.activeEditor
  const element = e.target?.closest(`#${MENTION_MENU_ID}`)
  if (element) return
  onMentionsExit(editor)
}

/**
 * Sets the ARIA Active Descendant attribute
 * of the mentions marker to the given value
 *
 * @param String activeDescendant
 * @param Editor ed
 */
export const onFocusedUserChange = (focusedUser, ed) => {
  const editor = ed || tinymce.activeEditor
  const markerEl = editor.dom.select(MARKER_SELECTOR)[0]

  // TODO: Pass this object in from the component
  const temp = {
    activeDescendant: focusedUser?.ariaActiveDescendantId,
    user: {
      shortName: focusedUser?.name,
      id: focusedUser?._id,
    },
  }

  markerEl?.setAttribute('aria-activedescendant', focusedUser?.ariaActiveDescendantId || '')
  markerEl?.setAttribute('data-displayname', focusedUser?.name || '')
  markerEl?.setAttribute('data-userId', focusedUser?._id || '')

  currentMentionsSelection = temp
}

/**
 * Unmounts the mentions component and removes the
 * mount element.
 *
 * If setMention is true, also injects the mention
 * HTML for the currently selected mention suggestion
 *
 * @param Editor ed
 * @param Bool setMention
 */
export const onMentionsExit = (ed, setMention = false) => {
  const editor = ed || tinymce.activeEditor
  const menuMountElem = document.querySelector(MENTION_MENU_SELECTOR)
  const markerEl = editor.dom.select(MARKER_SELECTOR)[0]

  if (menuMountElem && markerEl) {
    makeBodyEditable(editor, MARKER_SELECTOR)

    if (setMention) {
      // Mention successful: insert mention HTML
      insertMentionFor(currentMentionsSelection?.user, ed)
    } else {
      // Mention cancelled: remove all attributes
      Array.from(markerEl.attributes).forEach(a => markerEl.removeAttribute(a.name))
    }

    menuMountElem.remove()
    return ReactDom.unmountComponentAtNode(menuMountElem)
  }
}
