/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import conversions, {contrast, type RGBAType} from '@instructure/ui-color-utils'
import tinycolor from 'tinycolor2'

const isTransparent = (color?: string) => {
  if (!color) {
    return true
  }
  const c = tinycolor(color)
  return c.isValid() && c.getAlpha() === 0
}

// the following is copied from the INSTUI ColorContrast component
// a function to handle this will eventually be exported
// from @instructure/ui-color-utils
const INSTUIcalcBlendedColor = (c1: RGBAType, c2: RGBAType) => {
  const alpha = 1 - (1 - c1.a) * (1 - c2.a)
  return {
    r: (c2.r * c2.a) / alpha + (c1.r * c1.a * (1 - c2.a)) / alpha,
    g: (c2.g * c2.a) / alpha + (c1.g * c1.a * (1 - c2.a)) / alpha,
    b: (c2.b * c2.a) / alpha + (c1.b * c1.a * (1 - c2.a)) / alpha,
    a: 1,
  }
}

const INSTUIcalcContrast = (firstColor: string, secondColor: string): number => {
  const c1RGBA = conversions.colorToRGB(firstColor)
  const c2RGBA = conversions.colorToRGB(secondColor)
  const c1OnWhite = INSTUIcalcBlendedColor({r: 255, g: 255, b: 255, a: 1}, c1RGBA)
  const c2OnC1OnWhite = INSTUIcalcBlendedColor(c1OnWhite, c2RGBA)

  return contrast(conversions.colorToHex8(c1OnWhite), conversions.colorToHex8(c2OnC1OnWhite), 2)
}

const getContrastStatus = (color1: string, color2: string): boolean => {
  return INSTUIcalcContrast(color1, color2) >= 4.5
}

const getDefaultColors = () => {
  const fontcolor =
    window
      .getComputedStyle(document.documentElement)
      .getPropertyValue('--ic-brand-font-color-dark') || '#000000'
  return [fontcolor.toLowerCase(), '#ffffff']
}

export {getContrastStatus, isTransparent, getDefaultColors}
