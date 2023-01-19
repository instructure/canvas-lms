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

import {MARKER_SELECTOR, MARKER_ID, TRIGGER_CHAR} from './constants'

/**
 * Simple wrapper function that inserts an html string
 * into an editor
 *
 * @param {String} html - The HTML to insert
 * @param {Object} editor - tinyMCE instance (defaults to active instance)
 *
 * @return {Boolean} - Was the insertion a success?
 */
export function insert(html, editor = tinymce.activeEditor) {
  return editor.execCommand('mceInsertContent', false, html)
}

/**
 * Replaces the node identified by "selector" with "newHtml"
 *
 * @param {String} selector - CSS style selector
 * @param {String} newHtml - the HTML to insert
 * @param {Object} editor - tinyMCE instance (defaults to active instance)
 *
 * @return {Boolean} - Was the insertion a success?
 */
export function replace(selector, newHtml, editor = tinymce.activeEditor) {
  const node = editor.dom.select(selector)[0]

  // Move cursor to the element that should be replaced
  editor.selection.select(node)

  // Delete the old element
  editor.dom.remove(node)

  // Insert the new element
  return insert(newHtml, editor)
}

export function insertMentionFor(user, editor = tinymce.activeEditor) {
  if (!user || !user.shortName || !user.id) {
    // eslint-disable-next-line no-console
    console.error('Error inserting mention for user:', user)
    return
  }

  // TODO: Any issue using generic document to make the element versus TinyMCE getDoc()?
  const newElem = document.createElement('span')

  newElem.classList.add('mceNonEditable', 'mention')
  newElem.setAttribute('data-mention', user?.id)
  newElem.textContent = `${TRIGGER_CHAR}${user?.shortName}`

  removeTriggerChar(editor)

  replace(MARKER_SELECTOR, newElem.outerHTML, editor)
}

/**
 * Removes the trigger char from the editor body
 */
export function removeTriggerChar(editor) {
  const markerElem = editor.dom.select(MARKER_SELECTOR)[0]
  const parentElem = markerElem?.parentElement
  // xsslint safeString.identifier TRIGGER_CHAR
  // xsslint safeString.identifier MARKER_ID
  const triggerMatcher = `${TRIGGER_CHAR}<span id="${MARKER_ID}"`

  if (parentElem?.innerHTML?.includes(TRIGGER_CHAR)) {
    const {innerHTML} = parentElem
    const triggerIndex = innerHTML.lastIndexOf(triggerMatcher)

    // slice out the trigger char and keep all surrounding content
    parentElem.innerHTML = innerHTML.slice(0, triggerIndex) + innerHTML.slice(triggerIndex + 1)
  }
}
