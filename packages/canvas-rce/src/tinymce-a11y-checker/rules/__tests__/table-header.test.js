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

import rule from '../table-header'

let el

beforeEach(() => {
  el = document.createElement('table')
})

describe('test', () => {
  test('returns true if the element is not a table', () => {
    const elem = document.createElement('div')
    expect(rule.test(elem)).toBe(true)
  })

  test('returns falsy if the element is a table, but has no th', () => {
    expect(rule.test(el)).toBeFalsy()
  })

  test('returns truthy if the table contains a th', () => {
    el.appendChild(document.createElement('th'))
    expect(rule.test(el)).toBeTruthy()
  })
})

describe('data', () => {
  test('returns the proper object', () => {
    expect(rule.data()).toMatchSnapshot()
  })
})

describe('form', () => {
  test('returns the proper object', () => {
    expect(rule.form()).toMatchSnapshot()
  })
})

describe('update', () => {
  beforeEach(() => {
    const tr = document.createElement('tr')
    tr.appendChild(document.createElement('td'))
    tr.appendChild(document.createElement('td'))
    tr.appendChild(document.createElement('td'))
    const tr2 = document.createElement('tr')
    tr2.appendChild(document.createElement('td'))
    tr2.appendChild(document.createElement('td'))
    tr2.appendChild(document.createElement('td'))
    el.appendChild(tr)
    el.appendChild(tr2)
  })
  test('returns same element', () => {
    expect(rule.update(el, {})).toBe(el)
  })

  describe('header option === none', () => {
    test('returns with only td elements', () => {
      el.appendChild(document.createElement('th'))
      el.appendChild(document.createElement('th'))
      el.appendChild(document.createElement('th'))
      rule.update(el, {header: 'none'})
      expect(el.querySelectorAll('th')).toHaveLength(0)
    })
  })

  describe('header option === row', () => {
    test('changes top row to headers with column scope', () => {
      rule.update(el, {header: 'row'})
      expect(el).toMatchSnapshot()
    })
  })

  describe('header option === col', () => {
    test('changes first column to headers with row scope', () => {
      rule.update(el, {header: 'col'})
      expect(el).toMatchSnapshot()
    })
  })

  describe('header option === both', () => {
    test('adds a header row and a header column', () => {
      rule.update(el, {header: 'both'})
      expect(el).toMatchSnapshot()
    })
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
