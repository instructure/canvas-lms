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

import React, {useEffect, useState} from 'react'
import {debounce} from '@instructure/debounce'
import {calculateScaleRatio} from './controls/utils'
import {WHEEL_SCALE_STEP, WHEEL_EVENT_DELAY} from './constants'
import {actions} from '../../../reducers/imageCropper'

export function useMouseWheel(scaleRatio, dispatch) {
  const [tempScaleRatio, setTempScaleRatio] = useState(scaleRatio)
  const [isScaling, setIsScaling] = useState(false)

  const onWheelCallback = (event) => {
    event.preventDefault()

    const newScaleRatio = calculateScaleRatio(tempScaleRatio - event.deltaY * WHEEL_SCALE_STEP)
    if (newScaleRatio !== tempScaleRatio) {
      setIsScaling(true)
      setTempScaleRatio(newScaleRatio)
    }
  }

  const setScalingRatio = () =>  {
    setIsScaling(false)
  }

  useEffect(() => {
    if (!isScaling) {
      setTempScaleRatio(scaleRatio)
    }
  }, [scaleRatio])

  useEffect(() => {
    if (isScaling) {
      debounce(setScalingRatio, WHEEL_EVENT_DELAY)()
    }
  }, [tempScaleRatio])

  useEffect(() => {
    if (!isScaling) {
      dispatch({type: actions.SET_SCALE_RATIO, payload: tempScaleRatio})
    }
  }, [isScaling])

  return [tempScaleRatio, onWheelCallback]
}
