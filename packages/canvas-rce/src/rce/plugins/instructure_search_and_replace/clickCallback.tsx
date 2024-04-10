/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import ReactDOM from 'react-dom'
import {Editor} from 'tinymce'
import FindReplaceController from './components/FindReplaceTrayController'
import {SearchReplacePlugin} from './types'

const CONTAINER_ID = 'instructure-find-replace-tray-container'

export default function (editor: Editor, document: Document) {
  const plugin = editor.plugins.searchreplace as SearchReplacePlugin

  const initalSelection = editor.selection?.getContent({format: 'text'})
  if (initalSelection) editor.selection?.collapse(true)

  let container = document.getElementById(CONTAINER_ID)
  if (container == null) {
    container = document.createElement('div')
    container.id = CONTAINER_ID
    document.body.appendChild(container)
  }

  const handleDismiss = () => {
    if (container) ReactDOM.unmountComponentAtNode(container)
    editor.focus(false)
  }

  ReactDOM.render(
    <FindReplaceController
      plugin={plugin}
      onDismiss={handleDismiss}
      initialText={initalSelection}
      undoManager={editor.undoManager}
    />,
    container
  )
}
