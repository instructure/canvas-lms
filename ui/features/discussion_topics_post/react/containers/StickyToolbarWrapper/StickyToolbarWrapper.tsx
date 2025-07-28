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

import React, {useState, useEffect, useRef, ReactNode} from 'react'
import {isSpeedGraderInTopUrl} from '../../utils/constants'
interface ToolbarDimensions {
  width: number
  left: number
}

interface StickyToolbarWrapperProps {
  children: ReactNode
  scrollContainerId?: string
}

const StickyToolbarWrapper = ({
  children,
  scrollContainerId = 'drawer-layout-content',
}: StickyToolbarWrapperProps) => {
  const toolbarRef = useRef<HTMLDivElement>(null)
  const [isSticky, setSticky] = useState(false)
  const [toolbarDimensions, setToolbarDimensions] = useState<ToolbarDimensions>({width: 0, left: 0})
  const initialOffsetRef = useRef<number | null>(null)

  // Update the dimensions (width and left offset) of the toolbar
  const updateDimensions = (isResizing = false): void => {
    if (toolbarRef.current) {
      const rect = toolbarRef.current.getBoundingClientRect()
      // when the window is resizing, we need to follow the width of the body
      const bodyRect = isResizing
        ? document.querySelector('#discussion-drawer-layout')?.getBoundingClientRect()
        : null
      const finalRect = bodyRect ? {width: bodyRect.width, left: rect.left} : rect
      setToolbarDimensions({width: finalRect.width, left: finalRect.left})
    }
  }

  useEffect(() => {
    // Capture the dimensions on mount
    updateDimensions(false)
    // Recalculate dimensions on window resize
    const handleResize = () => updateDimensions(true)
    window.addEventListener('resize', handleResize)
    return () => {
      window.removeEventListener('resize', handleResize)
    }
  }, [])

  useEffect(() => {
    // Get the scrollable container element; default to window if not found
    const scrollContainer = document.getElementById(scrollContainerId) || window

    const getScrollPosition = (): number =>
      scrollContainer === window ? window.scrollY : (scrollContainer as HTMLElement).scrollTop

    // Store the initial vertical offset of the toolbar (relative to the document)
    const setInitialOffset = (): void => {
      if (toolbarRef.current && initialOffsetRef.current === null) {
        const rect = toolbarRef.current.getBoundingClientRect()
        const currentScroll = getScrollPosition()
        initialOffsetRef.current = rect.top + currentScroll
      }
    }

    setInitialOffset()

    const handleScroll = (): void => {
      if (!toolbarRef.current || initialOffsetRef.current === null) return
      const currentScroll = getScrollPosition()
      setSticky(currentScroll >= initialOffsetRef.current + 10)
    }

    scrollContainer.addEventListener('scroll', handleScroll)
    // In case the initial offset changes on resize
    window.addEventListener('resize', setInitialOffset)

    // Run once on mount in case we're already scrolled past the toolbar
    handleScroll()

    return () => {
      scrollContainer.removeEventListener('scroll', handleScroll)
      window.removeEventListener('resize', setInitialOffset)
    }
  }, [scrollContainerId])

  // When sticky, apply the captured dimensions so that the element
  // retains the same width as in its normal flow
  const stickyStyle: React.CSSProperties = {
    position: 'fixed',
    top: 0,
    width: toolbarDimensions.width,
    left: toolbarDimensions.left,
    zIndex: 1000,
  }

  return (
    <>
      {/* this is a placeholder div if we know the sticky toolbar is going to be there */}
      {isSticky && (
        <div
          data-testid="placeholder-div"
          // eslint-disable-next-line react-compiler/react-compiler
          style={{height: toolbarRef.current?.offsetHeight || 0}}
        />
      )}
      <div data-testid="sticky-toolbar" ref={toolbarRef} style={isSticky ? stickyStyle : {}}>
        {children}
      </div>
    </>
  )
}

export default StickyToolbarWrapper
