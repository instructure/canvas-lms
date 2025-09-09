/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

export interface ColorInfo {
  hexcode: string
  name: string
}

/**
 * Validates if a color string is a valid hex color
 * @param color - The color string to validate
 * @param allowWhite - Whether to allow white colors (#fff, #ffffff)
 * @returns true if the color is a valid hex code
 */
export function isValidHex(color: string, allowWhite = false): boolean {
  if (!allowWhite) {
    // prevent selection of white (#fff or #ffffff)
    const whiteHexRe = /^#?([fF]{3}|[fF]{6})$/
    if (whiteHexRe.test(color)) {
      return false
    }
  }

  // ensure hex is valid
  const validHexRe = /^#?([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/
  return validHexRe.test(color)
}

/**
 * Determines if a swatch should have border color applied
 * @param color - The color object
 * @param currentColor - The currently selected color
 * @param withBoxShadow - Whether box shadow is enabled
 * @returns true if border color should be applied
 */
export function shouldApplySwatchBorderColor(
  color: ColorInfo,
  currentColor: string,
  withBoxShadow: boolean,
): boolean {
  return withBoxShadow || currentColor !== color.hexcode
}

/**
 * Determines if a swatch should have selected styling
 * @param color - The color object
 * @param currentColor - The currently selected color
 * @returns true if selected styling should be applied
 */
export function shouldApplySelectedStyle(color: ColorInfo, currentColor: string): boolean {
  return currentColor === color.hexcode
}

/**
 * Gets the name of a predefined color by hex code
 * @param colorHex - The hex color code
 * @param predefinedColors - Array of predefined colors
 * @returns The color name or undefined if not found
 */
export function getColorName(colorHex: string, predefinedColors: ColorInfo[]): string | undefined {
  const colorWithoutHash = colorHex.replace('#', '')

  const definedColor = predefinedColors.find(
    color => color.hexcode.replace('#', '') === colorWithoutHash,
  )

  return definedColor?.name
}
