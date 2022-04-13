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

import Helpers from 'ui/features/course_settings/react/helpers'

QUnit.module('Course Settings Helpers')

test('isValidImageType', () => {
  ok(Helpers.isValidImageType('image/jpeg'), 'accepts jpeg')
  ok(Helpers.isValidImageType('image/gif'), 'accepts gif')
  ok(Helpers.isValidImageType('image/png'), 'accepts png')
  ok(!Helpers.isValidImageType('image/tiff'), 'denies tiff')
})

test('extractInfoFromEvent', () => {
  const changeEvent = {
    type: 'change',
    target: {
      files: [{type: 'image/jpeg'}]
    }
  }

  const dragEvent = {
    type: 'drop',
    dataTransfer: {
      files: [
        {
          name: 'test',
          type: 'image/jpeg'
        }
      ]
    }
  }

  const changeResults = Helpers.extractInfoFromEvent(changeEvent)
  const expectedChangeResults = {
    file: {
      type: 'image/jpeg'
    },
    type: 'image/jpeg'
  }

  const dragResults = Helpers.extractInfoFromEvent(dragEvent)
  const expectedDragResults = {
    file: {
      name: 'test',
      type: 'image/jpeg'
    },
    type: 'image/jpeg'
  }

  deepEqual(changeResults, expectedChangeResults, 'creates the proper info from change events')
  deepEqual(dragResults, expectedDragResults, 'creates the proper info from drag events')
})

QUnit.module('resizeImageToFit')

function makeImage(w, h) {
  return new Promise(resolve => {
    const canvas = document.createElement('canvas')
    canvas.width = w
    canvas.height = h
    const ctx = canvas.getContext('2d')
    ctx.strokeStyle = 'black'
    ctx.strokeRect(0, 0, w, h)
    canvas.toBlob(blob => {
      resolve(blob)
    })
  })
}

test('does not resize an image smaller than the requested size', () => {
  return new Promise(resolve => {
    /* eslint-disable promise/catch-or-return */
    makeImage(10, 10).then(imageIn => {
      Helpers.resizeImageToFit(imageIn, 100, 100).then(imageOut => {
        const htmlImage = document.createElement('img')
        document.getElementById('qunit-fixture').appendChild(htmlImage)
        htmlImage.onload = () => {
          deepEqual(htmlImage.naturalWidth, 10)
          deepEqual(htmlImage.naturalHeight, 10)
          URL.revokeObjectURL(htmlImage.src)
          resolve()
        }
        htmlImage.src = URL.createObjectURL(imageOut)
      })
    })
    /* eslint-enable promise/catch-or-return */
  })
})

test('shrinks a tall image to fit requested size', () => {
  return new Promise(resolve => {
    /* eslint-disable promise/catch-or-return */
    makeImage(50, 100).then(imageIn => {
      Helpers.resizeImageToFit(imageIn, 25, 25).then(imageOut => {
        const htmlImage = document.createElement('img')
        document.getElementById('qunit-fixture').appendChild(htmlImage)
        htmlImage.onload = () => {
          deepEqual(htmlImage.naturalWidth, 25)
          deepEqual(htmlImage.naturalHeight, 50)
          URL.revokeObjectURL(htmlImage.src)
          resolve()
        }
        htmlImage.src = URL.createObjectURL(imageOut)
      })
    })
    /* eslint-enable promise/catch-or-return */
  })
})

test('shrinks a wide image to fit requested size', () => {
  return new Promise(resolve => {
    /* eslint-disable promise/catch-or-return */
    makeImage(100, 50).then(imageIn => {
      Helpers.resizeImageToFit(imageIn, 25, 25).then(imageOut => {
        const htmlImage = document.createElement('img')
        document.getElementById('qunit-fixture').appendChild(htmlImage)
        htmlImage.onload = () => {
          deepEqual(htmlImage.naturalWidth, 50)
          deepEqual(htmlImage.naturalHeight, 25)
          URL.revokeObjectURL(htmlImage.src)
          resolve()
        }
        htmlImage.src = URL.createObjectURL(imageOut)
      })
    })
    /* eslint-enable promise/catch-or-return */
  })
})
