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

import {getWidgetColors, lightColors, darkColors} from '../darkThemeColors'

describe('darkThemeColors', () => {
  it('returns light colors when isDark is false', () => {
    expect(getWidgetColors(false)).toBe(lightColors)
  })

  it('returns dark colors when isDark is true', () => {
    expect(getWidgetColors(true)).toBe(darkColors)
  })

  it('has matching keys between light and dark', () => {
    expect(Object.keys(lightColors).sort()).toEqual(Object.keys(darkColors).sort())
  })

  it('has different values between light and dark', () => {
    expect(lightColors.cardBackground).not.toBe(darkColors.cardBackground)
    expect(lightColors.cardSecondary).not.toBe(darkColors.cardSecondary)
    expect(lightColors.border).not.toBe(darkColors.border)
    expect(lightColors.textPrimary).not.toBe(darkColors.textPrimary)
  })
})
