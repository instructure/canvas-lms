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
import bridge from '../../../../bridge'
import formatMessage from '../../../../format-message'

export default function doFileUpload(ed, document, opts) {
  const {accept, panels, preselectedFile} = {...opts}
  let title = formatMessage('Upload File')
  if (accept?.indexOf('image/') === 0) {
    title = formatMessage('Upload Image')
  }

  return import('./UploadFile').then(({UploadFile}) => {
    let container = document.querySelector('.canvas-rce-upload-container')
    if (!container) {
      container = document.createElement('div')
      container.className = 'canvas-rce-upload-container'
      document.body.appendChild(container)
    }

    const handleDismiss = () => {
      ReactDOM.unmountComponentAtNode(container)
      ed.focus(false)
    }

    ReactDOM.render(
      <UploadFile
        preselectedFile={preselectedFile}
        accept={accept}
        editor={ed}
        label={title}
        panels={panels}
        onDismiss={handleDismiss}
        canvasOrigin={bridge.canvasOrigin}
      />,
      container
    )
  })
}
