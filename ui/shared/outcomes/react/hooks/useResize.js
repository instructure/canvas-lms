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

import {useCallback, useRef, useEffect} from 'react'
import {isRTL} from '@canvas/i18n/rtlHelper'

const useResize = ({minWidth = 100, margin = 12, smallStep = 5, largeStep = 25} = {}) => {
  const containerRef = useRef(null)
  const delimiterRef = useRef(null)
  const leftColumnRef = useRef(null)
  const rightColumnRef = useRef(null)
  const setDelimiterRef = ref => (delimiterRef.current = ref)
  const setLeftColumnRef = ref => (leftColumnRef.current = ref)
  const setRightColumnRef = ref => (rightColumnRef.current = ref)

  const getValues = () => {
    const containerRect = containerRef.current.getBoundingClientRect()
    const delimiterRect = delimiterRef.current.getBoundingClientRect()
    const separatorPosition = Math.floor(
      ((delimiterRect.left - containerRect.left) / containerRect.width) * 100
    )
    return [containerRect, delimiterRect, separatorPosition]
  }

  useEffect(() => {
    if (containerRef.current && delimiterRef.current) {
      delimiterRef.current.setAttribute('aria-valuenow', getValues()[2])
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [containerRef.current, delimiterRef.current])

  const keyCodes = {
    PAGE_UP: 33,
    PAGE_DOWN: 34,
    ARROW_LEFT: 37,
    ARROW_RIGHT: 39,
  }
  const step = {
    [keyCodes.PAGE_UP]: largeStep,
    [keyCodes.PAGE_DOWN]: -largeStep,
    [keyCodes.ARROW_RIGHT]: smallStep,
    [keyCodes.ARROW_LEFT]: -smallStep,
  }
  let isHandlerDragging = false

  // recursivelly check if the element of mousemove start event is the
  // delimiter. This will handle clicking in a element inside the delimiter
  // and handle correctly the start of mousemove eent
  const onMouseDown = e => {
    let el = e.target

    while (el) {
      if (el === delimiterRef.current) {
        isHandlerDragging = true
        return
      }

      el = el.parentNode
    }

    isHandlerDragging = false
  }

  const onMouseUp = _e => {
    isHandlerDragging = false
  }

  const onMouseMove = e => {
    if (isHandlerDragging) {
      handleMove(e)
    } else {
      return false
    }
  }

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

  const onKeyDownHandler = e => handleMove(e, true)

  const handleMove = (e, keyboard = false) => {
    const [containerRect, delimiterRect, separatorPosition] = getValues()
    const maxLeftWidth = containerRect.width - minWidth - margin
    const calcLeftWidth = !keyboard
      ? e.clientX
      : Object.keys(step).includes(String(e.keyCode))
      ? delimiterRect.x + step[e.keyCode]
      : delimiterRect.x
    const currentLeftWidth = Math.max(minWidth, calcLeftWidth - containerRect.left)

    const leftWidth = Math.min(currentLeftWidth, maxLeftWidth)
    const rightWidth = containerRect.width - leftWidth - margin

    const leftColumnWidth = isRTL() ? rightWidth : leftWidth
    const rightColumnWidth = isRTL() ? leftWidth : rightWidth

    leftColumnRef.current.style.width = leftColumnWidth + 'px'
    leftColumnRef.current.style.flexGrow = 0

    rightColumnRef.current.style.width = rightColumnWidth + 'px'
    rightColumnRef.current.style.flexGrow = 0

    delimiterRef.current.setAttribute('aria-valuenow', separatorPosition)
  }

  return {
    setContainerRef,
    setDelimiterRef,
    setLeftColumnRef,
    setRightColumnRef,
    onKeyDownHandler,
  }
}

export default useResize
