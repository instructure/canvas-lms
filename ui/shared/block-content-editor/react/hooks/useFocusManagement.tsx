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

import {useEffect, useRef} from 'react'
import {useAppSelector, useAppSetStore} from '../store'

type ButtonType = 'addButton' | 'insertButton' | 'copyButton'

type UseFocusManagementConfig = {
  nodeId?: string
  buttonType: ButtonType
}

const shouldFocusButton = (
  config: UseFocusManagementConfig,
  targetType: ButtonType,
  targetNodeId: string | null,
): boolean => {
  if (config.buttonType !== targetType) return false
  if (config.buttonType === 'addButton') return true
  return config.nodeId === targetNodeId
}

export const useFocusManagement = (config?: UseFocusManagementConfig) => {
  const focusTarget = useAppSelector(state => state.focusTarget)
  const set = useAppSetStore()
  const buttonRef = useRef<Element | null>(null)

  useEffect(() => {
    if (!config) return
    if (!focusTarget.type) return

    const shouldFocus = shouldFocusButton(config, focusTarget.type, focusTarget.nodeId)

    if (!shouldFocus) return

    setTimeout(() => {
      ;(buttonRef.current as HTMLElement).focus()
      set(state => {
        state.focusTarget = {type: null, nodeId: null}
      })
    }, 0)
  }, [config, focusTarget, set])

  const elementRef = (element: Element | null) => {
    buttonRef.current = element
  }

  const setFocusTarget = (type: ButtonType, nodeId: string | null = null) => {
    set(state => {
      state.focusTarget = {type, nodeId}
    })
  }

  const focusAddBlockButton = () => {
    setFocusTarget('addButton')
  }

  const focusInsertButton = (nodeId: string) => {
    setFocusTarget('insertButton', nodeId)
  }

  const focusCopyButton = (nodeId: string) => {
    setFocusTarget('copyButton', nodeId)
  }

  return {
    elementRef,
    focusAddBlockButton,
    focusInsertButton,
    focusCopyButton,
  }
}
