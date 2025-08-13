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

import {useState, useRef, useCallback, useEffect} from 'react'
import {ButtonData} from './types'

const MAX_BUTTONS = 5
const MIN_BUTTONS = 1

export const createEmptyButton = (buttonId: number): ButtonData => ({
  id: buttonId,
  text: '',
})

export const useButtonManager = (
  initialButtons: ButtonData[],
  onButtonsChange: (buttons: ButtonData[]) => void,
) => {
  const [buttons, setButtons] = useState<ButtonData[]>(initialButtons.slice(0, MAX_BUTTONS))
  const nextIdRef = useRef(Math.max(0, ...initialButtons.map(b => b.id)) + 1)

  useEffect(() => {
    onButtonsChange(buttons)
  }, [buttons, onButtonsChange])

  const addButton = useCallback(() => {
    if (buttons.length < MAX_BUTTONS) {
      const newId = nextIdRef.current
      setButtons(prev => [...prev, createEmptyButton(newId)])
      nextIdRef.current += 1
    }
  }, [buttons.length])

  const removeButton = useCallback(
    (buttonId: number) => {
      if (buttons.length > MIN_BUTTONS) {
        setButtons(prev => prev.filter(button => button.id !== buttonId))
      }
    },
    [buttons.length],
  )

  const updateButton = useCallback((buttonId: number, updatedButton: Partial<ButtonData>) => {
    setButtons(prev =>
      prev.map(button => (button.id === buttonId ? {...button, ...updatedButton} : button)),
    )
  }, [])

  const canDeleteButton = buttons.length > MIN_BUTTONS
  const canAddButton = buttons.length < MAX_BUTTONS

  return {
    buttons,
    addButton,
    removeButton,
    updateButton,
    canDeleteButton,
    canAddButton,
  }
}
