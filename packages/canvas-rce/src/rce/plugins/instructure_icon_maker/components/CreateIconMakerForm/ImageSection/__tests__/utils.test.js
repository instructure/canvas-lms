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

import {isAnUnsupportedGifPngImage} from '../utils'

describe('isAnUnsupportedGifPngImage()', () => {
  it('returns true for a heavy GIF image', () => {
    expect(isAnUnsupportedGifPngImage({type: 'image/gif', size: 300 * 1024})).toBe(true)
  })

  it('returns true for a heavy PNG image', () => {
    expect(isAnUnsupportedGifPngImage({type: 'image/png', size: 300 * 1024})).toBe(true)
  })

  describe('returns false based on', () => {
    describe('mime types', () => {
      it('for jpeg images', () => {
        expect(isAnUnsupportedGifPngImage({type: 'image/jpeg', size: 200 * 1024})).toBe(false)
      })

      it('for webp images', () => {
        expect(isAnUnsupportedGifPngImage({type: 'image/webp', size: 200 * 1024})).toBe(false)
      })

      it('for bmp images', () => {
        expect(isAnUnsupportedGifPngImage({type: 'image/bmp', size: 200 * 1024})).toBe(false)
      })

      it('for tiff images', () => {
        expect(isAnUnsupportedGifPngImage({type: 'image/tiff', size: 200 * 1024})).toBe(false)
      })
    })

    describe('size', () => {
      it('for gif images with small size', () => {
        expect(isAnUnsupportedGifPngImage({type: 'image/gif', size: 100 * 1024})).toBe(false)
      })

      it('for png images with small size', () => {
        expect(isAnUnsupportedGifPngImage({type: 'image/png', size: 100 * 1024})).toBe(false)
      })
    })
  })
})
