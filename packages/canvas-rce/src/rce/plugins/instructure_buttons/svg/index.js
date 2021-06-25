/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {DEFAULT_SETTINGS, BASE_SIZE, STROKE_WIDTH} from './constants'
import {createSvgElement} from './utils'
import {buildShape} from './shape'

export function buildSvg(settings = {}) {
  settings = {...DEFAULT_SETTINGS, ...settings}

  const wrapper = buildSvgWrapper(settings)
  const g = buildGroup(settings)
  const shape = buildShape(settings)

  g.appendChild(shape)
  wrapper.appendChild(g)

  return wrapper
}

export function buildSvgWrapper({size}) {
  const base = BASE_SIZE[size]
  return createSvgElement('svg', {
    fill: 'none',
    height: `${base}px`,
    viewBox: `0 0 ${base} ${base}`,
    width: `${base}px`
  })
}

export function buildGroup({color, outlineColor, outlineSize}) {
  const g = createSvgElement('g', {fill: color || 'none'})
  if (outlineColor) {
    g.setAttribute('stroke', outlineColor)
    g.setAttribute('stroke-width', STROKE_WIDTH[outlineSize])
  }
  return g
}
