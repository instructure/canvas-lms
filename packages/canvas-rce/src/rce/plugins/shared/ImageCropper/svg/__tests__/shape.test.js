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

import {buildShapeMask} from '../shape'

describe('buildShape()', () => {
  it('builds a square', () => {
    expect(buildShapeMask({shape: 'square'})).toMatchInlineSnapshot(`
      <rect
        fill="black"
        height="350"
        width="350"
        x="0"
        y="0"
      />
    `)
  })

  it('builds a circle', () => {
    expect(buildShapeMask({shape: 'circle'})).toMatchInlineSnapshot(`
      <circle
        cx="175"
        cy="175"
        fill="black"
        r="175"
      />
    `)
  })

  it('builds a diamond', () => {
    expect(buildShapeMask({shape: 'diamond'})).toMatchInlineSnapshot(`
      <path
        d="M175 0L350 175L175 350L0 175L175 0Z"
      />
    `)
  })

  it('builds a pentagon', () => {
    expect(buildShapeMask({shape: 'pentagon'})).toMatchInlineSnapshot(`
      <path
        d="M175 0L350 136.71L295.15999999999997 350H54.84L0 136.71L175 0L175 0Z"
      />
    `)
  })

  it('builds a hexagon', () => {
    expect(buildShapeMask({shape: 'hexagon'})).toMatchInlineSnapshot(`
      <path
        d="M248.68 0L350 175L248.68 350H101.32L0 175L101.32 0H248.68Z"
      />
    `)
  })

  it('builds an octagon', () => {
    expect(buildShapeMask({shape: 'octagon'})).toMatchInlineSnapshot(`
      <path
        d="M0 101.32L101.32 0H248.68L350 101.32V248.68L248.68 350H101.32L0 248.68V101.32Z"
      />
    `)
  })

  it('builds a star', () => {
    expect(buildShapeMask({shape: 'star'})).toMatchInlineSnapshot(`
      <path
        d="M175 0L215.01 136.71H350L237.27 211.47L295.15999999999997 350L175 257.04L54.84 350L112.72999999999999 211.47L0 136.71H134.99L175 0Z"
      />
    `)
  })
})
