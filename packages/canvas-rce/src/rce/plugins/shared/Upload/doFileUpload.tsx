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

import ReactDOM from 'react-dom'
import formatMessage from '../../../../format-message'
import React from 'react'
import bridge from '../../../../bridge'
import {handleSubmit, UploadFilePanelId} from './UploadFile'
import {Editor} from 'tinymce'

export type DoFileUploadResult = 'submitted' | 'dismissed'

export default function doFileUpload(
  ed: Editor,
  document: Document,
  opts: {
    accept?: string
    panels?: UploadFilePanelId[]
    preselectedFile?: File
  }
): {
  /**
   * Resolves when the dialog is shown.
   */
  shownPromise: Promise<unknown>

  /**
   * Resolves when the dialog is closed
   */
  closedPromise: Promise<DoFileUploadResult>
} {
  const {accept, panels, preselectedFile} = {...opts}

  const title = accept?.startsWith('image/')
    ? formatMessage('Upload Image')
    : formatMessage('Upload File')

  let shownResolve: () => void
  const shownPromise = new Promise<void>(resolve => (shownResolve = resolve))

  const closedPromise = import('./UploadFile').then(({UploadFile}) => {
    const container =
      document.querySelector('.canvas-rce-upload-container') ||
      (() => {
        const elem = document.createElement('div')
        elem.className = 'canvas-rce-upload-container'
        document.body.appendChild(elem)
        return elem
      })()

    return new Promise<DoFileUploadResult>(resolve => {
      const handleDismiss = () => {
        ReactDOM.unmountComponentAtNode(container)
        ed.focus(false)
        resolve('dismissed')
      }

      const wrappedSubmit = (...args: Parameters<typeof handleSubmit>) => {
        try {
          return handleSubmit(...args)
        } finally {
          resolve('submitted')
        }
      }

      ReactDOM.render(
        <UploadFile
          preselectedFile={preselectedFile}
          accept={accept}
          editor={ed}
          label={title}
          panels={panels}
          onDismiss={handleDismiss}
          onSubmit={wrappedSubmit}
          canvasOrigin={bridge.canvasOrigin}
        />,
        container
      )

      shownResolve()
    })
  })

  return {
    shownPromise,
    closedPromise,
  }
}
