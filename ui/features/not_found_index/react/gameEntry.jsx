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
import {createRoot} from 'react-dom/client'
import OfficialNotFoundGame from './frogger/OfficialNotFoundGame'
import SpaceInvaders from './space_invaders/SpaceInvaders'
import SlidePuzzle from './slide_puzzle/SlidePuzzle'

export const renderGameApp = domElement => {
  const AppRootElement = document.getElementById(domElement)
  const root = createRoot(AppRootElement)
  const gamePool = [<OfficialNotFoundGame />, <SpaceInvaders />, <SlidePuzzle />]
  const index = Math.floor(Math.random() * 3)
  root.render(gamePool[index])
}

export const renderGameIntoDom = domElement => {
  renderGameApp(domElement)
}
