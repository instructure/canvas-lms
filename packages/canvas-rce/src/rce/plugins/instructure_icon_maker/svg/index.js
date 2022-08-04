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

import {BASE_SIZE, DEFAULT_SETTINGS, STROKE_WIDTH} from './constants'
import {createSvgElement} from './utils'
import {buildMetadata} from './metadata'
import {buildShape} from './shape'
import {buildImage} from './image'
import {buildClipPath} from './clipPath'
import {buildText, buildTextBackground, getContainerWidth, getContainerHeight} from './text'
import base64EncodedFont from './font'

export function buildSvg(settings, options = {}) {
  settings = {...DEFAULT_SETTINGS, ...settings}

  const mainContainer = buildSvgContainer(settings, options)
  const shapeWrapper = buildSvgWrapper(settings)

  if (!options.isPreview) {
    const metadata = buildMetadata(settings)
    mainContainer.appendChild(metadata)
  }

  const g = buildGroup(settings) // The shape group. Sets the controls the fill color
  const clipPath = buildClipPath(settings) // A clip path used to crop the image
  const shape = buildShape(settings) // The actual path of the shape being built
  const image = buildImage(settings) // The embedded image. Cropped by clipPath

  clipPath.appendChild(shape)
  g.appendChild(clipPath)
  g.appendChild(shape.cloneNode(true))

  // Don't append an image if none has been selected
  if (image) {
    g.appendChild(image)
  }

  shapeWrapper.appendChild(g)
  mainContainer.appendChild(shapeWrapper)

  const textBackground = buildTextBackground(settings)
  if (textBackground) mainContainer.appendChild(textBackground)

  const text = buildText(settings)
  if (text) mainContainer.appendChild(text)

  return mainContainer
}

export function buildStylesheet() {
  const stylesheet = document.createElement('style')
  const css = `@font-face {font-family: "Lato Extended";font-weight: bold;src: url(${base64EncodedFont()});}`
  stylesheet.setAttribute('type', 'text/css')
  stylesheet.appendChild(document.createTextNode(css))
  return stylesheet
}

export function buildSvgWrapper(settings) {
  const base = BASE_SIZE[settings.size]
  return createSvgElement('svg', {
    fill: 'none',
    height: `${base}px`,
    viewBox: `0 0 ${base} ${base}`,
    width: `${base}px`,
    x: Math.floor((getContainerWidth(settings) - base) * 0.5)
  })
}

export function buildSvgContainer(settings, options) {
  const containerWidth = getContainerWidth(settings)
  const containerHeight = getContainerHeight(settings)
  const attributes = {
    fill: 'none',
    width: `${containerWidth}px`,
    height: `${containerHeight}px`,
    viewBox: `0 0 ${containerWidth} ${containerHeight}`,
    xmlns: 'http://www.w3.org/2000/svg'
  }
  if (options.isPreview) attributes.style = 'padding: 16px'
  return createSvgElement('svg', attributes)
}

export function buildGroup({color, outlineColor, outlineSize}) {
  const fill = color || 'none'
  const g = createSvgElement('g', {fill})
  if (outlineColor) {
    g.setAttribute('stroke', outlineColor)
    g.setAttribute('stroke-width', STROKE_WIDTH[outlineSize])
  }
  return g
}
