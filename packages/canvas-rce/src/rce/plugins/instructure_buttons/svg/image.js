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
import {CLIP_PATH_ID} from './clipPath'
import {Shape} from './shape'

export function buildImage(settings) {
  // Don't attempt to embed an image if none exist
  if (!settings.encodedImage) return

  const group = createSvgElement('g', {'clip-path': `url(#${CLIP_PATH_ID})`})
  const image = createSvgElement('image', {
    x: settings.x,
    y: settings.y,
    transform: settings.transform,
    width: settings.width,
    height: settings.height,
    href: settings.encodedImage
  })

  group.appendChild(image)

  return group
}

/**
 * Calculates the transformation props for a given
 * shape and size.
 *
 * A Transform takes the following shape:
 * {
 *   x: string,
 *   y: string,
 *   width: number,
 *   height: number,
 *   translateX: number,
 *   translateY: number
 * }
 *
 * @param {Shape} shape
 * @param {Size} size
 *
 * @returns Transform
 */
export function transformForShape(shape, size) {
  switch (shape) {
    case Shape.Pentagon:
      return transformForPentagon(size)
    default:
      return transformForDefault(size)
  }
}

function transformForPentagon(size) {
  const defaults = transformForDefault(size)
  return {
    ...defaults,
    y: '55%'
  }
}

function transformForDefault(_size) {
  return {
    x: '50%',
    y: '50%',
    width: 75,
    height: 75,
    translateX: -37.5, // Width / 2
    translateY: -37.5 // Height / 2
  }
}
