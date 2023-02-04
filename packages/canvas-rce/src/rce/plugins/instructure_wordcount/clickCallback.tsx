/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {generateRows, HEADERS} from './utils/tableContent'

const MODAL_ID = 'canvas-rce-wordcount-container'

interface WordCountOptions {
  readonly skipEditorFocus: boolean
}

export default function (ed: Editor, document: Document, options: WordCountOptions) {
  return import('./components/WordCountModal').then(({WordCountModal}) => {
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
      ed.focus(options.skipEditorFocus)
    }

    ReactDOM.render(
      <WordCountModal headers={HEADERS} rows={generateRows(ed)} onDismiss={handleDismiss} />,
      container
    )
  })
}
