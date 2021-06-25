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

import {buildGroup, buildSvg, buildSvgWrapper} from '../index'
import {DEFAULT_SETTINGS} from '../constants'

let settings

describe('buildSvg()', () => {
  beforeEach(() => {
    settings = {
      ...DEFAULT_SETTINGS,
      shape: 'circle',
      size: 'large',
      color: '#000',
      outlineColor: '#fff',
      outlineSize: 'large'
    }
  })

  it('builds the whole button svg', () => {
    expect(buildSvg(settings)).toMatchInlineSnapshot(`
      <svg
        fill="none"
        height="218px"
        viewBox="0 0 218 218"
        width="218px"
      >
        <g
          fill="#000"
          stroke="#fff"
          stroke-width="8"
        >
          <circle
            cx="109"
            cy="109"
            r="105"
          />
        </g>
      </svg>
    `)
  })
})

describe('buildSvgWrapper()', () => {
  beforeEach(() => {
    settings = {...DEFAULT_SETTINGS}
  })

  it('builds the <svg /> wrapper when size is x-small', () => {
    expect(buildSvgWrapper({...settings, size: 'x-small'})).toMatchInlineSnapshot(`
      <svg
        fill="none"
        height="74px"
        viewBox="0 0 74 74"
        width="74px"
      />
    `)
  })

  it('builds the <svg /> wrapper when size is small', () => {
    expect(buildSvgWrapper({...settings, size: 'small'})).toMatchInlineSnapshot(`
      <svg
        fill="none"
        height="122px"
        viewBox="0 0 122 122"
        width="122px"
      />
    `)
  })

  it('builds the <svg /> wrapper when size is medium', () => {
    expect(buildSvgWrapper({...settings, size: 'medium'})).toMatchInlineSnapshot(`
      <svg
        fill="none"
        height="158px"
        viewBox="0 0 158 158"
        width="158px"
      />
    `)
  })

  it('builds the <svg /> wrapper when size is large', () => {
    expect(buildSvgWrapper({...settings, size: 'large'})).toMatchInlineSnapshot(`
      <svg
        fill="none"
        height="218px"
        viewBox="0 0 218 218"
        width="218px"
      />
    `)
  })
})

describe('buildGroup()', () => {
  beforeEach(() => {
    settings = {...DEFAULT_SETTINGS, color: '#f00', outlineColor: '#0f0', outlineSize: 'small'}
  })

  it('builds the <g /> element when color is not set', () => {
    settings = {...settings, color: null}
    expect(buildGroup(settings)).toMatchInlineSnapshot(`
      <g
        fill="none"
        stroke="#0f0"
        stroke-width="2"
      />
    `)
  })

  it('builds the <g /> element when color is set', () => {
    expect(buildGroup(settings)).toMatchInlineSnapshot(`
      <g
        fill="#f00"
        stroke="#0f0"
        stroke-width="2"
      />
    `)
  })

  it('builds the <g /> element when outlineColor is not set', () => {
    settings = {...settings, outlineColor: null}
    expect(buildGroup(settings)).toMatchInlineSnapshot(`
      <g
        fill="#f00"
      />
    `)
  })

  describe('when outlineSize is set', () => {
    it('builds the <g /> element when outlineSize is "none"', () => {
      settings = {...settings, outlineSize: 'none'}
      expect(buildGroup(settings)).toMatchInlineSnapshot(`
        <g
          fill="#f00"
          stroke="#0f0"
          stroke-width="0"
        />
      `)
    })

    it('builds the <g /> element when outlineSize is "small"', () => {
      settings = {...settings, outlineSize: 'small'}
      expect(buildGroup(settings)).toMatchInlineSnapshot(`
        <g
          fill="#f00"
          stroke="#0f0"
          stroke-width="2"
        />
      `)
    })

    it('builds the <g /> element when outlineSize is "medium"', () => {
      settings = {...settings, outlineSize: 'medium'}
      expect(buildGroup(settings)).toMatchInlineSnapshot(`
        <g
          fill="#f00"
          stroke="#0f0"
          stroke-width="4"
        />
      `)
    })

    it('builds the <g /> element when outlineSize is "large"', () => {
      settings = {...settings, outlineSize: 'large'}
      expect(buildGroup(settings)).toMatchInlineSnapshot(`
        <g
          fill="#f00"
          stroke="#0f0"
          stroke-width="8"
        />
      `)
    })
  })
})
