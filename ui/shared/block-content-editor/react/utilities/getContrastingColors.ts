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

import {lighten, darken, contrast, validateContrast} from '@instructure/ui-color-utils'
import tinyColor from 'tinycolor2'

export type ContrastingColors = {
  foreground: string
  background: string
}

const DEFAULT_FOREGROUND_COLOR = '#2a7abc'
const DEFAULT_BACKGROUND_COLOR = '#eaf2f9'
const ADJUSTMENT_STEP_PERCENTAGE = 5
const MAX_ATTEMPTS = 20

const colorCache = new Map<string, ContrastingColors>()

export function getContrastingColors(color: string): ContrastingColors {
  if (colorCache.has(color)) {
    return {...colorCache.get(color)!}
  }

  const adjust = tinyColor(color).isLight() ? darken : lighten
  let backgroundColor = color
  let isContrastValid = false
  let attempt = 0

  while (!isContrastValid && attempt < MAX_ATTEMPTS) {
    backgroundColor = adjust(backgroundColor, ADJUSTMENT_STEP_PERCENTAGE)
    isContrastValid = validateContrast(contrast(color, backgroundColor), 'AA').isValidGraphicsText
    attempt++
  }

  const result: ContrastingColors = {
    foreground: isContrastValid ? color : DEFAULT_FOREGROUND_COLOR,
    background: isContrastValid ? backgroundColor : DEFAULT_BACKGROUND_COLOR,
  }

  colorCache.set(color, result)
  return {...result}
}
