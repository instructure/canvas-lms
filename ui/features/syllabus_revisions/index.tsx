/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {render, rerender} from '@canvas/react'
import type {Root} from 'react-dom/client'
import SyllabusRevisionsTray from './react/SyllabusRevisionsTray'

let trayContainer: HTMLDivElement | null = null
let trayRoot: Root | null = null
let isOpen = false
let courseIdState: string | null = null
let buttonElement: HTMLButtonElement | null = null

const updateButton = () => {
  if (buttonElement) {
    buttonElement.textContent = isOpen
      ? buttonElement.dataset.hideText || ''
      : buttonElement.dataset.showText || ''
  }
}

const renderTray = () => {
  if (trayRoot && courseIdState) {
    rerender(
      trayRoot,
      <SyllabusRevisionsTray courseId={courseIdState} open={isOpen} onDismiss={handleDismiss} />,
    )
  }
}

const handleToggle = () => {
  isOpen = !isOpen
  renderTray()
  updateButton()
}

const handleDismiss = () => {
  isOpen = false
  renderTray()
  updateButton()
}

export function initSyllabusRevisionsTray(courseId: string, button: HTMLButtonElement) {
  if (!trayContainer) {
    trayContainer = document.createElement('div')
    trayContainer.id = 'syllabus-revisions-tray-container'
    document.body.appendChild(trayContainer)
  }

  if (!trayRoot) {
    trayRoot = render(
      <SyllabusRevisionsTray courseId={courseId} open={isOpen} onDismiss={handleDismiss} />,
      trayContainer,
    )
  }

  courseIdState = courseId
  buttonElement = button

  if (buttonElement) {
    buttonElement.addEventListener('click', handleToggle)
  }

  renderTray()
}
