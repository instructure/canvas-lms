/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import tinymce from 'compiled/editor/stocktiny'

const openTag = /</
const isLink = /^<a [^>]+>[^<]+<\/a>$/

/**
 * @exports
 * A series of functions that wrap conditionals
 * and context around sending imperative commands to tinymce.
 *
 * They're all exported as self contained functions that hang off this
 * namespace with no global state
 * in this module because that's what has been really hurting debugging
 * efforts around tinymce issues in the past.
 *
 * Each function in this module will have a side effect of dispatching
 * some command to either the global tinymce module or a fetched
 * editor instance, and often other side effects that modulate
 * a passed in jquery object or the global editor registry.
 * (They aren't pure!!)
 */

/**
 * Make sure an editor is removed from everywhere we know about it.
 * This includes unregistering it with tinmyce, and with Instructure's
 * editorBoxList.
 *
 * @param {jQueryObject} editorNode the DOM element that this operation
 *   applies to.
 * @param {EditorBoxList} editorList our instance of the editor registry
 *   that keeps track of all the editors we know about.
 */
export function remove(editorNode, editorList) {
  const id = editorNode.attr('id')
  editorNode.data('rich_text', false)
  if (tinymce && tinymce.execCommand) {
    tinymce.execCommand('mceRemoveEditor', false, id)
    editorList._removeEditorBox(id)
  }
}

export function isOnlyText(maybeHtml) {
  return !(openTag.test(maybeHtml) && (!isLink.test(maybeHtml) || !maybeHtml.includes('href=')))
}

export function isLinkInsideTD(editor) {
  return (
    editor.selection.dom.getParent(editor.selection.getNode(), 'td') &&
    editor.selection.dom.getParent(editor.selection.getNode(), 'a') &&
    editor.selection.getNode().tagName !== 'TD'
  )
}

/**
 * Determines how to build an html link inside of a td tag. If the selection is a link
 * then it creates a new tag with the same attributes. If the selection is not a link then
 * it grabs whatever the selection is and generates a link with the html as its contents.
 * @param {Editor} tinymce editor
 * @param {String} content the text of the link inside the a tag,
 *   often passed in as the previously selected text prior to trying to
 *   create a link
 * @param {Hash} linkAttrs other attributes for the link (class, target, etc)
 */
export function buildHtmlLink(editor, content, linkAttrs) {
  if (editor.selection.getNode().tagName === 'A') {
    return editor.dom.create('a', linkAttrs, content)
  } else {
    // selection as surrounding html tags
    return editor.dom.create('a', linkAttrs, editor.selection.getNode())
  }
}

/**
 * Provide a means for inputting a link at the cursor point, after
 * re-establishing focus (important for IE11, which apparently hates
 * focus and will not remember your selection unless you explicitly
 * refocus).
 *
 * @param {String} id the id attribute of the tinymce node to add to
 * @param {String} content the text of the link inside the a tag,
 *   often passed in as the previously selected text prior to trying to
 *   create a link
 * @param {Hash} linkAttrs other attributes for the link (class, target, etc)
 *
 * @returns {DOM Node} returns a raw dom node
 */
export function insertLink(id, content, linkAttrs) {
  const editor = tinymce.get(id)
  editor.focus()

  // This is this odd edge case where if you have a link inside of a table and try to change it, tinymce will strip out all
  // of the surrounding tags like spans and divs. This makes sure surrounding tags/classess are maintained.

  if (isOnlyText(content) && isLinkInsideTD(editor)) {
    const linkHTML = buildHtmlLink(editor, content, linkAttrs)
    const linkToReplace = editor.selection.getNode()
    const linkParent = linkToReplace.parentNode

    linkParent.replaceChild(linkHTML, linkToReplace)
  } else if (isOnlyText(content)) {
    const linkContent = editor.dom.encode(content)
    const linkHtml = editor.dom.createHTML('a', linkAttrs, linkContent)
    editor.insertContent(linkHtml)
  } else {
    editor.execCommand('mceInsertLink', false, linkAttrs)
  }
}
