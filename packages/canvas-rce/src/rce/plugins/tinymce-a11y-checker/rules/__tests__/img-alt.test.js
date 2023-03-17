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

import rule from '../img-alt'

let el

beforeEach(() => {
  el = document.createElement('img')
})

describe('test', () => {
  test('returns true if element is not an image', () => {
    const elem = document.createElement('div')
    expect(rule.test(elem)).toBe(true)
  })

  test('returns true if alt text is not empty', () => {
    el.setAttribute('alt', 'some text')
    expect(rule.test(el)).toBeTruthy()
  })

  test('returns false if no alt attribute', () => {
    expect(rule.test(el)).toBeFalsy()
  })

  test('returns true if alt is empty and not decorative', () => {
    el.setAttribute('alt', '')
    expect(rule.test(el)).toBeTruthy()
  })

  test('returns true for alt containing only white space', () => {
    el.setAttribute('alt', '   ')
    expect(rule.test(el)).toBeTruthy()
  })
})

describe('data', () => {
  test('returns alt text', () => {
    el.setAttribute('alt', 'some text')
    expect(rule.data(el).alt).toBe('some text')
  })

  test('returns empty alt text if no alt attribute', () => {
    expect(rule.data(el).alt).toBe('')
  })

  test('returns decorative true if el has empty alt text', () => {
    el.setAttribute('alt', '')
    expect(rule.data(el).decorative).toBeTruthy()
  })
  test('returns decorative false if el have alt text', () => {
    el.setAttribute('alt', 'some text')
    expect(rule.data(el).decorative).toBeFalsy()
  })
})

describe('form', () => {
  test('alt field is disabled if decorative', () => {
    const altField = rule.form().find(f => f.dataKey === 'alt')
    expect(altField.disabledIf({decorative: true})).toBeTruthy()
  })

  test('alt field is not disabled if not decorative', () => {
    const altField = rule.form().find(f => f.dataKey === 'alt')
    expect(altField.disabledIf({decorative: false})).toBeFalsy()
  })
})

describe('update', () => {
  test('returns same element', () => {
    expect(rule.update(el, {})).toBe(el)
  })

  test("sets alt text to empty and role to 'presentation' if decorative", () => {
    rule.update(el, {decorative: true})
    expect(el.getAttribute('alt')).toBe('')
    expect(el.getAttribute('role')).toBe('presentation')
  })

  test('sets alt text and removes role if not decorative', () => {
    el.setAttribute('alt', '')
    el.setAttribute('role', 'presentation')
    rule.update(el, {decorative: false, alt: 'some text'})
    expect(el.getAttribute('alt')).toBe('some text')
    expect(el.hasAttribute('role')).toBeFalsy()
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
