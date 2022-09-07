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
import round from '../../../utils/round'
import {KEY_EVENT_DELAY, KEY_EVENT_STEP} from './constants'
import {actions} from '../../../reducers/imageCropper'

const EVENT_EXCEPTION_ELEMENT_IDS = [
  'imageCropperHeader',
  'imageCropperFooter',
  'imageCropperControls'
]

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
  const elapsedTime = useRef(0)

  const onKeyDownCallback = event => {
    // 37 = Left, 38 = Up, 39 = Right, 40 = Down
    const {keyCode} = event
    if (![37, 38, 39, 40].includes(keyCode)) {
      return
    }

    elapsedTime.current += 1

    let increment = 1
    if (keyCode === direction.current) {
      increment = Math.floor(elapsedTime.current / KEY_EVENT_STEP) + 1
    } else {
      direction.current = keyCode
      dispatch({type: actions.UPDATE_SETTINGS, payload: {direction: keyCode}})
      elapsedTime.current = 0
    }

    event.preventDefault()
    if ([37, 39].includes(keyCode)) {
      const signedIncrement = keyCode === 37 ? -increment : increment
      const newTranslateX = round(tempTranslateXRef.current + signedIncrement)
      setTempTranslateX(newTranslateX)
    }

    if ([38, 40].includes(keyCode)) {
      const signedIncrement = keyCode === 38 ? -increment : increment
      const newTranslateY = round(tempTranslateYRef.current + signedIncrement)
      setTempTranslateY(newTranslateY)
    }
  }

  const stopMovementCallback = useCallback(
    debounce(() => {
      direction.current = elapsedTime.current = 0
      setIsMoving(false)
    }, KEY_EVENT_DELAY),
    []
  )

  useEffect(() => {
    const onKeyDownCallbackWrapper = event => {
      // If the active element is in the modal header, footer or controls.
      if (
        EVENT_EXCEPTION_ELEMENT_IDS.some(id =>
          document.getElementById(id)?.contains(document.activeElement)
        )
      ) {
        return
      }
      onKeyDownCallback(event)
    }
    // Adds the event listener when component did mount
    document.addEventListener('keydown', onKeyDownCallbackWrapper)
    return () => {
      // Removes the event listener when component will unmount
      document.removeEventListener('keydown', onKeyDownCallbackWrapper)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  useEffect(() => {
    if (isMoving && direction.current !== 0) {
      stopMovementCallback()
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [tempTranslateX, tempTranslateY])
}

function useMouseEvents(
  tempTranslateX,
  tempTranslateY,
  setTempTranslateX,
  setTempTranslateY,
  setIsMoving
) {
  const initialPageX = useRef(0)
  const initialPageY = useRef(0)
  const mouseDown = useRef(false)
  const imgElement = useRef(null)

  const stoppedMovingCallback = () => {
    mouseDown.current = false
    initialPageX.current = 0
    initialPageY.current = 0

    if (imgElement.current) {
      imgElement.current.onmousemove = null
      imgElement.current.onmouseup = null
      imgElement.current = null
    }

    setIsMoving(false)
  }

  const startedMovingCallback = (target, clientX, clientY) => {
    mouseDown.current = true
    initialPageX.current = clientX
    initialPageY.current = clientY

    target.onmousemove = onMouseMoveCallback
    target.onmouseup = stoppedMovingCallback
    // Should stop the movement when mouse leaves the preview
    target.onmouseout = stoppedMovingCallback

    imgElement.current = target

    setIsMoving(true)
  }

  const onMouseMoveCallback = e => {
    if (!mouseDown.current) {
      return stoppedMovingCallback()
    }
    setTempTranslateX(tempTranslateX + e.clientX - initialPageX.current)
    setTempTranslateY(tempTranslateY + e.clientY - initialPageY.current)
  }

  return e => startedMovingCallback(e.target, e.clientX, e.clientY)
}

export function useKeyMouseEvents(translateX, translateY, dispatch, imgRef) {
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
  const onMouseDownCallback = useMouseEvents(
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

  return [tempTranslateX, tempTranslateY, onMouseDownCallback]
}
