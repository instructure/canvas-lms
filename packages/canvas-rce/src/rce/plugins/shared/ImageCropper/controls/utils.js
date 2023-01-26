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

import {BUTTON_ROTATION_DEGREES, MAX_SCALE_RATIO, MIN_SCALE_RATIO} from '../constants'
import round from '../../round'

export const calculateScaleRatio = scaleRatio => {
  let result = round(scaleRatio)
  result = result > MAX_SCALE_RATIO ? MAX_SCALE_RATIO : result
  result = result < MIN_SCALE_RATIO ? MIN_SCALE_RATIO : result
  return result
}

export const calculateScalePercentage = scalePercentage => {
  const result = calculateScaleRatio(scalePercentage / 100)
  return round(result * 100, 0)
}

export const calculateRotation = rotationAngle => {
  const simplifiedRotationAngle = round(rotationAngle % 360)
  if (Math.abs(rotationAngle) >= 360) {
    return simplifiedRotationAngle
  }
  return rotationAngle
}

export const getNearestRectAngle = (rotationAngle, shouldRotateToLeft) => {
  return shouldRotateToLeft
    ? Math.ceil(rotationAngle / BUTTON_ROTATION_DEGREES) * 90
    : Math.floor(rotationAngle / BUTTON_ROTATION_DEGREES) * 90
}
