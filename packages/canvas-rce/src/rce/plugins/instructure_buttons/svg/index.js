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

import {BASE_SIZE, DEFAULT_OPTIONS, DEFAULT_SETTINGS, STROKE_WIDTH} from './constants'
import {createSvgElement} from './utils'
import {buildShape} from './shape'

export function buildSvg(settings, options = DEFAULT_OPTIONS) {
  settings = {...DEFAULT_SETTINGS, ...settings}

  const wrapper = buildSvgWrapper(settings)

  if (options.isPreview) {
    const checkerboard = buildCheckerboard()
    wrapper.appendChild(checkerboard)
  }

  const g = buildGroup(settings, options)
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

export function buildGroup({color, outlineColor, outlineSize}, options = DEFAULT_OPTIONS) {
  const fill = color || (options.isPreview ? 'url(#checkerboard)' : 'none')
  const g = createSvgElement('g', {fill})
  if (outlineColor) {
    g.setAttribute('stroke', outlineColor)
    g.setAttribute('stroke-width', STROKE_WIDTH[outlineSize])
  }
  return g
}

export function buildCheckerboard() {
  const pattern = createSvgElement('pattern', {
    id: 'checkerboard',
    x: '0',
    y: '0',
    width: '16',
    height: '16',
    patternUnits: 'userSpaceOnUse'
  })

  const children = [
    createSvgElement('rect', {fill: '#d9d9d9', x: '0', width: '8', height: '8', y: '0'}),
    createSvgElement('rect', {fill: '#d9d9d9', x: '8', width: '8', height: '8', y: '8'})
  ]
  children.forEach(child => pattern.appendChild(child))

  return pattern
}
