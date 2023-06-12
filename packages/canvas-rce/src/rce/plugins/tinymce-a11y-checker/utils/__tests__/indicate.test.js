/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import indicate, {
  clearIndicators,
  findChildDepth,
  buildDepthSelector,
  INDICATOR_STYLE,
  A11Y_CHECKER_STYLE_ELEM_ID,
  ensureA11yCheckerStyleElement,
} from '../indicate'

beforeEach(() => {
  document.body.innerHTML = `
  <p id="p1">
    first para
  </p>
  <p id="p2">2nd para</p>
  <p id="p3">
    this is the 3nd para.
    <span id="s1">with first span</span>
    <span id="s2">with 2nd span</span>
    <span id="s3">with 3rd span</span>
    more text
    <span id="s4">target span</span>
    <span id="s5">last span</span>
  </p>`
})

afterEach(() => {
  document.fullscreenElement = null
})

describe('findChildDepth', () => {
  it('finds the depth of a child element in its parent', () => {
    const depth = findChildDepth(document.getElementById('p3'), document.getElementById('s3'))
    expect(depth).toEqual(3)
  })

  it('returns 0 if any arguments are missing', () => {
    expect(findChildDepth(null, document.getElementById('p3'))).toEqual(0)
    expect(findChildDepth(document.getElementById('p3'), null)).toEqual(0)
  })
})

describe('buildDepthSelector', () => {
  it('returns the css selector to the given element', () => {
    const sel = buildDepthSelector(document.getElementById('s3'))
    expect(sel).toEqual('body>:nth-child(3)>:nth-child(3)')
  })
})

describe('indicate', () => {
  it("adds the style element to the head if it doesn't exist", () => {
    expect(document.querySelector('style')).toBe(null)
    indicate(document.getElementById('p1'))
    expect(document.querySelector(`style#${A11Y_CHECKER_STYLE_ELEM_ID}`)).toBeTruthy()
    indicate(document.getElementById('p1'))
    expect(document.querySelectorAll('style').length).toEqual(1)
  })

  it('injects the css into the style element', () => {
    indicate(document.getElementById('s3'))
    expect(document.getElementById(A11Y_CHECKER_STYLE_ELEM_ID).textContent).toEqual(
      `body>:nth-child(3)>:nth-child(3){${INDICATOR_STYLE}}`
    )
  })
})

describe('clearIndicators', () => {
  it('removes the indicator css when called', () => {
    ensureA11yCheckerStyleElement(document)
    clearIndicators(document)
    expect(document.getElementById(A11Y_CHECKER_STYLE_ELEM_ID).textContent).toEqual('')
  })
})
