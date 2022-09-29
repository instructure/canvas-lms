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

import {renderGameIntoDom} from './react/gameEntry'
import NotFoundArtwork from './react/NotFoundArtwork'

export const renderNotFoundApp = domElementId => {
  const AppRootElement = document.getElementById(domElementId)
  ReactDOM.render(<NotFoundArtwork />, AppRootElement)
}

export const handleGameStartClick = event => {
  if (event.keyCode === 32) {
    document.body.removeEventListener('keydown', handleGameStartClick)
    renderGameIntoDom('not_found_root')

    // Trigger start command for game
    const startGameEvent = new KeyboardEvent('keydown', {
      keyCode: 32,
      bubbles: true,
      cancelable: true,
    })
    document.dispatchEvent(startGameEvent)
  }
}

if (!ENV.KILL_JOY) {
  document.body.addEventListener('keydown', handleGameStartClick)
}

renderNotFoundApp('not_found_root')
