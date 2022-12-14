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

import round from '../../round'
import {SHAPE_CONTAINER_LENGTH} from '../constants'
import {createSvgElement} from './utils'
import {Shape} from '../shape'

export function buildShapeMask({shape, size}) {
  const dimensionSize = size || SHAPE_CONTAINER_LENGTH
  switch (shape) {
    case Shape.Square:
      return buildSquare(dimensionSize)
    case Shape.Circle:
      return buildCircle(dimensionSize)
    case Shape.Triangle:
      return buildTriangle(dimensionSize)
    case Shape.Diamond:
      return buildDiamond(dimensionSize)
    case Shape.Pentagon:
      return buildPentagon(dimensionSize)
    case Shape.Hexagon:
      return buildHexagon(dimensionSize)
    case Shape.Octagon:
      return buildOctagon(dimensionSize)
    case Shape.Star:
      return buildStar(dimensionSize)
    default:
      throw new Error(`Invalid shape: ${shape}`)
  }
}

function buildSquare(dimensionSize) {
  return createSvgElement('rect', {
    x: 0,
    y: 0,
    width: dimensionSize,
    height: dimensionSize,
    fill: 'black',
  })
}

function buildCircle(dimensionSize) {
  return createSvgElement('circle', {
    cx: dimensionSize / 2,
    cy: dimensionSize / 2,
    r: dimensionSize / 2,
    fill: 'black',
  })
}

function buildTriangle(dimensionSize) {
  return createSvgElement('path', {
    d: `M${dimensionSize / 2} 0L${dimensionSize} ${dimensionSize}H0L${dimensionSize / 2} 0Z`,
  })
}

function buildDiamond(dimensionSize) {
  return createSvgElement('path', {
    d: `M${dimensionSize / 2} 0L${dimensionSize} ${dimensionSize / 2}L${
      dimensionSize / 2
    } ${dimensionSize}L0 ${dimensionSize / 2}L${dimensionSize / 2} 0Z`,
  })
}

function buildPentagon(dimensionSize) {
  const half = round(dimensionSize / 2, 2)
  const alpha = round(0.3906 * dimensionSize, 2)
  const beta = round(0.3433 * dimensionSize, 2)

  return createSvgElement('path', {
    d: `M${half} 0L${dimensionSize} ${alpha}L${half + beta} ${dimensionSize}H${
      half - beta
    }L0 ${alpha}L${half} 0L${half} 0Z`,
  })
}

function buildHexagon(dimensionSize) {
  const leg = round(0.2895 * dimensionSize, 2)
  return createSvgElement('path', {
    d: `M${dimensionSize - leg} 0L${dimensionSize} ${dimensionSize / 2}L${
      dimensionSize - leg
    } ${dimensionSize}H${leg}L0 ${dimensionSize / 2}L${leg} 0H${dimensionSize - leg}Z`,
  })
}

function buildOctagon(dimensionSize) {
  const leg = round(0.2895 * dimensionSize, 2)
  const side = round(dimensionSize - 2 * leg, 2)
  return createSvgElement('path', {
    d: `M0 ${leg}L${leg} 0H${leg + side}L${dimensionSize} ${leg}V${leg + side}L${
      leg + side
    } ${dimensionSize}H${leg}L0 ${leg + side}V${leg}Z`,
  })
}

function buildStar(dimensionSize) {
  const half = round(dimensionSize / 2, 2)
  const alpha = round(0.1143 * dimensionSize, 2)
  const beta = round(0.3906 * dimensionSize, 2)
  const gamma = round(0.1779 * dimensionSize, 2)
  const delta = round(0.6042 * dimensionSize, 2)
  const zeta = round(0.3433 * dimensionSize, 2)
  const eta = round(0.7344 * dimensionSize, 2)

  return createSvgElement('path', {
    d: `M${half} 0L${half + alpha} ${beta}H${dimensionSize}L${half + gamma} ${delta}L${
      half + zeta
    } ${dimensionSize}L${half} ${eta}L${half - zeta} ${dimensionSize}L${
      half - gamma
    } ${delta}L0 ${beta}H${half - alpha}L${half} 0Z`,
  })
}
