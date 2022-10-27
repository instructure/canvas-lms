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

import {createSvgElement} from './utils'
import {
  PREVIEW_HEIGHT,
  SHAPE_CONTAINER_LENGTH,
  GLUE_WIDTH,
  PREVIEW_WIDTH,
  PREVIEW_BACKGROUND_COLOR,
} from '../constants'
import {buildShapeMask} from './shape'

export function buildSvg(shape) {
  const settings = {shape}
  const mainContainer = createSvgContainer()
  const leftGlue = createSvgElement('rect', {
    x: 0,
    y: 0,
    width: GLUE_WIDTH,
    height: PREVIEW_HEIGHT,
    fill: PREVIEW_BACKGROUND_COLOR,
    'fill-opacity': '0.5',
  })
  const rightGlue = createSvgElement('rect', {
    x: GLUE_WIDTH + SHAPE_CONTAINER_LENGTH,
    y: 0,
    width: GLUE_WIDTH,
    height: PREVIEW_HEIGHT,
    fill: PREVIEW_BACKGROUND_COLOR,
    'fill-opacity': '0.5',
  })
  const defsElement = createSvgElement('defs')
  const maskElement = createMask(settings)

  const bgElement = createSvgElement('rect', {
    x: `${PREVIEW_WIDTH / 2 - SHAPE_CONTAINER_LENGTH / 2}`,
    y: 0,
    width: SHAPE_CONTAINER_LENGTH,
    height: SHAPE_CONTAINER_LENGTH,
    mask: 'url(#imageCropperMask)',
    fill: PREVIEW_BACKGROUND_COLOR,
    'fill-opacity': '0.5',
  })
  defsElement.appendChild(maskElement)
  mainContainer.appendChild(leftGlue)
  mainContainer.appendChild(rightGlue)
  mainContainer.appendChild(defsElement)
  mainContainer.appendChild(bgElement)
  return mainContainer
}

function createSvgContainer() {
  return createSvgElement('svg', {
    xmlns: 'http://www.w3.org/2000/svg',
    width: PREVIEW_WIDTH,
    height: PREVIEW_HEIGHT,
  })
}

function createMask(settings) {
  const maskElement = createSvgElement('mask', {
    id: 'imageCropperMask',
  })
  const shapeContainer = createSvgElement('svg', {
    x: `${PREVIEW_WIDTH / 2 - SHAPE_CONTAINER_LENGTH / 2}`,
    y: 0,
    width: SHAPE_CONTAINER_LENGTH,
    height: SHAPE_CONTAINER_LENGTH,
  })
  const bgElement = createSvgElement('rect', {
    width: '100%',
    height: `${PREVIEW_HEIGHT}px`,
    fill: 'white',
  })
  const shapeElement = buildShapeMask(settings)
  shapeContainer.appendChild(bgElement)
  shapeContainer.appendChild(shapeElement)
  maskElement.appendChild(shapeContainer)
  return maskElement
}
