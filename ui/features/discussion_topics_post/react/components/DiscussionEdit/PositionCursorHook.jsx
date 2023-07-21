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
import * as ReactDOMServer from 'react-dom/server'

const positionCursor = rceRef => {
  // Don't do anything until RCE is initialized
  if (!rceRef.current) return

  // Grab the instance of TinyMCE
  const {editor} = rceRef.current
  // Grab the container for the mention
  const mentionContainer = editor.dom.select('p')[0]

  positionForCreateReply(editor, mentionContainer)
}

const positionForCreateReply = (editor, mentionContainer) => {
  // Save the current html
  const currentText = mentionContainer.innerHTML
  // Inject a element right after the inserted mention
  mentionContainer.innerHTML =
    currentText + ReactDOMServer.renderToString(<span className="post_mention" />)
  // Move cursor to the paragraph
  const target = editor.dom.select('span.post_mention')[0]
  editor.selection.setCursorLocation(target, 0)
}

export default positionCursor
