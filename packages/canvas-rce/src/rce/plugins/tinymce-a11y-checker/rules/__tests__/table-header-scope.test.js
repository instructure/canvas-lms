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

import rule from '../table-header-scope'

let el

beforeEach(() => {
  el = document.createElement('th')
})

describe('test', () => {
  test('returns true if the element is not a th', () => {
    const elem = document.createElement('td')
    expect(rule.test(elem)).toBe(true)
  })

  test('returns true if the scope attribute is valid', () => {
    el.setAttribute('scope', 'row')
    expect(rule.test(el)).toBe(true)
    el.setAttribute('scope', 'col')
    expect(rule.test(el)).toBe(true)
    el.setAttribute('scope', 'rowgroup')
    expect(rule.test(el)).toBe(true)
    el.setAttribute('scope', 'colgroup')
    expect(rule.test(el)).toBe(true)
  })

  test('returns false if the scope attribute is not valid', () => {
    el.setAttribute('scope', 'invalid')
    expect(rule.test(el)).toBe(false)
  })

  test('returns false if there is no scope', () => {
    expect(rule.test(el)).toBe(false)
  })
})

describe('data', () => {
  test('returns the existing scope if present', () => {
    el.setAttribute('scope', 'colgroup')
    expect(rule.data(el)).toEqual({scope: 'colgroup'})
  })

  test('returns none if there is no existing scope', () => {
    expect(rule.data(el)).toEqual({scope: 'none'})
  })
})

describe('form', () => {
  test('returns the proper object', () => {
    expect(rule.form()).toMatchSnapshot()
  })
})

describe('update', () => {
  test('returns same element', () => {
    expect(rule.update(el, {})).toBe(el)
  })

  test('removes scope attribute when header === none', () => {
    el.setAttribute('scope', 'colgroup')
    rule.update(el, {header: 'none'})
    expect(el.getAttribute('scope')).toBeFalsy()
  })

  test('sets the scope attribute based on the scope property', () => {
    rule.update(el, {scope: 'col'})
    expect(el.getAttribute('scope')).toBe('col')
  })
})

describe('message', () => {
  test('returns the proper message', () => {
    expect(rule.message()).toMatchSnapshot()
  })
})

describe('why', () => {
  test('returns the proper message', () => {
    expect(rule.why()).toMatchSnapshot()
  })
})

describe('linkText', () => {
  test('returns the proper linkText message', () => {
    expect(rule.linkText()).toMatchSnapshot()
  })
})
