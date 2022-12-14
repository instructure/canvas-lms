/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import round from '../round'
import {buildShapeMask} from './svg/shape'
import {createSvgElement} from './svg/utils'
import {PREVIEW_HEIGHT} from './constants'

const CLIP_PATH_ID = 'clip-path-for-cropped-image'

export async function createCroppedImageSvg(cropperSettings, image) {
  const {shape} = cropperSettings
  const {imageWidth, imageHeight} = await fetchImageMetadata(image)

  const squareDimension = imageHeight
  const rootElement = createSvgElement('svg', {
    xmlns: 'http://www.w3.org/2000/svg',
    width: squareDimension,
    height: squareDimension,
  })

  const defs = createDefsElement({shape, squareDimension})
  const mainGroup = createMainSvgGroup({
    imageWidth,
    imageHeight,
    squareDimension,
    image,
    settings: cropperSettings,
  })

  rootElement.appendChild(defs)
  rootElement.appendChild(mainGroup)
  return rootElement
}

const fetchImageMetadata = src => {
  return new Promise(resolve => {
    const img = new Image()
    img.onload = function () {
      resolve({imageWidth: this.naturalWidth, imageHeight: this.naturalHeight})
    }
    img.src = src
  })
}

const createDefsElement = ({shape, squareDimension}) => {
  const defs = createSvgElement('defs')
  const shapeMask = buildShapeMask({shape, size: squareDimension})
  const clipPath = createSvgElement('clipPath', {
    id: CLIP_PATH_ID,
  })
  clipPath.appendChild(shapeMask)
  defs.appendChild(clipPath)
  return defs
}

const convertTranslationUnits = (translationPixels, imageHeight) => {
  return (imageHeight * translationPixels) / PREVIEW_HEIGHT
}

const createMainSvgGroup = ({imageWidth, imageHeight, squareDimension, image, settings}) => {
  const mainGroup = createSvgElement('g', {
    'clip-path': `url(#${CLIP_PATH_ID})`,
  })
  const imageElement = createSvgElement('image', {
    width: imageWidth,
    height: imageHeight,
    href: image,
  })
  setTransformAttribute({
    imageElement,
    imageWidth,
    imageHeight,
    squareDimension,
    settings,
  })
  mainGroup.appendChild(imageElement)
  return mainGroup
}

export const setTransformAttribute = ({
  imageElement,
  imageWidth,
  imageHeight,
  squareDimension,
  settings,
}) => {
  const {rotation = 0, scaleRatio = 1.0, translateX = 0, translateY = 0} = settings
  const horizontalCenter = (scaleRatio * imageWidth) / 2
  const verticalCenter = (scaleRatio * imageHeight) / 2
  const convertedTranslateX = convertTranslationUnits(translateX, imageHeight)
  const convertedTranslateY = convertTranslationUnits(translateY, imageHeight)
  const x = round(-horizontalCenter + convertedTranslateX + squareDimension / 2, 2)
  const y = round(-verticalCenter + convertedTranslateY + squareDimension / 2, 2)
  let value = `translate(${x}, ${y})`
  if (rotation !== 0) {
    // Rotates image using its center as pivot
    value += ` rotate(${rotation}, ${horizontalCenter}, ${verticalCenter})`
  }
  if (scaleRatio !== 1.0) {
    value += ` scale(${scaleRatio})`
  }
  imageElement.setAttribute('transform', value)
}
