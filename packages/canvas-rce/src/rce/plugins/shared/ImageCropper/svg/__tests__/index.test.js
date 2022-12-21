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

import {buildSvg} from '../index'

describe('buildSvg()', () => {
  it('builds the crop shape svg', () => {
    expect(buildSvg('square')).toMatchInlineSnapshot(`
      <svg
        height="350"
        width="942"
        xmlns="http://www.w3.org/2000/svg"
      >
        <rect
          fill="#394B58"
          fill-opacity="0.5"
          height="350"
          width="296"
          x="0"
          y="0"
        />
        <rect
          fill="#394B58"
          fill-opacity="0.5"
          height="350"
          width="296"
          x="646"
          y="0"
        />
        <defs>
          <mask
            id="imageCropperMask"
          >
            <svg
              height="350"
              width="350"
              x="296"
              y="0"
            >
              <rect
                fill="white"
                height="350px"
                width="100%"
              />
              <rect
                fill="black"
                height="350"
                width="350"
                x="0"
                y="0"
              />
            </svg>
          </mask>
        </defs>
        <rect
          fill="#394B58"
          fill-opacity="0.5"
          height="350"
          mask="url(#imageCropperMask)"
          width="350"
          x="296"
          y="0"
        />
      </svg>
    `)
  })
})
