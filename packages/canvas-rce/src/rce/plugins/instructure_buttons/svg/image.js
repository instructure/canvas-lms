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
