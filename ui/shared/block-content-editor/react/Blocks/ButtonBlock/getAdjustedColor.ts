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
import {lighten, darken} from '@instructure/ui-color-utils'
import tinyColor from 'tinycolor2'

export const getAdjustedColor = (color: string): string => {
  const tinyColorObj = tinyColor(color)
  const isLight = tinyColorObj.isLight()
  const luminosity = tinyColorObj.getLuminance()
  const baseAmount = 10

  if (isLight) {
    return darken(color, baseAmount)
  } else {
    const adjustedAmount = baseAmount + (0.5 - luminosity) * 20
    return lighten(color, adjustedAmount)
  }
}
