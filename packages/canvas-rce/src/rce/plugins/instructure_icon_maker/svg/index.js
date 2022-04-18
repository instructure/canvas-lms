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
import {createSvgElement, convertFileToBase64} from './utils'
import {buildMetadata} from './metadata'
import {buildShape} from './shape'
import {buildImage} from './image'
import {buildClipPath} from './clipPath'
import {buildText, buildTextBackground, getContainerWidth, getContainerHeight} from './text'

export function buildSvg(settings, options = DEFAULT_OPTIONS) {
  settings = {...DEFAULT_SETTINGS, ...settings}

  const mainContainer = buildSvgContainer(settings)
  const shapeWrapper = buildSvgWrapper(settings)

  if (options.isPreview) {
    const checkerboard = buildCheckerboard()
    shapeWrapper.appendChild(checkerboard)
  } else {
    const metadata = buildMetadata(settings)
    mainContainer.appendChild(metadata)
  }

  const g = buildGroup(settings, options) // The shape group. Sets the controls the fill color
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
  const url = '/fonts/lato/extended/Lato-Bold.woff2'
  return new Promise(resolve => resolve(fetch(url)))
    .then(data => data.blob())
    .then(blob => convertFileToBase64(blob))
    .then(base64String => {
      const stylesheet = document.createElement('style')
      const css = `@font-face {font-family: "Lato Extended";font-weight: bold;src: url(${base64String});}`
      stylesheet.setAttribute('type', 'text/css')
      stylesheet.appendChild(document.createTextNode(css))
      return stylesheet
    })
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

export function buildSvgContainer(settings) {
  const containerWidth = getContainerWidth(settings)
  const containerHeight = getContainerHeight(settings)
  return createSvgElement('svg', {
    fill: 'none',
    width: `${containerWidth}px`,
    height: `${containerHeight}px`,
    viewBox: `0 0 ${containerWidth} ${containerHeight}`,
    xmlns: 'http://www.w3.org/2000/svg'
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
