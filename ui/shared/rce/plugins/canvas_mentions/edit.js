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
