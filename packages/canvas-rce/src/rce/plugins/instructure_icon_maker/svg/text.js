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
import {
  TEXT_BACKGROUND_PADDING,
  BASE_SIZE,
  TEXT_SIZE,
  MAX_CHAR_COUNT,
  Size,
  TEXT_SIZE_FONT_DIFF,
} from './constants'
import {Shape} from './shape'

export function buildText({text, textPosition, textSize, textColor, shape, size}) {
  if (!text.trim()) return null

  const lines = splitTextIntoLines(text, MAX_CHAR_COUNT[textSize])
  const textElement = createSvgElement('text', {
    x: Math.max(TEXT_BACKGROUND_PADDING, Math.floor(getTextXValue(text, textSize, size))),
    y: getTextYValue(textPosition, textSize, shape, size, lines.length),
    fill: textColor || '',
    'font-family': 'Lato Extended',
    'font-size': TEXT_SIZE[textSize],
    'font-weight': 'bold',
  })

  const containerWidth = getContainerWidth({text, textSize, size})
  lines.forEach((line, index) => {
    const subtextWidth = getTextWidth(line, textSize)
    const subtext = createSvgElement('tspan', {
      x: Math.max(TEXT_BACKGROUND_PADDING, Math.floor((containerWidth - subtextWidth) * 0.5)),
      dy: index === 0 ? 0 : TEXT_SIZE[textSize],
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
  size,
}) {
  if (!text.trim()) return null

  const linesCount = splitTextIntoLines(text, MAX_CHAR_COUNT[textSize]).length
  const xValue = getTextXValue(text, textSize, size)
  const yValue = getTextYValue(textPosition, textSize, shape, size, linesCount)
  const textWidth = getTextWidth(text, textSize)
  // An extra line is added due svg text baseline behavior the first line is not counted regularly.
  const textHeight = getTextHeight(linesCount + 1, textSize)

  const paddingSize = TEXT_BACKGROUND_PADDING * 2
  const pathElement = createSvgElement('path')

  const radius = 4
  const fontWeight = 2
  const initialX = Math.max(0, Math.floor(xValue - TEXT_BACKGROUND_PADDING)) + radius
  const initialY = Math.floor(
    yValue - TEXT_SIZE[textSize] + TEXT_SIZE_FONT_DIFF[textSize] - TEXT_BACKGROUND_PADDING / 2
  )
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
  if (!text || text.trim().length === 0) {
    return base
  }

  const linesCount = splitTextIntoLines(text, MAX_CHAR_COUNT[textSize]).length
  const textYValue = getTextYValue(textPosition, textSize, shape, size, linesCount)
  const textHeight = getTextHeight(linesCount, textSize)
  const textBackgroundHeight = textYValue + textHeight + TEXT_BACKGROUND_PADDING * 2

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

function getTextHeight(linesCount, textSize) {
  // Since the svg text's initial Y position starts on the bottom of the first line
  // one line is subtracted to the count
  return (linesCount - 1) * TEXT_SIZE[textSize]
}

function getTextXValue(text, textSize, size) {
  const containerWidth = getContainerWidth({text, textSize, size})
  const textWidth = getTextWidth(text, textSize)
  return Math.floor((containerWidth - textWidth) * 0.5)
}

function getTextYValue(textPosition, textSize, shape, size, linesCount) {
  switch (textPosition) {
    case 'middle': {
      const baseline = getYMiddleText(textSize, shape, size)
      // Represents the Y difference for multiline text to keep it vertically centered
      const multilineDiff = ((linesCount - 1) * TEXT_SIZE[textSize]) / 2
      return baseline - multilineDiff
    }
    case 'bottom-third': {
      const baseline = getYBottomThirdText(textSize, shape, size)
      // Represents the Y difference for multiline text to keep it vertically centered
      const multilineDiff = ((linesCount - 1) * TEXT_SIZE[textSize]) / 2
      return baseline - multilineDiff
    }
    case 'below':
      return getYBelowText(textSize, shape, size)
    default:
      throw new Error(`Invalid text position: ${textPosition}`)
  }
}

function getYMiddleText(textSize, shape, size) {
  switch (textSize) {
    case Size.Small:
      return getYMiddleTextForShape(getYMiddleSmallTextForShape, shape, size)
    case Size.Medium:
      return getYMiddleTextForShape(getYMiddleMediumTextForShape, shape, size)
    case Size.Large:
      return getYMiddleTextForShape(getYMiddleLargeTextForShape, shape, size)
    case Size.ExtraLarge:
      return getYMiddleTextForShape(getYMiddleXLargeTextForShape, shape, size)
    default:
      throw new Error(`Invalid text size: ${textSize}`)
  }
}

function getYBottomThirdText(textSize, shape, size) {
  switch (textSize) {
    case Size.Small:
      return getYMiddleTextForShape(getYBottomThirdSmallTextForShape, shape, size)
    case Size.Medium:
      return getYMiddleTextForShape(getYBottomThirdMediumTextForShape, shape, size)
    case Size.Large:
      return getYMiddleTextForShape(getYBottomThirdLargeTextForShape, shape, size)
    case Size.ExtraLarge:
      return getYMiddleTextForShape(getYBottomThirdXLargeTextForShape, shape, size)
    default:
      throw new Error(`Invalid text size: ${textSize}`)
  }
}

function getYBelowText(textSize, shape, size) {
  switch (textSize) {
    case Size.Small:
      return getYMiddleTextForShape(getYBelowSmallTextForShape, shape, size)
    case Size.Medium:
      return getYMiddleTextForShape(getYBelowMediumTextForShape, shape, size)
    case Size.Large:
      return getYMiddleTextForShape(getYBelowLargeTextForShape, shape, size)
    case Size.ExtraLarge:
      return getYMiddleTextForShape(getYBelowXLargeTextForShape, shape, size)
    default:
      throw new Error(`Invalid text size: ${textSize}`)
  }
}

function getYMiddleTextForShape(getYTextSizeCallback, shape, size) {
  switch (shape) {
    case Shape.Square:
    case Shape.Circle:
    case Shape.Triangle:
    case Shape.Diamond:
    case Shape.Pentagon:
    case Shape.Hexagon:
    case Shape.Octagon:
    case Shape.Star:
      return getYTextSizeCallback(size)
    default:
      throw new Error(`Invalid shape: ${shape}`)
  }
}

function getYMiddleSmallTextForShape(size) {
  switch (size) {
    case Size.ExtraSmall:
      return 43
    case Size.Small:
      return 67
    case Size.Medium:
      return 85
    case Size.Large:
      return 115
    default:
      throw new Error(`Invalid size: ${size}`)
  }
}

function getYMiddleMediumTextForShape(size) {
  switch (size) {
    case Size.ExtraSmall:
      return 43
    case Size.Small:
      return 67
    case Size.Medium:
      return 85
    case Size.Large:
      return 115
    default:
      throw new Error(`Invalid size: ${size}`)
  }
}

function getYMiddleLargeTextForShape(size) {
  switch (size) {
    case Size.ExtraSmall:
      return 45
    case Size.Small:
      return 69
    case Size.Medium:
      return 87
    case Size.Large:
      return 117
    default:
      throw new Error(`Invalid size: ${size}`)
  }
}

function getYMiddleXLargeTextForShape(size) {
  switch (size) {
    case Size.ExtraSmall:
      return 47
    case Size.Small:
      return 71
    case Size.Medium:
      return 89
    case Size.Large:
      return 119
    default:
      throw new Error(`Invalid size: ${size}`)
  }
}

function getYBottomThirdSmallTextForShape(size) {
  switch (size) {
    case Size.ExtraSmall:
      return 73
    case Size.Small:
      return 121
    case Size.Medium:
      return 157
    case Size.Large:
      return 217
    default:
      throw new Error(`Invalid size: ${size}`)
  }
}

function getYBottomThirdMediumTextForShape(size) {
  switch (size) {
    case Size.ExtraSmall:
      return 74
    case Size.Small:
      return 122
    case Size.Medium:
      return 158
    case Size.Large:
      return 218
    default:
      throw new Error(`Invalid size: ${size}`)
  }
}

function getYBottomThirdLargeTextForShape(size) {
  switch (size) {
    case Size.ExtraSmall:
      return 75
    case Size.Small:
      return 123
    case Size.Medium:
      return 159
    case Size.Large:
      return 219
    default:
      throw new Error(`Invalid size: ${size}`)
  }
}

function getYBottomThirdXLargeTextForShape(size) {
  switch (size) {
    case Size.ExtraSmall:
      return 77
    case Size.Small:
      return 125
    case Size.Medium:
      return 161
    case Size.Large:
      return 221
    default:
      throw new Error(`Invalid size: ${size}`)
  }
}

function getYBelowSmallTextForShape(size) {
  switch (size) {
    case Size.ExtraSmall:
      return 96
    case Size.Small:
      return 144
    case Size.Medium:
      return 180
    case Size.Large:
      return 240
    default:
      throw new Error(`Invalid size: ${size}`)
  }
}

function getYBelowMediumTextForShape(size) {
  switch (size) {
    case Size.ExtraSmall:
      return 98
    case Size.Small:
      return 146
    case Size.Medium:
      return 182
    case Size.Large:
      return 242
    default:
      throw new Error(`Invalid size: ${size}`)
  }
}

function getYBelowLargeTextForShape(size) {
  switch (size) {
    case Size.ExtraSmall:
      return 104
    case Size.Small:
      return 152
    case Size.Medium:
      return 188
    case Size.Large:
      return 248
    default:
      throw new Error(`Invalid size: ${size}`)
  }
}

function getYBelowXLargeTextForShape(size) {
  switch (size) {
    case Size.ExtraSmall:
      return 110
    case Size.Small:
      return 158
    case Size.Medium:
      return 194
    case Size.Large:
      return 254
    default:
      throw new Error(`Invalid size: ${size}`)
  }
}
