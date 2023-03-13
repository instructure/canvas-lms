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

import rule from '../paragraphs-for-headings'

let el

beforeEach(() => {
  el = document.createElement('h2')
})

describe('test', () => {
  test('return true on non-H? element', () => {
    expect(rule.test(document.createElement('div'))).toBeTruthy()
  })

  test('returns false if the heading is > 120 characters', () => {
    const moreThanMaxString = Array(122).join('x')

    el.appendChild(document.createTextNode(moreThanMaxString))
    expect(rule.test(el)).toBeFalsy()
  })

  test('return true if the heading is less than the max', () => {
    const lessThanMaxString = 'x'
    el.appendChild(document.createTextNode(lessThanMaxString))
    expect(rule.test(el)).toBeTruthy()
  })
})

describe('data', () => {
  test('returns the proper object', () => {
    expect(rule.data()).toMatchSnapshot()
  })
})

describe('form', () => {
  test('returns the appropriate object', () => {
    expect(rule.form()).toMatchSnapshot()
  })
})

describe('update', () => {
  test('returns same element', () => {
    expect(rule.update(el, {})).toBe(el)
  })

  test("returns P elment if 'change' is true", () => {
    document.createElement('body').appendChild(el)
    expect(rule.update(el, {change: true}).tagName).toBe('P')
  })
})

describe('message', () => {
  test('returns the proper message', () => {
    expect(rule.message()).toMatchSnapshot()
  })
})

describe('why', () => {
  test('returns the proper why message', () => {
    expect(rule.why()).toMatchSnapshot()
  })
})
