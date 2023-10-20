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

import rule from '../large-text-contrast'

let el

beforeEach(() => {
  el = document.createElement('div')
})

describe('test', () => {
  test('returns true if element does not contain any  text', () => {
    const elem = document.createElement('div')
    elem.style.fontSize = '30px'
    elem.style.backgroundColor = '#fff'
    elem.style.color = '#fff'
    expect(rule.test(elem)).toBe(true)
  })

  test('returns true if disabled by the config', () => {
    const elem = document.createElement('div')
    elem.style.fontSize = '30px'
    elem.style.backgroundColor = '#fff'
    elem.style.color = '#fff'
    elem.textContent = 'disabled'
    expect(
      rule.test(elem, {
        disableContrastCheck: true,
      })
    ).toBe(true)
  })

  test('returns true if the only content of a text node is a link', () => {
    const elem = document.createElement('div')
    const link = document.createElement('a')
    elem.style.fontSize = '30px'
    elem.style.backgroundColor = '#fff'
    elem.style.color = '#eee'
    link.setAttribute('href', 'http://example.com')
    link.textContent = 'Example Site'
    elem.appendChild(link)
    expect(rule.test(elem)).toBe(true)
  })

  test('returns true if the element has a background image', () => {
    const elem = document.createElement('div')
    elem.style.fontSize = '30px'
    elem.style.backgroundColor = '#fff'
    elem.style.color = '#000'
    elem.textContent = 'hello'
    elem.style.backgroundImage = 'url(http://example.com)'
    expect(rule.test(elem)).toBe(true)
  })

  test('returns true if the element has a background gradient', () => {
    const elem = document.createElement('div')
    elem.style.fontSize = '30px'
    elem.style.backgroundColor = '#fff'
    elem.style.color = '#000'
    elem.textContent = 'hello'
    elem.style.background = 'linear-gradient(90deg, rgba(33,27,99,1) 70%, rgba(102,40,145,1) 100%)'
    expect(rule.test(elem)).toBe(true)
  })

  test('returns false if large text does not have high enough contrast', () => {
    const elem = document.createElement('div')
    elem.style.fontSize = '30px'
    elem.style.backgroundColor = '#fff'
    elem.style.color = '#eee'
    elem.textContent = 'hello'
    expect(rule.test(elem)).toBe(false)
  })
})

describe('update', () => {
  test('returns same element', () => {
    expect(rule.update(el, {})).toBe(el)
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
