/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import React from 'react'
import {render} from '@testing-library/react'
import Cropper from '../cropper'

let file, wrapper, ref

describe('CanvasCropper', () => {
  beforeEach(() => {
    const blob = dataURItoBlob(filedata)
    ref = React.createRef()
    file = blob
    wrapper = render(<Cropper imgFile={file} width={100} height={100} ref={ref} />)
  })

  test('renders the component', () => {
    expect(wrapper.container.querySelector('.CanvasCropper')).toBeTruthy()
  })

  test('renders the image', () => {
    expect(wrapper.container.querySelector('.Cropper-image')).toBeTruthy()
  })

  test('getImage returns cropped image object', async () => {
    const done = jest.fn()
     
    ref.current.crop().then(image => {
      expect(image instanceof Blob).toBeTruthy()
      expect(done).toHaveBeenCalledTimes(1)
      done()
    })
  })
})

function dataURItoBlob(dataURI) {
  const byteString = atob(dataURI.split(',')[1])
  const mimeString = dataURI.split(',')[0].split(':')[1].split(';')[0]
  const ab = new ArrayBuffer(byteString.length)
  const ia = new Uint8Array(ab)
  for (let i = 0; i < byteString.length; i++) {
    ia[i] = byteString.charCodeAt(i)
  }
  const blob = new Blob([ab], {type: mimeString})
  return blob
}

// Simple 1x1 transparent PNG
const filedata =
  'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=='
