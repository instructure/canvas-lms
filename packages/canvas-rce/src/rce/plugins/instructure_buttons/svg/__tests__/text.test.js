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

import sinon from 'sinon'

import {buildText, buildTextBackground, getContainerWidth, getContainerHeight} from '../text'
import {DEFAULT_SETTINGS} from '../constants'

let settings

describe('buildText()', () => {
  beforeEach(() => {
    settings = {...DEFAULT_SETTINGS, text: 'Hello World!'}
  })

  it('builds <text /> if text is valid', () => {
    expect(buildText({...settings})).toMatchInlineSnapshot(`
      <text
        fill="#000000"
        font-family="Lato Extended"
        font-size="14"
        font-weight="bold"
        x="55"
        y="68"
      >
        <tspan
          dy="0"
          x="55"
        >
          Hello World!
        </tspan>
      </text>
    `)
  })

  it('builds <text /> if text is must be multiline', () => {
    const text =
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed eiusmod tempor incidunt ut labore et dolore magna aliqua.'
    expect(buildText({...settings, text})).toMatchInlineSnapshot(`
      <text
        fill="#000000"
        font-family="Lato Extended"
        font-size="14"
        font-weight="bold"
        x="47"
        y="68"
      >
        <tspan
          dy="0"
          x="50"
        >
          Lorem ipsum dolor sit
        </tspan>
        <tspan
          dy="14"
          x="47"
        >
          amet, consectetur adipiscing
        </tspan>
        <tspan
          dy="14"
          x="49"
        >
          elit, sed eiusmod tempor
        </tspan>
        <tspan
          dy="14"
          x="50"
        >
          incidunt ut labore et
        </tspan>
        <tspan
          dy="14"
          x="51"
        >
          dolore magna aliqua.
        </tspan>
      </text>
    `)
  })

  it('does not build <text /> if text is empty', () => {
    expect(buildText({...settings, text: ''})).toBeNull()
  })

  it('does not build <text /> if text has spaces', () => {
    expect(buildText({...settings, text: '  '})).toBeNull()
  })

  describe('builds <text /> when text size', () => {
    it('is small', () => {
      expect(buildText({...settings, textSize: 'small'})).toMatchInlineSnapshot(`
        <text
          fill="#000000"
          font-family="Lato Extended"
          font-size="14"
          font-weight="bold"
          x="55"
          y="68"
        >
          <tspan
            dy="0"
            x="55"
          >
            Hello World!
          </tspan>
        </text>
      `)
    })

    it('is medium', () => {
      expect(buildText({...settings, textSize: 'medium'})).toMatchInlineSnapshot(`
        <text
          fill="#000000"
          font-family="Lato Extended"
          font-size="16"
          font-weight="bold"
          x="55"
          y="69"
        >
          <tspan
            dy="0"
            x="55"
          >
            Hello World!
          </tspan>
        </text>
      `)
    })

    it('is large', () => {
      expect(buildText({...settings, textSize: 'large'})).toMatchInlineSnapshot(`
        <text
          fill="#000000"
          font-family="Lato Extended"
          font-size="22"
          font-weight="bold"
          x="55"
          y="72"
        >
          <tspan
            dy="0"
            x="55"
          >
            Hello World!
          </tspan>
        </text>
      `)
    })

    it('is x-large', () => {
      expect(buildText({...settings, textSize: 'x-large'})).toMatchInlineSnapshot(`
        <text
          fill="#000000"
          font-family="Lato Extended"
          font-size="28"
          font-weight="bold"
          x="55"
          y="75"
        >
          <tspan
            dy="0"
            x="55"
          >
            Hello World!
          </tspan>
        </text>
      `)
    })
  })

  describe('builds <text /> when text color', () => {
    it('is null', () => {
      expect(buildText({...settings, textColor: null})).toMatchInlineSnapshot(`
        <text
          fill=""
          font-family="Lato Extended"
          font-size="14"
          font-weight="bold"
          x="55"
          y="68"
        >
          <tspan
            dy="0"
            x="55"
          >
            Hello World!
          </tspan>
        </text>
      `)
    })

    it('is valid', () => {
      expect(buildText({...settings, textColor: '#f00'})).toMatchInlineSnapshot(`
        <text
          fill="#f00"
          font-family="Lato Extended"
          font-size="14"
          font-weight="bold"
          x="55"
          y="68"
        >
          <tspan
            dy="0"
            x="55"
          >
            Hello World!
          </tspan>
        </text>
      `)
    })
  })

  describe('builds <text /> when text background color', () => {
    it('is null', () => {
      expect(buildText({...settings, textBackgroundColor: null})).toMatchInlineSnapshot(`
        <text
          fill="#000000"
          font-family="Lato Extended"
          font-size="14"
          font-weight="bold"
          x="55"
          y="68"
        >
          <tspan
            dy="0"
            x="55"
          >
            Hello World!
          </tspan>
        </text>
      `)
    })

    it('is valid', () => {
      expect(buildText({...settings, textBackgroundColor: '#f00'})).toMatchInlineSnapshot(`
        <text
          fill="#000000"
          font-family="Lato Extended"
          font-size="14"
          font-weight="bold"
          x="55"
          y="68"
        >
          <tspan
            dy="0"
            x="55"
          >
            Hello World!
          </tspan>
        </text>
      `)
    })
  })

  describe('builds <text /> when text position', () => {
    it('is middle', () => {
      expect(buildText({...settings, textPosition: 'middle'})).toMatchInlineSnapshot(`
        <text
          fill="#000000"
          font-family="Lato Extended"
          font-size="14"
          font-weight="bold"
          x="55"
          y="68"
        >
          <tspan
            dy="0"
            x="55"
          >
            Hello World!
          </tspan>
        </text>
      `)
    })

    it('is bottom-third', () => {
      expect(buildText({...settings, textPosition: 'bottom-third'})).toMatchInlineSnapshot(`
        <text
          fill="#000000"
          font-family="Lato Extended"
          font-size="14"
          font-weight="bold"
          x="55"
          y="125"
        >
          <tspan
            dy="0"
            x="55"
          >
            Hello World!
          </tspan>
        </text>
      `)
    })

    it('is below', () => {
      expect(buildText({...settings, textPosition: 'below'})).toMatchInlineSnapshot(`
        <text
          fill="#000000"
          font-family="Lato Extended"
          font-size="14"
          font-weight="bold"
          x="55"
          y="144"
        >
          <tspan
            dy="0"
            x="55"
          >
            Hello World!
          </tspan>
        </text>
      `)
    })
  })
})

describe('buildTextBackground()', () => {
  beforeEach(() => {
    settings = DEFAULT_SETTINGS
  })

  it('builds <path /> if text is valid', () => {
    expect(buildTextBackground({...settings, text: 'Hello World!'})).toMatchInlineSnapshot(`
      <path
        d="M55,52 h14 a4,4 0 0 1 4,4 v16 a4,4 0 0 1 -4,4 h-14 a4,4 0 0 1 -4,-4 v-16 a4,4 0 0 1 4,-4 z"
        fill=""
      />
    `)
  })

  it('does not build <path /> if text is empty', () => {
    expect(buildTextBackground({...settings, text: ''})).toBeNull()
  })

  it('does not build <path /> if text has spaces', () => {
    expect(buildTextBackground({...settings, text: '  '})).toBeNull()
  })
})

describe('getContainerWidth()', () => {
  beforeEach(() => {
    settings = DEFAULT_SETTINGS
  })

  it('returns base size if is greater', () => {
    expect(getContainerWidth({...settings, text: 'Hello World!'})).toBe(122)
  })

  it('returns text width if is greater', () => {
    sinon.stub(document, 'createElement').returns({
      getContext: () => ({
        measureText: text => ({
          width: text.length * 5
        })
      })
    })
    expect(getContainerWidth({...settings, text: 'This is a long text for testing'})).toBe(125)
    document.createElement.reset()
  })
})

describe('getContainerHeight()', () => {
  beforeEach(() => {
    settings = DEFAULT_SETTINGS
  })

  it('returns base size if is greater', () => {
    expect(getContainerHeight({...settings, text: 'Hello World!'})).toBe(122)
  })

  it('returns text background height if is greater', () => {
    const text =
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed eiusmod tempor incidunt ut labore et dolore magna aliqua.'
    expect(getContainerHeight({...settings, text})).toBe(142)
  })
})
