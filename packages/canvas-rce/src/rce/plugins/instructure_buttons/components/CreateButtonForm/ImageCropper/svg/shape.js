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

import round from 'round'
import {SHAPE_CONTAINER_LENGTH} from '../constants'
import {createSvgElement} from './utils'

export function buildShapeMask({shape}) {
  switch (shape) {
    case 'square':
      return buildSquare()
    case 'circle':
      return buildCircle()
    case 'triangle':
      return buildTriangle()
    case 'hexagon':
      return buildHexagon()
    case 'octagon':
      return buildOctagon()
    case 'star':
      return buildStar()
    default:
      throw new Error(`Invalid shape: ${shape}`)
  }
}

function buildSquare() {
  return createSvgElement('rect', {
    x: 0,
    y: 0,
    width: SHAPE_CONTAINER_LENGTH,
    height: SHAPE_CONTAINER_LENGTH,
    fill: 'black'
  })
}

function buildCircle() {
  return createSvgElement('circle', {
    cx: SHAPE_CONTAINER_LENGTH / 2,
    cy: SHAPE_CONTAINER_LENGTH / 2,
    r: SHAPE_CONTAINER_LENGTH / 2,
    fill: 'black'
  })
}

function buildTriangle() {
  return createSvgElement('path', {
    d: `M${SHAPE_CONTAINER_LENGTH / 2} 0L${SHAPE_CONTAINER_LENGTH} ${SHAPE_CONTAINER_LENGTH}H0L${
      SHAPE_CONTAINER_LENGTH / 2
    } 0Z`
  })
}

function buildHexagon() {
  const leg = round(0.2895 * SHAPE_CONTAINER_LENGTH, 2)
  return createSvgElement('path', {
    d: `M${SHAPE_CONTAINER_LENGTH - leg} 0L${SHAPE_CONTAINER_LENGTH} ${
      SHAPE_CONTAINER_LENGTH / 2
    }L${SHAPE_CONTAINER_LENGTH - leg} ${SHAPE_CONTAINER_LENGTH}H${leg}L0 ${
      SHAPE_CONTAINER_LENGTH / 2
    }L${leg} 0H${SHAPE_CONTAINER_LENGTH - leg}Z`
  })
}

function buildOctagon() {
  const leg = round(0.2895 * SHAPE_CONTAINER_LENGTH, 2)
  const side = round(SHAPE_CONTAINER_LENGTH - 2 * leg, 2)
  return createSvgElement('path', {
    d: `M0 ${leg}L${leg} 0H${leg + side}L${SHAPE_CONTAINER_LENGTH} ${leg}V${leg + side}L${
      leg + side
    } ${SHAPE_CONTAINER_LENGTH}H${leg}L0 ${leg + side}V${leg}Z`
  })
}

function buildStar() {
  const half = round(SHAPE_CONTAINER_LENGTH / 2, 2)
  const alpha = round(0.1143 * SHAPE_CONTAINER_LENGTH, 2)
  const beta = round(0.3906 * SHAPE_CONTAINER_LENGTH, 2)
  const gamma = round(0.1779 * SHAPE_CONTAINER_LENGTH, 2)
  const delta = round(0.6042 * SHAPE_CONTAINER_LENGTH, 2)
  const zeta = round(0.3433 * SHAPE_CONTAINER_LENGTH, 2)
  const eta = round(0.7344 * SHAPE_CONTAINER_LENGTH, 2)

  return createSvgElement('path', {
    d: `M${half} 0L${half + alpha} ${beta}H${SHAPE_CONTAINER_LENGTH}L${half + gamma} ${delta}L${
      half + zeta
    } ${SHAPE_CONTAINER_LENGTH}L${half} ${eta}L${half - zeta} ${SHAPE_CONTAINER_LENGTH}L${
      half - gamma
    } ${delta}L0 ${beta}H${half - alpha}L${half} 0L${half} 0Z`
  })
}
