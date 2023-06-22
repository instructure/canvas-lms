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

import {shouldCompressImage, compressImage} from '../compressionUtils'

jest.spyOn(global, 'FileReader').mockImplementation(function () {
  this.readAsDataURL = () => {
    this.result = 'data:image/jpeg;base64,SGVsbG8sIFdvcmxkIQ=='
    this.onloadend()
  }
})

global.Image = class {
  constructor() {
    setTimeout(() => {
      this.onload()
    }, 100)
  }
}

describe('shouldCompressImage()', () => {
  describe('mime types', () => {
    it('accepts jpeg images', () => {
      expect(shouldCompressImage({type: 'image/jpeg', size: 600000})).toBe(true)
    })

    it('accepts webp images', () => {
      expect(shouldCompressImage({type: 'image/webp', size: 600000})).toBe(true)
    })

    it('accepts bmp images', () => {
      expect(shouldCompressImage({type: 'image/bmp', size: 600000})).toBe(true)
    })

    it('accepts tiff images', () => {
      expect(shouldCompressImage({type: 'image/tiff', size: 600000})).toBe(true)
    })

    it("doesn't accept gif images", () => {
      expect(shouldCompressImage({type: 'image/gif', size: 600000})).toBe(false)
    })

    it("doesn't accept png images", () => {
      expect(shouldCompressImage({type: 'image/png', size: 600000})).toBe(false)
    })

    it("doesn't accept svg images", () => {
      expect(shouldCompressImage({type: 'image/svg+xml', size: 600000})).toBe(false)
    })
  })

  describe('size', () => {
    it('has greater size', () => {
      expect(shouldCompressImage({type: 'image/jpeg', size: 600000})).toBe(true)
    })

    it('has lower size', () => {
      expect(shouldCompressImage({type: 'image/jpeg', size: 400000})).toBe(false)
    })
  })
})

describe('compressImage()', () => {
  beforeAll(() => {
    const createElement = document.createElement.bind(document)
    document.createElement = tagName => {
      if (tagName === 'canvas') {
        return {
          getContext: () => ({
            drawImage: jest.fn(),
          }),
          toBlob: fn => fn('data:image/jpeg;base64,xxxxxxx=='),
        }
      }
      return createElement(tagName)
    }
  })

  it('returns compressed blob image', async () => {
    const result = await compressImage({
      encodedImage: 'data:image/jpeg;base64,abcdefhijk==',
      previewWidth: 200,
      previewHeight: 400,
    })
    expect(result).toEqual('data:image/jpeg;base64,SGVsbG8sIFdvcmxkIQ==')
  })
})
