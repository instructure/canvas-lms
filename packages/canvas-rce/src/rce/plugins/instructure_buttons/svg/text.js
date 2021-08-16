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

import {createSvgElement, splitTextIntoLines} from './utils'
import {TEXT_BACKGROUND_PADDING, BASE_SIZE, TEXT_SIZE, MAX_CHAR_COUNT} from './constants'

export function buildText({text, textPosition, textSize, textColor, shape, size}) {
  if (!text.trim()) return null

  const textElement = createSvgElement('text', {
    x: Math.max(TEXT_BACKGROUND_PADDING, Math.floor(getTextXValue(text, textSize, size))),
    y: getTextYValue(textPosition, textSize, shape, size),
    fill: textColor || '',
    'font-family': 'Lato Extended',
    'font-size': TEXT_SIZE[textSize],
    'font-weight': 'bold'
  })

  const lines = splitTextIntoLines(text, MAX_CHAR_COUNT[textSize])
  const containerWidth = getContainerWidth({text, textSize, size})
  lines.forEach((line, index) => {
    const subtextWidth = getTextWidth(line, textSize)
    const subtext = createSvgElement('tspan', {
      x: Math.max(TEXT_BACKGROUND_PADDING, Math.floor((containerWidth - subtextWidth) * 0.5)),
      dy: index === 0 ? 0 : TEXT_SIZE[textSize]
    })
    subtext.textContent = line
    textElement.appendChild(subtext)
  })

  return textElement
}

export function buildTextBackground({
  text,
  textPosition,
  textSize,
  textBackgroundColor,
  shape,
  size
}) {
  if (!text.trim()) return null

  const xValue = getTextXValue(text, textSize, size)
  const yValue = getTextYValue(textPosition, textSize, shape, size)
  const textWidth = getTextWidth(text, textSize)
  const textHeight = getTextHeight(text, textSize)
  const paddingSize = TEXT_BACKGROUND_PADDING * 2
  const pathElement = createSvgElement('path')

  const radius = 4
  const fontWeight = 2
  const initialX = Math.max(0, Math.floor(xValue - TEXT_BACKGROUND_PADDING)) + radius
  const initialY = Math.floor(yValue - TEXT_SIZE[textSize] - TEXT_BACKGROUND_PADDING / 2)
  const horizontalLineLength = Math.floor(textWidth + paddingSize + fontWeight) - radius * 2
  const verticalLineLength = Math.floor(textHeight + paddingSize + fontWeight) - radius * 2
  const d = `M${initialX},${initialY} h${horizontalLineLength} a${radius},${radius} 0 0 1 ${radius},${radius} v${verticalLineLength} a${radius},${radius} 0 0 1 ${-radius},${radius} h${-horizontalLineLength} a${radius},${radius} 0 0 1 ${-radius},${-radius} v${-verticalLineLength} a${radius},${radius} 0 0 1 ${radius},${-radius} z`
  pathElement.setAttribute('d', d)
  pathElement.setAttribute('fill', textBackgroundColor || '')
  return pathElement
}

export function getContainerWidth({text, textSize, size}) {
  const fontWeight = 2
  const base = BASE_SIZE[size]
  const textWidth =
    Math.floor(getTextWidth(text, textSize)) + TEXT_BACKGROUND_PADDING * 2 + fontWeight
  return Math.max(base, textWidth)
}

export function getContainerHeight({text, textPosition, textSize, shape, size}) {
  const base = BASE_SIZE[size]
  const textBackgroundHeight =
    getTextYValue(textPosition, textSize, shape, size) +
    getTextHeight(text, textSize) +
    TEXT_BACKGROUND_PADDING
  return Math.max(base, textBackgroundHeight)
}

function getTextWidth(text, textSize) {
  const canvas = document.createElement('canvas')
  const context = canvas.getContext('2d')
  context.font = `${TEXT_SIZE[textSize]}px "Lato Extended"`
  const lines = splitTextIntoLines(text, MAX_CHAR_COUNT[textSize])
  const widths = lines.map(line => context.measureText(line).width)
  return Math.max(...widths)
}

function getTextHeight(text, textSize) {
  const linesCount = splitTextIntoLines(text, MAX_CHAR_COUNT[textSize]).length
  return linesCount * TEXT_SIZE[textSize]
}

function getTextXValue(text, textSize, size) {
  const containerWidth = getContainerWidth({text, textSize, size})
  const textWidth = getTextWidth(text, textSize)
  return Math.floor((containerWidth - textWidth) * 0.5)
}

function getTextYValue(textPosition, textSize, shape, size) {
  switch (textPosition) {
    case 'middle':
      return getYMiddleText(textSize, shape, size)
    case 'bottom-third':
      return getYBottomThirdText(textSize, shape, size)
    case 'below':
      return getYBelowText(textSize, shape, size)
    default:
      throw new Error(`Invalid text position: ${textPosition}`)
  }
}

function getYMiddleText(textSize, shape, size) {
  switch (textSize) {
    case 'small':
      return getYMiddleTextForShape(getYMiddleSmallTextForShape, shape, size)
    case 'medium':
      return getYMiddleTextForShape(getYMiddleMediumTextForShape, shape, size)
    case 'large':
      return getYMiddleTextForShape(getYMiddleLargeTextForShape, shape, size)
    case 'x-large':
      return getYMiddleTextForShape(getYMiddleXLargeTextForShape, shape, size)
    default:
      throw new Error(`Invalid text size: ${textSize}`)
  }
}

function getYBottomThirdText(textSize, shape, size) {
  switch (textSize) {
    case 'small':
      return getYMiddleTextForShape(getYBottomThirdSmallTextForShape, shape, size)
    case 'medium':
      return getYMiddleTextForShape(getYBottomThirdMediumTextForShape, shape, size)
    case 'large':
      return getYMiddleTextForShape(getYBottomThirdLargeTextForShape, shape, size)
    case 'x-large':
      return getYMiddleTextForShape(getYBottomThirdXLargeTextForShape, shape, size)
    default:
      throw new Error(`Invalid text size: ${textSize}`)
  }
}

function getYBelowText(textSize, shape, size) {
  switch (textSize) {
    case 'small':
      return getYMiddleTextForShape(getYBelowSmallTextForShape, shape, size)
    case 'medium':
      return getYMiddleTextForShape(getYBelowMediumTextForShape, shape, size)
    case 'large':
      return getYMiddleTextForShape(getYBelowLargeTextForShape, shape, size)
    case 'x-large':
      return getYMiddleTextForShape(getYBelowXLargeTextForShape, shape, size)
    default:
      throw new Error(`Invalid text size: ${textSize}`)
  }
}

function getYMiddleTextForShape(getYTextSizeCallback, shape, size) {
  switch (shape) {
    case 'square':
    case 'circle':
    case 'triangle':
    case 'hexagon':
    case 'octagon':
    case 'star':
      return getYTextSizeCallback(size)
    default:
      throw new Error(`Invalid shape: ${shape}`)
  }
}

function getYMiddleSmallTextForShape(size) {
  switch (size) {
    case 'x-small':
      return 44
    case 'small':
      return 68
    case 'medium':
      return 86
    case 'large':
      return 116
    default:
      throw new Error(`Invalid size: ${size}`)
  }
}

function getYMiddleMediumTextForShape(size) {
  switch (size) {
    case 'x-small':
      return 45
    case 'small':
      return 69
    case 'medium':
      return 87
    case 'large':
      return 117
    default:
      throw new Error(`Invalid size: ${size}`)
  }
}

function getYMiddleLargeTextForShape(size) {
  switch (size) {
    case 'x-small':
      return 48
    case 'small':
      return 72
    case 'medium':
      return 90
    case 'large':
      return 120
    default:
      throw new Error(`Invalid size: ${size}`)
  }
}

function getYMiddleXLargeTextForShape(size) {
  switch (size) {
    case 'x-small':
      return 51
    case 'small':
      return 75
    case 'medium':
      return 93
    case 'large':
      return 123
    default:
      throw new Error(`Invalid size: ${size}`)
  }
}

function getYBottomThirdSmallTextForShape(size) {
  switch (size) {
    case 'x-small':
      return 77
    case 'small':
      return 125
    case 'medium':
      return 161
    case 'large':
      return 221
    default:
      throw new Error(`Invalid size: ${size}`)
  }
}

function getYBottomThirdMediumTextForShape(size) {
  switch (size) {
    case 'x-small':
      return 78
    case 'small':
      return 126
    case 'medium':
      return 162
    case 'large':
      return 222
    default:
      throw new Error(`Invalid size: ${size}`)
  }
}

function getYBottomThirdLargeTextForShape(size) {
  switch (size) {
    case 'x-small':
      return 81
    case 'small':
      return 129
    case 'medium':
      return 165
    case 'large':
      return 225
    default:
      throw new Error(`Invalid size: ${size}`)
  }
}

function getYBottomThirdXLargeTextForShape(size) {
  switch (size) {
    case 'x-small':
      return 84
    case 'small':
      return 132
    case 'medium':
      return 168
    case 'large':
      return 228
    default:
      throw new Error(`Invalid size: ${size}`)
  }
}

function getYBelowSmallTextForShape(size) {
  switch (size) {
    case 'x-small':
      return 96
    case 'small':
      return 144
    case 'medium':
      return 180
    case 'large':
      return 240
    default:
      throw new Error(`Invalid size: ${size}`)
  }
}

function getYBelowMediumTextForShape(size) {
  switch (size) {
    case 'x-small':
      return 98
    case 'small':
      return 146
    case 'medium':
      return 182
    case 'large':
      return 242
    default:
      throw new Error(`Invalid size: ${size}`)
  }
}

function getYBelowLargeTextForShape(size) {
  switch (size) {
    case 'x-small':
      return 104
    case 'small':
      return 152
    case 'medium':
      return 188
    case 'large':
      return 248
    default:
      throw new Error(`Invalid size: ${size}`)
  }
}

function getYBelowXLargeTextForShape(size) {
  switch (size) {
    case 'x-small':
      return 110
    case 'small':
      return 158
    case 'medium':
      return 194
    case 'large':
      return 254
    default:
      throw new Error(`Invalid size: ${size}`)
  }
}
