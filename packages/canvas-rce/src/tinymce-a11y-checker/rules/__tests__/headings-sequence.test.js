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

import rule from '../headings-sequence'

let h2
let body

beforeEach(() => {
  body = document.createElement('body')
  h2 = document.createElement('h2')
  body.appendChild(h2)
})

describe('test', () => {
  test('returns false if previous heading is not sequential', () => {
    const h4 = document.createElement('H4')
    body.appendChild(h4)
    expect(rule.test(h4)).toBeFalsy()
  })

  test('returns true if H2-H6 and top of document', () => {
    expect(rule.test(h2)).toBeTruthy()
  })

  test('return true if previous heading is sequential', () => {
    const h3 = document.createElement('H3')
    body.appendChild(h3)
    expect(rule.test(h3)).toBeTruthy()
  })

  test('return true if H1', () => {
    const h1 = document.createElement('h1')
    expect(rule.test(h1)).toBeTruthy()
  })

  test('return true on non-h tag', () => {
    const div = document.createElement('div')
    expect(rule.test(div)).toBeTruthy()
  })
})

describe('data', () => {
  test("default action is 'nothing'", () => {
    expect(rule.data().action).toBe('nothing')
  })
})

describe('form', () => {
  test("form has dataKey of 'action'", () => {
    expect(rule.form()[0].dataKey).toBe('action')
  })
})

describe('update', () => {
  test('returns same element', () => {
    expect(rule.update(h2, {})).toBe(h2)
  })

  test("returns different h element on 'elem' action", () => {
    const h4 = document.createElement('h4')
    body.appendChild(h4)
    expect(rule.update(h4, {action: 'elem'}).tagName).toBe('H3')
  })

  test("returns p element on 'modify' action", () => {
    expect(rule.update(h2, {action: 'modify'}).tagName).toBe('P')
  })

  test("returns h1 element on 'modify' and prior elem unassigned", () => {
    expect(rule.update(h2, {action: 'elem'}).tagName).toBe('H1')
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

describe('linkText', () => {
  test('returns the proper linkText message', () => {
    expect(rule.linkText()).toMatchSnapshot()
  })
})
