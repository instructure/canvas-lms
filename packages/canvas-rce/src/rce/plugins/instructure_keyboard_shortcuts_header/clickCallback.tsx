/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

const MODAL_ID = 'canvas-rce-keyboard-shortcuts-container'

export default function (ed: Editor, document: Document) {
  return import('../../KeyboardShortcutModal').then(({default: KeyboardShortcutModal}) => {
    let container = document.querySelector(`#${MODAL_ID}`)

    if (!container) {
      container = document.createElement('div')
      container.id = MODAL_ID
      document.body.appendChild(container)
    }

    const handleDismiss = () => {
      if (container) {
        ReactDOM.unmountComponentAtNode(container)
      }
      ed.focus()
    }

    ReactDOM.render(
      <KeyboardShortcutModal
        open={true}
        onClose={handleDismiss}
        onDismiss={handleDismiss}
        onExited={handleDismiss}
      />,
      container,
    )
  })
}
