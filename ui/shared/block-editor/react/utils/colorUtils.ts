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

import {type SerializedNode} from '@craftjs/core'
import tinycolor from 'tinycolor2'
import {contrast} from '@instructure/ui-color-utils'
import {white, black} from './constants'
import {
  getContrastStatus,
  isTransparent,
  getDefaultColors,
  type ColorsInUse,
} from '@instructure/canvas-rce'

const getContrastingColor = (color1: string) => {
  const color2 = contrast(color1, white) > contrast(color1, black) ? white : black
  return color2
}

const getContrastingButtonColor = (color1: string) => {
  const buttonColor = color1 === white ? 'primary-inverse' : 'secondary'
  return buttonColor
}

const getEffectiveBackgroundColor = (elem: HTMLElement | null): string => {
  if (!elem) return '#ffffff'
  let bgcolor = window.getComputedStyle(elem).backgroundColor
  while (isTransparent(bgcolor) && elem.parentElement) {
    elem = elem.parentElement
    bgcolor = window.getComputedStyle(elem).backgroundColor
  }
  return tinycolor(bgcolor).toHexString().toLowerCase()
}

const getEffectiveColor = (elem: HTMLElement) => {
  if (!elem) return '#000000'
  // getComputedStyle returns the effective color.
  // we don't have to walk up the tree
  const color = window.getComputedStyle(elem).color
  return tinycolor(color).toHexString().toLowerCase()
}

const sortByBrightness = (a: string, b: string) => {
  const brightnessA = tinycolor(a).getBrightness()
  const brightnessB = tinycolor(b).getBrightness()
  return brightnessA - brightnessB
}

interface Query {
  getSerializedNodes: () => Record<string, SerializedNode>
}

const getColorsInUse = (query: Query) => {
  const defaultColors = getDefaultColors()

  const colors: ColorsInUse = {
    foreground: [],
    background: [],
    border: [],
  }

  Object.values(query.getSerializedNodes()).forEach(value => {
    const n = value
    if (n.props.color && n.props.color[0] === '#' && !isTransparent(n.props.color)) {
      const c = tinycolor(n.props.color).toHexString().toLowerCase()
      if (!(defaultColors.includes(c) || colors.foreground.includes(c))) {
        colors.foreground.push(c)
      }
    }

    if (n.props.background && n.props.background[0] === '#' && !isTransparent(n.props.background)) {
      const c = tinycolor(n.props.background).toHexString().toLowerCase()
      if (!(defaultColors.includes(c) || colors.background.includes(c))) {
        colors.background.push(c)
      }
    }

    if (
      n.props.borderColor &&
      n.props.borderColor[0] === '#' &&
      !isTransparent(n.props.borderColor)
    ) {
      const c = tinycolor(n.props.borderColor).toHexString().toLowerCase()
      if (!(defaultColors.includes(c) || colors.border.includes(c))) {
        colors.border.push(c)
      }
    }
  })
  colors.foreground.sort(sortByBrightness)
  colors.background.sort(sortByBrightness)
  colors.border.sort(sortByBrightness)
  return colors
}

export {
  getContrastingColor,
  getContrastingButtonColor,
  getContrastStatus,
  isTransparent,
  getEffectiveBackgroundColor,
  getEffectiveColor,
  getColorsInUse,
  getDefaultColors,
  white,
  black,
  type ColorsInUse,
}
