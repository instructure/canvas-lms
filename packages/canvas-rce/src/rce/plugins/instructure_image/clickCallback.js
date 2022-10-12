/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import formatMessage from '../../../format-message'

export default function (ed, document, trayProps) {
  return import('../shared/Upload/UploadFile').then(({UploadFile}) => {
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
    const unsplashEnabled = ed.getParam('unsplash_enabled')
    const panels = unsplashEnabled ? ['COMPUTER', 'UNSPLASH', 'URL'] : ['COMPUTER', 'URL']
    ReactDOM.render(
      <UploadFile
        accept="image/*"
        editor={ed}
        label={formatMessage('Upload Image')}
        panels={panels}
        onDismiss={handleDismiss}
        trayProps={trayProps}
      />,
      container
    )
  })
}
