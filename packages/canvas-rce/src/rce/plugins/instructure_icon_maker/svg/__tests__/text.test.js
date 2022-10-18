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
import {BASE_SIZE, DEFAULT_SETTINGS} from '../constants'

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
        y="144"
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

    it('is medium', () => {
      expect(buildText({...settings, textSize: 'medium'})).toMatchInlineSnapshot(`
        <text
          fill="#000000"
          font-family="Lato Extended"
          font-size="16"
          font-weight="bold"
          x="55"
          y="146"
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
          y="152"
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
          y="158"
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

    it('is valid', () => {
      expect(buildText({...settings, textColor: '#f00'})).toMatchInlineSnapshot(`
        <text
          fill="#f00"
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

  describe('builds <text /> when text background color', () => {
    it('is null', () => {
      expect(buildText({...settings, textBackgroundColor: null})).toMatchInlineSnapshot(`
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

    it('is valid', () => {
      expect(buildText({...settings, textBackgroundColor: '#f00'})).toMatchInlineSnapshot(`
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

  describe('builds <text /> when text position', () => {
    describe('is middle', () => {
      it('and it is a single line text', () => {
        expect(buildText({...settings, textPosition: 'middle'})).toMatchInlineSnapshot(`
          <text
            fill="#000000"
            font-family="Lato Extended"
            font-size="14"
            font-weight="bold"
            x="55"
            y="67"
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

      it('and it is a multi line text', () => {
        expect(
          buildText({...settings, text: 'Hello World! Hello World! Bye!', textPosition: 'middle'})
        ).toMatchInlineSnapshot(`
          <text
            fill="#000000"
            font-family="Lato Extended"
            font-size="14"
            font-weight="bold"
            x="48"
            y="60"
          >
            <tspan
              dy="0"
              x="48"
            >
              Hello World! Hello World!
            </tspan>
            <tspan
              dy="14"
              x="59"
            >
              Bye!
            </tspan>
          </text>
        `)
      })
    })

    describe('is bottom-third', () => {
      it('and it is a single line text', () => {
        expect(buildText({...settings, textPosition: 'bottom-third'})).toMatchInlineSnapshot(`
          <text
            fill="#000000"
            font-family="Lato Extended"
            font-size="14"
            font-weight="bold"
            x="55"
            y="121"
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

      it('and it is a multi line text', () => {
        expect(
          buildText({
            ...settings,
            text: 'Hello World! Hello World! Bye!',
            textPosition: 'bottom-third',
          })
        ).toMatchInlineSnapshot(`
          <text
            fill="#000000"
            font-family="Lato Extended"
            font-size="14"
            font-weight="bold"
            x="48"
            y="114"
          >
            <tspan
              dy="0"
              x="48"
            >
              Hello World! Hello World!
            </tspan>
            <tspan
              dy="14"
              x="59"
            >
              Bye!
            </tspan>
          </text>
        `)
      })
    })

    describe('is below', () => {
      it('and it is a single line text', () => {
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

      it('and it is a multi line text', () => {
        expect(
          buildText({...settings, text: 'Hello World! Hello World! Bye!', textPosition: 'below'})
        ).toMatchInlineSnapshot(`
          <text
            fill="#000000"
            font-family="Lato Extended"
            font-size="14"
            font-weight="bold"
            x="48"
            y="144"
          >
            <tspan
              dy="0"
              x="48"
            >
              Hello World! Hello World!
            </tspan>
            <tspan
              dy="14"
              x="59"
            >
              Bye!
            </tspan>
          </text>
        `)
      })
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
        d="M55,127 h14 a4,4 0 0 1 4,4 v16 a4,4 0 0 1 -4,4 h-14 a4,4 0 0 1 -4,-4 v-16 a4,4 0 0 1 4,-4 z"
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

  describe('builds <path /> when text position', () => {
    describe('is middle', () => {
      it('and it is a single line text', () => {
        expect(buildTextBackground({...settings, textPosition: 'middle'})).toMatchInlineSnapshot(
          `null`
        )
      })

      it('and it is a multi line text', () => {
        expect(
          buildTextBackground({
            ...settings,
            text: 'Hello World! Hello World! Bye!',
            textPosition: 'middle',
          })
        ).toMatchInlineSnapshot(`
          <path
            d="M48,43 h27 a4,4 0 0 1 4,4 v30 a4,4 0 0 1 -4,4 h-27 a4,4 0 0 1 -4,-4 v-30 a4,4 0 0 1 4,-4 z"
            fill=""
          />
        `)
      })
    })

    describe('is bottom-third', () => {
      it('and it is a single line text', () => {
        expect(
          buildTextBackground({...settings, textPosition: 'bottom-third'})
        ).toMatchInlineSnapshot(`null`)
      })

      it('and it is a multi line text', () => {
        expect(
          buildTextBackground({
            ...settings,
            text: 'Hello World! Hello World! Bye!',
            textPosition: 'bottom-third',
          })
        ).toMatchInlineSnapshot(`
          <path
            d="M48,97 h27 a4,4 0 0 1 4,4 v30 a4,4 0 0 1 -4,4 h-27 a4,4 0 0 1 -4,-4 v-30 a4,4 0 0 1 4,-4 z"
            fill=""
          />
        `)
      })
    })

    describe('is below', () => {
      it('and it is a single line text', () => {
        expect(buildTextBackground({...settings, textPosition: 'below'})).toMatchInlineSnapshot(
          `null`
        )
      })

      it('and it is a multi line text', () => {
        expect(
          buildTextBackground({
            ...settings,
            text: 'Hello World! Hello World! Bye!',
            textPosition: 'below',
          })
        ).toMatchInlineSnapshot(`
          <path
            d="M48,127 h27 a4,4 0 0 1 4,4 v30 a4,4 0 0 1 -4,4 h-27 a4,4 0 0 1 -4,-4 v-30 a4,4 0 0 1 4,-4 z"
            fill=""
          />
        `)
      })
    })
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
          width: text.length * 5,
        }),
      }),
    })
    expect(getContainerWidth({...settings, text: 'This is a long text for testing'})).toBe(125)
    document.createElement.reset()
  })
})

describe('getContainerHeight()', () => {
  beforeEach(() => {
    settings = DEFAULT_SETTINGS
  })
  it('returns base size for default settings of text empty and textPosition below', () => {
    const expectedHeight = BASE_SIZE[settings.size]
    expect(getContainerHeight({...settings})).toBe(expectedHeight)
  })

  it('returns text background height calculation for non-empty string', () => {
    const text =
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed eiusmod tempor incidunt ut labore et dolore magna aliqua.'
    expect(getContainerHeight({...settings, text})).toBe(208)
  })

  it('returns base size if text field only contains white space', () => {
    const expectedHeight = BASE_SIZE[settings.size]
    const text = '      '
    expect(getContainerHeight({...settings, text})).toBe(expectedHeight)
  })
})
