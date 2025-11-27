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

import {useScope as createI18nScope} from '@canvas/i18n'
const I18n = createI18nScope('IgniteAgent')

import {View} from '@instructure/ui-view'
import {IconButton} from '@instructure/ui-buttons'
import {IconAiSolid} from '@instructure/ui-icons'
import {Spinner} from '@instructure/ui-spinner'

import React, {useState, useEffect, useRef, useCallback} from 'react'
import {useAgentContainer} from './AgentContainerContext'
import {PositionArrow} from './PositionArrow'
import {MIN_TOP_MARGIN, BUTTON_HEIGHT, DRAG_THRESHOLD} from './constants'
import './AgentButton.css'

/**
 * A button component for the Ignite Agent that can be vertically repositioned.
 * The button can be vertically repositioned by the user and the position is persisted in localStorage.
 * @param {object} props - The component props.
 * @param {Function} props.onClick - The function to execute when the button is clicked.
 * @param {boolean} [props.isLoading=false] - If true, shows a spinner overlay and disables the button.
 */
export function AgentButton({onClick, isLoading = false}) {
  // Get positioning state and utilities from context
  const {
    buttonPosition,
    setButtonPosition,
    constrainPosition,
    viewportHeight,
    setDragging: setDraggingContext,
  } = useAgentContainer()

  const [isHovered, setIsHovered] = useState(false)
  const [isFocused, setIsFocused] = useState(false)
  const [isDragging, setIsDragging] = useState(false)
  const [isPointerDown, setIsPointerDown] = useState(false)

  const containerRef = useRef(null)
  const dragStartY = useRef(0)
  const dragStartPosition = useRef(0)
  const hasDraggedRef = useRef(false)
  const onClickRef = useRef(onClick)

  const showControls = isHovered || isFocused || isDragging

  // Keep onClickRef up to date with latest onClick prop
  useEffect(() => {
    onClickRef.current = onClick
  }, [onClick])

  const getBottomPixels = useCallback(
    containerHeight => {
      const calculatedBottom = (buttonPosition / 100) * containerHeight

      const maxBottom = containerHeight - MIN_TOP_MARGIN - BUTTON_HEIGHT

      return Math.min(calculatedBottom, maxBottom)
    },
    [buttonPosition],
  )

  const bottomPx = getBottomPixels(viewportHeight)

  const handlePointerDown = useCallback(
    e => {
      // Only start drag preparation for primary pointer (left mouse button or first touch)
      if (!e.isPrimary) return

      dragStartY.current = e.clientY
      dragStartPosition.current = buttonPosition
      hasDraggedRef.current = false
      setIsPointerDown(true)
    },
    [buttonPosition],
  )

  const handlePointerMove = useCallback(
    e => {
      if (!isPointerDown) return

      const deltaY = Math.abs(dragStartY.current - e.clientY)

      if (!isDragging && deltaY > DRAG_THRESHOLD) {
        setIsDragging(true)
        hasDraggedRef.current = true
      }

      if (isDragging) {
        const deltaYSigned = dragStartY.current - e.clientY // Inverted: moving up = positive
        const deltaPercent = (deltaYSigned / viewportHeight) * 100
        const newPosition = constrainPosition(
          dragStartPosition.current + deltaPercent,
          viewportHeight,
        )

        setButtonPosition(newPosition)
      }
    },
    [isPointerDown, isDragging, constrainPosition, viewportHeight, setButtonPosition],
  )

  const handlePointerUp = useCallback(() => {
    setIsPointerDown(false)
    if (isDragging) {
      setIsDragging(false)
    }
    // Defer reset to next tick so click handlers see the dragged state
    // Event order: pointerdown → pointermove → pointerup → click
    // Without setTimeout, handleButtonClick would see hasDraggedRef=false
    setTimeout(() => {
      hasDraggedRef.current = false
    }, 0)
  }, [isDragging])

  const handleClick = useCallback(e => {
    // Prevent click if we just finished dragging
    if (hasDraggedRef.current) {
      e.preventDefault()
      e.stopPropagation()
    }
  }, [])

  const handleButtonClick = useCallback(() => {
    if (!hasDraggedRef.current) {
      onClickRef.current()
    }
  }, [])

  useEffect(() => {
    if (isPointerDown) {
      // Note: Document-level listeners are necessary for smooth dragging
      // When dragging, pointer can move outside button bounds
      // These listeners are only active during drag (when isPointerDown=true)
      document.addEventListener('pointermove', handlePointerMove)
      document.addEventListener('pointerup', handlePointerUp)

      return () => {
        document.removeEventListener('pointermove', handlePointerMove)
        document.removeEventListener('pointerup', handlePointerUp)
      }
    }
  }, [isPointerDown, handlePointerMove, handlePointerUp])

  useEffect(() => {
    setDraggingContext(isDragging)
  }, [isDragging, setDraggingContext])

  const handleFocus = useCallback(() => {
    setIsFocused(true)
  }, [])

  const handleBlur = useCallback(e => {
    if (containerRef.current && !containerRef.current.contains(e.relatedTarget)) {
      setIsFocused(false)
    }
  }, [])

  return (
    <div
      ref={containerRef}
      className="agent-position-closed"
      style={{bottom: `${bottomPx}px`}}
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
      onFocus={handleFocus}
      onBlur={handleBlur}
    >
      <div className="agent-button-wrapper">
        {showControls && (
          <div className="agent-control-top">
            <PositionArrow direction="up" />
          </div>
        )}

        <View display="inline-block" shadow="above" borderRadius="circle">
          {/* eslint-disable-next-line jsx-a11y/no-static-element-interactions, jsx-a11y/click-events-have-key-events -- This div is only for drag detection using pointer events (supports mouse and touch). The onClick prevents click propagation during drag. The IconButton inside provides full keyboard accessibility, and keyboard users can use the arrow buttons to reposition. */}
          <div
            style={{position: 'relative', cursor: 'move', touchAction: 'none'}}
            onPointerDown={handlePointerDown}
            onClick={handleClick}
          >
            <IconButton
              onClick={handleButtonClick}
              screenReaderLabel={
                isLoading ? I18n.t('Loading IgniteAI') : 'IgniteAI - Open chat assistant'
              }
              renderIcon={() => <IconAiSolid />}
              color="ai-primary"
              shape="circle"
              size="large"
              withBackground
            />
            {isLoading && (
              <div
                style={{
                  position: 'absolute',
                  inset: '0',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  backgroundColor: 'rgba(255, 255, 255, 0.8)',
                  borderRadius: '50%',
                }}
              >
                <Spinner renderTitle={I18n.t('Agent is processing')} size="small" />
              </div>
            )}
          </div>
        </View>

        {showControls && (
          <div className="agent-control-bottom">
            <PositionArrow direction="down" />
          </div>
        )}
      </div>

      <output
        style={{
          position: 'absolute',
          width: '1px',
          height: '1px',
          padding: '0',
          margin: '-1px',
          overflow: 'hidden',
          clip: 'rect(0, 0, 0, 0)',
          whiteSpace: 'nowrap',
          border: '0',
        }}
        aria-live="polite"
        aria-atomic="true"
      >
        {isDragging && `Button position: ${Math.round(buttonPosition)}% from bottom`}
      </output>
    </div>
  )
}
