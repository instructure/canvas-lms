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

import {createCroppedImageSvg} from '../imageCropUtils'
import {Shape} from '../../../../svg/shape'

describe('createCroppedImageSvg()', () => {
  beforeAll(() => {
    global.Image = class {
      onload() {}

      set src(val) {
        this.naturalWidth = 200
        this.naturalHeight = 100
        this.onload()
      }
    }
  })

  it('builds a <svg />', async () => {
    const imageSrc = 'data:image/png;base64,asdfasdfjksdf=='
    const shape = Shape.Square
    const svg = await createCroppedImageSvg({imageSrc, shape})
    expect(svg).toMatchInlineSnapshot(`
      <svg
        height="100"
        width="100"
        xmlns="http://www.w3.org/2000/svg"
      >
        <defs>
          <clippath
            id="clip-path-for-cropped-image"
          >
            <rect
              fill="black"
              height="100"
              width="100"
              x="0"
              y="0"
            />
          </clippath>
        </defs>
        <g
          clip-path="url(#clip-path-for-cropped-image)"
        >
          <image
            height="100"
            href="data:image/png;base64,asdfasdfjksdf=="
            transform="translate(-50, 0)"
            width="200"
          />
        </g>
      </svg>
    `)
  })

  describe('builds a <svg /> with scaleRatio', () => {
    it('1.0', async () => {
      const imageSrc = 'data:image/png;base64,asdfasdfjksdf=='
      const shape = Shape.Square
      const scaleRatio = 1.0
      const svg = await createCroppedImageSvg({imageSrc, shape, scaleRatio})
      expect(svg).toMatchInlineSnapshot(`
        <svg
          height="100"
          width="100"
          xmlns="http://www.w3.org/2000/svg"
        >
          <defs>
            <clippath
              id="clip-path-for-cropped-image"
            >
              <rect
                fill="black"
                height="100"
                width="100"
                x="0"
                y="0"
              />
            </clippath>
          </defs>
          <g
            clip-path="url(#clip-path-for-cropped-image)"
          >
            <image
              height="100"
              href="data:image/png;base64,asdfasdfjksdf=="
              transform="translate(-50, 0)"
              width="200"
            />
          </g>
        </svg>
      `)
    })

    it('1.5', async () => {
      const imageSrc = 'data:image/png;base64,asdfasdfjksdf=='
      const shape = Shape.Square
      const scaleRatio = 1.5
      const svg = await createCroppedImageSvg({imageSrc, shape, scaleRatio})
      expect(svg).toMatchInlineSnapshot(`
        <svg
          height="100"
          width="100"
          xmlns="http://www.w3.org/2000/svg"
        >
          <defs>
            <clippath
              id="clip-path-for-cropped-image"
            >
              <rect
                fill="black"
                height="100"
                width="100"
                x="0"
                y="0"
              />
            </clippath>
          </defs>
          <g
            clip-path="url(#clip-path-for-cropped-image)"
          >
            <image
              height="100"
              href="data:image/png;base64,asdfasdfjksdf=="
              transform="translate(-100, -25) scale(1.5)"
              width="200"
            />
          </g>
        </svg>
      `)
    })

    it('2.0', async () => {
      const imageSrc = 'data:image/png;base64,asdfasdfjksdf=='
      const shape = Shape.Square
      const scaleRatio = 2.0
      const svg = await createCroppedImageSvg({imageSrc, shape, scaleRatio})
      expect(svg).toMatchInlineSnapshot(`
        <svg
          height="100"
          width="100"
          xmlns="http://www.w3.org/2000/svg"
        >
          <defs>
            <clippath
              id="clip-path-for-cropped-image"
            >
              <rect
                fill="black"
                height="100"
                width="100"
                x="0"
                y="0"
              />
            </clippath>
          </defs>
          <g
            clip-path="url(#clip-path-for-cropped-image)"
          >
            <image
              height="100"
              href="data:image/png;base64,asdfasdfjksdf=="
              transform="translate(-150, -50) scale(2)"
              width="200"
            />
          </g>
        </svg>
      `)
    })
  })
})
