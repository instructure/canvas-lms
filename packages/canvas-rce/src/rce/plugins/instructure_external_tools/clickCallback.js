/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

export default function clickCallback(ed, ltiButtons) {
  return import('./components/LtiToolsModal').then(({LtiToolsModal}) => {
    let container = document.querySelector('.canvas-rce-upload-container')
    if (!container) {
      container = document.createElement('div')
      container.className = 'canvas-rce-upload-container'
      document.body.appendChild(container)
    }

    const handleDismiss = () => {
      ReactDOM.unmountComponentAtNode(container)
      ed.focus()
    }

    ReactDOM.render(
      <LtiToolsModal editor={ed} onDismiss={handleDismiss} ltiButtons={ltiButtons} />,
      container
    )
  })
}
