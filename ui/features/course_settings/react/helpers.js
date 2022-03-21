/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

const Helpers = {
  isValidImageType(mimeType) {
    switch (mimeType) {
      case 'image/jpeg':
      case 'image/gif':
      case 'image/png':
        return true
      default:
        return false
    }
  },

  extractInfoFromEvent(event) {
    let file = ''
    let type = ''
    if (event.type === 'change') {
      file = event.target.files[0]
      type = file.type
    } else {
      type = event.dataTransfer.files[0].type
      file = event.dataTransfer.files[0]
    }

    return {file, type}
  },

  // resize the user's selected image to more closely match
  // the eventual size it's rendered in the course card. This
  // avoids the latency from having to retrieve an image that's
  // larger than necessary. This was especially an issue in the
  // Respondus browser which would time out.
  resizeImageToFit(file, target_width, target_height) {
    const doc = document // for jest
    const target_ar = target_width / target_height
    const p = new Promise((resolve, reject) => {
      const reader = new FileReader()
      reader.onload = () => {
        const img = doc.createElement('img')
        img.onload = () => {
          if (img.width <= target_width || img.height <= target_height) {
            // the image is small enought, just use it.
            resolve(file)
          } else {
            // resize the image to more closely fit in the card
            const imgAspectRatio = img.width / img.height
            const cnvs = doc.createElement('canvas')
            cnvs.width = imgAspectRatio > target_ar ? target_height * imgAspectRatio : target_width
            cnvs.height = imgAspectRatio > target_ar ? target_height : target_width / imgAspectRatio
            const ctx = cnvs.getContext('2d')
            ctx.drawImage(img, 0, 0, cnvs.width, cnvs.height)
            cnvs.toBlob(blob => {
              const imgFile = new File([blob], file.name, {type: file.type})
              resolve(imgFile)
            }, 'image/jpg')
          }
        }
        img.src = reader.result
      }
      if (!/^image/.test(file.type)) {
        reject(new Error(`Invalid image file type '${file.type}'`))
      }
      reader.readAsDataURL(file)
    })
    return p
  }
}
export default Helpers
