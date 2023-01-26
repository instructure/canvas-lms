/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import {useEffect, useState, useRef, useCallback} from 'react'
import {debounce} from '@instructure/debounce'
import {KEY_EVENT_DELAY, KEY_EVENT_ACCELERATION} from './constants'
import {actions} from './reducers/imageCropper'

const EVENT_EXCEPTION_ELEMENT_IDS = [
  'imageCropperHeader',
  'imageCropperFooter',
  'imageCropperControls',
]

const TOUCH_EVENTS = ['ontouchmove', 'ontouchend', 'ontouchcancel']
const MOUSE_EVENTS = ['onmousemove', 'onmouseup', 'onmouseout']

function useKeysEvents(
  tempTranslateXRef,
  tempTranslateYRef,
  tempTranslateX,
  tempTranslateY,
  setTempTranslateX,
  setTempTranslateY,
  isMoving,
  setIsMoving,
  dispatch
) {
  // Refs that manage the keydown acceleration
  const direction = useRef(0)
  const initialTime = useRef(null)

  const onKeyDown = event => {
    // 37 = Left, 38 = Up, 39 = Right, 40 = Down
    const {keyCode} = event
    if (![37, 38, 39, 40].includes(keyCode)) {
      return
    }
    event.preventDefault()

    let elapsedTime

    if (keyCode !== direction.current) {
      elapsedTime = 0
      initialTime.current = new Date()
      direction.current = keyCode
      dispatch({type: actions.UPDATE_SETTINGS, payload: {direction: keyCode}})
    } else {
      const currentTime = new Date()
      elapsedTime = (currentTime - initialTime.current) / 1000
    }

    const translationDiff = Math.floor(KEY_EVENT_ACCELERATION * elapsedTime ** 2) || 1

    if ([37, 39].includes(keyCode)) {
      const sign = keyCode === 37 ? -1 : 1
      const newTranslateX = tempTranslateXRef.current + sign * translationDiff
      setTempTranslateX(newTranslateX)
    }

    if ([38, 40].includes(keyCode)) {
      const sign = keyCode === 38 ? -1 : 1
      const newTranslateY = tempTranslateYRef.current + sign * translationDiff
      setTempTranslateY(newTranslateY)
    }
  }

  const stopMovement = useCallback(
    debounce(
      () => {
        direction.current = 0
        initialTime.current = null
        setIsMoving(false)
      },
      KEY_EVENT_DELAY,
      {trailing: true}
    ),
    []
  )

  useEffect(() => {
    const onKeyDownWrapper = event => {
      // If the active element is in the modal header, footer or controls.
      if (
        EVENT_EXCEPTION_ELEMENT_IDS.some(id =>
          document.getElementById(id)?.contains(document.activeElement)
        )
      ) {
        return
      }
      onKeyDown(event)
    }
    // Adds the event listener when component did mount
    document.addEventListener('keydown', onKeyDownWrapper)
    return () => {
      // Removes the event listener when component will unmount
      document.removeEventListener('keydown', onKeyDownWrapper)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  useEffect(() => {
    if (isMoving && direction.current !== 0) {
      stopMovement()
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [tempTranslateX, tempTranslateY])
}

function useMouseAndTouchEvents(
  tempTranslateX,
  tempTranslateY,
  setTempTranslateX,
  setTempTranslateY,
  setIsMoving
) {
  const initialPageX = useRef(0)
  const initialPageY = useRef(0)
  const isDragging = useRef(false)
  const imgElement = useRef(null)

  const onStopMove = isMouseEvent => () => {
    isDragging.current = false
    initialPageX.current = 0
    initialPageY.current = 0

    if (imgElement.current) {
      const [move, end, cancel] = isMouseEvent ? MOUSE_EVENTS : TOUCH_EVENTS
      imgElement.current[move] = null
      imgElement.current[end] = null
      imgElement.current[cancel] = null
      imgElement.current = null
    }

    setIsMoving(false)
  }

  const onMove = isMouseEvent => e => {
    if (!isDragging.current) {
      return onStopMove()
    }
    const {clientX, clientY} = isMouseEvent ? e : e.touches[0]
    setTempTranslateX(tempTranslateX + clientX - initialPageX.current)
    setTempTranslateY(tempTranslateY + clientY - initialPageY.current)
  }

  const onStartMove = (e, isMouseEvent) => {
    isDragging.current = true
    const {target} = e
    const {clientX, clientY} = isMouseEvent ? e : e.touches[0]
    initialPageX.current = clientX
    initialPageY.current = clientY

    const [move, end, cancel] = isMouseEvent ? MOUSE_EVENTS : TOUCH_EVENTS
    target[move] = onMove(isMouseEvent)
    target[end] = onStopMove(isMouseEvent)
    // Should stop the movement when touch/mouse leaves the preview
    target[cancel] = onStopMove(isMouseEvent)

    imgElement.current = target

    setIsMoving(true)
  }

  return [e => onStartMove(e, true), e => onStartMove(e, false)]
}

export function useKeyMouseTouchEvents(translateX, translateY, dispatch) {
  const [tempTranslateX, _setTempTranslateX] = useState(translateX)
  const [tempTranslateY, _setTempTranslateY] = useState(translateY)
  const [isMoving, setIsMoving] = useState(false)

  // These are used to get the current values when the callback is called from outside.
  const tempTranslateXRef = useRef(tempTranslateX)
  const tempTranslateYRef = useRef(tempTranslateY)

  const setTempTranslateX = data => {
    setIsMoving(true)
    tempTranslateXRef.current = data
    _setTempTranslateX(data)
  }

  const setTempTranslateY = data => {
    setIsMoving(true)
    tempTranslateYRef.current = data
    _setTempTranslateY(data)
  }

  useKeysEvents(
    tempTranslateXRef,
    tempTranslateYRef,
    tempTranslateX,
    tempTranslateY,
    setTempTranslateX,
    setTempTranslateY,
    isMoving,
    setIsMoving,
    dispatch
  )

  const [onMouseDown, onTouchStart] = useMouseAndTouchEvents(
    tempTranslateX,
    tempTranslateY,
    setTempTranslateX,
    setTempTranslateY,
    setIsMoving
  )

  // Updates the reducer state when user stops moving.
  useEffect(() => {
    if (isMoving) {
      return
    }
    if (tempTranslateX !== translateX) {
      dispatch({type: actions.SET_TRANSLATE_X, payload: tempTranslateX})
    }
    if (tempTranslateY !== translateY) {
      dispatch({type: actions.SET_TRANSLATE_Y, payload: tempTranslateY})
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isMoving])

  // Updates the component state when props changed.
  useEffect(() => {
    if (isMoving) {
      return
    }
    if (translateX !== tempTranslateX) {
      tempTranslateXRef.current = translateX
      _setTempTranslateX(translateX)
    }
    if (translateY !== tempTranslateY) {
      tempTranslateYRef.current = translateY
      _setTempTranslateY(translateY)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [translateX, translateY])

  return [tempTranslateX, tempTranslateY, onMouseDown, onTouchStart]
}
