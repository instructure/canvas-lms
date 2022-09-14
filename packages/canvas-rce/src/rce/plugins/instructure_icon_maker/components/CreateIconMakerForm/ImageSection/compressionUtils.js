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

import {PREVIEW_HEIGHT, PREVIEW_WIDTH} from '../ImageCropper/constants'

const DEFAULT_TARGET_QUALITY = 0.75
export const MAX_IMAGE_SIZE_BYTES = 500 * 1024

function blobToBase64(blob) {
  return new Promise(resolve => {
    const reader = new FileReader()
    reader.onloadend = () => resolve(reader.result)
    reader.readAsDataURL(blob)
  })
}

function drawImageOnCanvasElement(image, quality, resolve, reject) {
  const {width, height} = image
  let compressedImageWidth, compressedImageHeight

  if (width > PREVIEW_WIDTH || height > PREVIEW_HEIGHT) {
    if (width > height) {
      compressedImageWidth = PREVIEW_WIDTH
      compressedImageHeight = compressedImageWidth * (height / width)
    } else if (height > width) {
      compressedImageHeight = PREVIEW_HEIGHT
      compressedImageWidth = compressedImageHeight * (width / height)
    } else {
      compressedImageWidth = compressedImageHeight = PREVIEW_HEIGHT
    }
  }

  const canvas = document.createElement('canvas')
  canvas.width = compressedImageWidth
  canvas.height = compressedImageHeight

  const ctx = canvas.getContext('2d')
  ctx.drawImage(image, 0, 0, compressedImageWidth, compressedImageHeight)

  canvas.toBlob(blob => (blob ? resolve(blob) : reject(blob)), 'image/jpeg', quality)
}

export function canCompressImage() {
  // Some old browsers don't support toBlob
  return Boolean(document.createElement('canvas').toBlob)
}

export function shouldCompressImage({type, size}) {
  return (
    ['image/jpeg', 'image/webp', 'image/bmp', 'image/tiff'].includes(type) &&
    size > MAX_IMAGE_SIZE_BYTES
  )
}

export function compressImage(encodedImage) {
  return new Promise((resolve, reject) => {
    const image = new Image()
    image.src = encodedImage
    image.onload = function () {
      drawImageOnCanvasElement(image, DEFAULT_TARGET_QUALITY, resolve, reject)
    }
  }).then(blob => blobToBase64(blob))
}
