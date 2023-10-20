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

import rule from '../img-alt-filename'

let el

beforeEach(() => {
  el = document.createElement('img')
  el.setAttribute('src', '/file.png')
})

describe('test', () => {
  test('returns true if alt text is missing', () => {
    expect(rule.test(el)).toBeTruthy()
  })

  test('returns true if not img tag', () => {
    expect(rule.test(el)).toBeTruthy()
  })

  test('returns true if alt text is empty', () => {
    el.setAttribute('alt', '')
    expect(rule.test(el)).toBeTruthy()
  })

  test('returns true if alt text is not filename', () => {
    el.setAttribute('alt', 'some text')
    expect(rule.test(el)).toBeTruthy()
  })

  test('returns false if alt text is an image filename', () => {
    const imageFileExtensions = ['jpg', 'jpeg', 'png', 'gif', 'svg', 'bmp', 'webp']
    imageFileExtensions.forEach(fileExtension => {
      el.setAttribute('alt', `file.${fileExtension}`)
      expect(rule.test(el)).toBeFalsy()

      el.setAttribute('alt', `FILE.${fileExtension.toUpperCase()}`)
      expect(rule.test(el)).toBeFalsy()
    })
  })

  test('returns true if alt text is formatted as filename but has no image extension', () => {
    el.setAttribute('alt', 'file.test')
    expect(rule.test(el)).toBeTruthy()
  })

  test('returns false if alt text is filename with blank spaces', () => {
    el.setAttribute('alt', 'file with blank.png')
    expect(rule.test(el)).toBeFalsy()
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

  test('returns decorative true if el has empty alt attribute', () => {
    el.setAttribute('alt', '')
    expect(rule.data(el).decorative).toBeTruthy()
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

  test('changes alt text if not decorative', () => {
    const text = 'this is my text'
    el.setAttribute('alt', 'thisismy.png')
    expect(rule.update(el, {alt: text, decorative: false}).getAttribute('alt')).toBe(text)
  })

  test('removes role if not decorative', () => {
    const text = 'this is my text'
    rule.update(el, {alt: text, decorative: false})
    expect(el.hasAttribute('role')).toBeFalsy()
    expect(el.getAttribute('alt')).toBe(text)
  })

  test('sets alt text to empty and role if decorative', () => {
    rule.update(el, {decorative: true})
    expect(el.getAttribute('role')).toBe('presentation')
    expect(el.getAttribute('alt')).toBe('')
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
  test('returns the proper why message', () => {
    expect(rule.linkText()).toMatchSnapshot()
  })
})
