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

import React, {createContext, useContext, useRef, useCallback, useState, useEffect} from 'react'
import {readFromSession, writeToSession} from './IgniteAgentSessionStorage'
import {readFromLocal, writeToLocal} from './IgniteAgentLocalStorage'
import {MIN_POSITION, DEFAULT_POSITION, MIN_TOP_MARGIN, BUTTON_HEIGHT} from './constants'

const AgentContainerContext = createContext(undefined)

export function AgentContainerProvider({children, buttonMountPoint}) {
  const containerRef = useRef(null)
  const [viewportHeight, setViewportHeight] = useState(window.innerHeight)
  const [viewportWidth, setViewportWidth] = useState(window.innerWidth)

  useEffect(() => {
    if (buttonMountPoint) {
      containerRef.current = buttonMountPoint
    }
  }, [buttonMountPoint])

  const [buttonPosition, setButtonPosition] = useState(() => {
    const savedInSession = readFromSession('buttonRelativeVerticalPosition')
    if (savedInSession !== undefined && savedInSession !== null && !Number.isNaN(savedInSession)) {
      return Math.max(MIN_POSITION, savedInSession)
    }

    const savedInLocal = readFromLocal('buttonRelativeVerticalPosition')
    if (savedInLocal !== undefined && savedInLocal !== null && !Number.isNaN(savedInLocal)) {
      return Math.max(MIN_POSITION, savedInLocal)
    }

    return DEFAULT_POSITION
  })

  const setDragging = useCallback(isDragging => {
    if (containerRef.current) {
      if (isDragging) {
        containerRef.current.classList.add('is-dragging-button')
      } else {
        containerRef.current.classList.remove('is-dragging-button')
      }
    }
  }, [])

  // Position constraint utilities
  const getMaxPosition = useCallback(viewportHeight => {
    const maxBottomPx = viewportHeight - MIN_TOP_MARGIN - BUTTON_HEIGHT
    return (maxBottomPx / viewportHeight) * 100
  }, [])

  const constrainPosition = useCallback(
    (pos, vpHeight) => {
      const maxPosition = getMaxPosition(vpHeight)
      return Math.max(MIN_POSITION, Math.min(maxPosition, pos))
    },
    [getMaxPosition],
  )

  // Persist position to storage
  useEffect(() => {
    writeToSession('buttonRelativeVerticalPosition', buttonPosition)
    writeToLocal('buttonRelativeVerticalPosition', buttonPosition)
  }, [buttonPosition])

  // Viewport resize tracking
  useEffect(() => {
    const updateViewportDimensions = () => {
      setViewportHeight(window.innerHeight)
      setViewportWidth(window.innerWidth)
    }

    window.addEventListener('resize', updateViewportDimensions)
    return () => window.removeEventListener('resize', updateViewportDimensions)
  }, [])

  return (
    <AgentContainerContext.Provider
      value={{
        containerRef,
        setDragging,
        viewportHeight,
        viewportWidth,
        buttonPosition,
        setButtonPosition,
        getMaxPosition,
        constrainPosition,
      }}
    >
      {children}
    </AgentContainerContext.Provider>
  )
}

export function useAgentContainer() {
  const context = useContext(AgentContainerContext)
  if (context === undefined) {
    throw new Error('useAgentContainer must be used within AgentContainerProvider')
  }
  return context
}
