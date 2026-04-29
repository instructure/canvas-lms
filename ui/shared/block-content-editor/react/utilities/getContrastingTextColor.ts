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

import tinycolor, {WCAG2Options} from 'tinycolor2'
import {colors} from '@instructure/canvas-theme'
import {memoize} from 'es-toolkit/compat'

const GRAY_COLORS = [colors.primitives.grey11, colors.primitives.grey125]

const WCAG_Options: WCAG2Options = {
  level: 'AA',
  size: 'small',
}

export const getContrastingTextColor = (backgroundColor: string): string | null => {
  if (!tinycolor(backgroundColor).isValid()) {
    return null
  }

  const textColor = tinycolor.mostReadable(backgroundColor, GRAY_COLORS, {
    includeFallbackColors: true,
    ...WCAG_Options,
  })

  const isContrastValid = tinycolor.isReadable(backgroundColor, textColor, {
    ...WCAG_Options,
  })

  return isContrastValid ? textColor.toHexString() : null
}

export const getContrastingTextColorCached = memoize(getContrastingTextColor)
