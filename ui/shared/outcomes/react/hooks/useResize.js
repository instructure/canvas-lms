/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {useCallback, useRef} from 'react'
import {isRTL} from '@canvas/i18n/rtlHelper'

const useResize = ({minWidth = 300, margin = 8} = {}) => {
  const containerRef = useRef(null)
  const delimiterRef = useRef(null)
  const leftColumnRef = useRef(null)
  const rightColumnRef = useRef(null)
  let isHandlerDragging = false

  const onMouseDown = e => {
    if (e.target === delimiterRef.current) isHandlerDragging = true
  }
  const onMouseUp = _e => {
    isHandlerDragging = false
  }
  const onMouseMove = e => {
    if (!isHandlerDragging) return false

    const containerRect = containerRef.current.getBoundingClientRect()
    const maxLeftWidth = containerRect.width - minWidth - margin
    const currentLeftWidth = Math.max(minWidth, e.clientX - containerRect.left - margin)

    const leftWidth = Math.min(currentLeftWidth, maxLeftWidth)
    const rightWidth = containerRect.width - leftWidth - margin

    const leftColumnWidth = isRTL() ? rightWidth : leftWidth
    const rightColumnWidth = isRTL() ? leftWidth : rightWidth

    leftColumnRef.current.style.width = leftColumnWidth + 'px'
    leftColumnRef.current.style.flexGrow = 0

    rightColumnRef.current.style.width = rightColumnWidth + 'px'
    rightColumnRef.current.style.flexGrow = 0
  }

  const setDelimiterRef = ref => (delimiterRef.current = ref)
  const setLeftColumnRef = ref => (leftColumnRef.current = ref)
  const setRightColumnRef = ref => (rightColumnRef.current = ref)

  const setContainerRef = useCallback(node => {
    if (node) {
      containerRef.current = node
      containerRef.current.addEventListener('mousedown', onMouseDown)
      containerRef.current.addEventListener('mouseup', onMouseUp)
      containerRef.current.addEventListener('mousemove', onMouseMove)
    }
    return () => {
      containerRef.current.removeEventListener('mousedown', onMouseDown)
      containerRef.current.removeEventListener('mouseup', onMouseUp)
      containerRef.current.removeEventListener('mousemove', onMouseMove)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  return {
    setContainerRef,
    setDelimiterRef,
    setLeftColumnRef,
    setRightColumnRef
  }
}

export default useResize
