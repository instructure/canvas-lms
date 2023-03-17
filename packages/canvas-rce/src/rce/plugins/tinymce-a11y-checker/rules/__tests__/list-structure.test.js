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

import rule from '../list-structure'

let body, p1, p2, p3

beforeEach(() => {
  body = document.createElement('body')

  p1 = document.createElement('p')
  p2 = document.createElement('p')
  p3 = document.createElement('p')

  body.appendChild(p1)
  body.appendChild(p2)
  body.appendChild(p3)

  p1.textContent = 'Normal Paragraph'
  p2.textContent = '1. List'
  p3.textContent = '2. List'
})

describe('test', () => {
  test('returns true if not P element', () => {
    expect(rule.test(document.createElement('div'))).toBeTruthy()
  })

  test('returns true if a normal paragraph', () => {
    expect(rule.test(p1)).toBeTruthy()
  })

  test('returns true if previous node is also list-like', () => {
    expect(rule.test(p3)).toBeTruthy()
  })

  test('returns false if ol-like', () => {
    expect(rule.test(p2)).toBeFalsy()
  })

  test('returns true if ol-like but item label is more than 4 chars', () => {
    p1.textContent = '12345. list like'
    p2.textContent = 'ABCDE. list like'
    p3.textContent = 'abcde) list like'
    expect(rule.test(p1)).toBeTruthy()
    expect(rule.test(p2)).toBeTruthy()
    expect(rule.test(p3)).toBeTruthy()
  })

  test('returns false if li-like', () => {
    p2.textContent = ' * List'
    p3.textContent = ' * List'
    expect(rule.test(p2)).toBeFalsy()
  })
})

describe('data', () => {
  test('returns the proper object', () => {
    expect(rule.data(p2)).toMatchSnapshot()
  })
})

describe('form', () => {
  test('returns the proper object', () => {
    expect(rule.form(p2)).toMatchSnapshot()
  })
})

describe('update', () => {
  test('returns same element', () => {
    expect(rule.update(p1, {})).toBe(p1)
  })

  test('Resolves ordered items with followed by a period', () => {
    p1.textContent = '1. List'
    p2.textContent = '2. List'
    p3.textContent = '3. List'

    rule.update(p1, {...rule.data(p1), formatAsList: true})

    expect(body.firstChild.tagName).toBe('OL')
    expect(body.firstChild.children.length).toBe(3)
    expect(
      [...body.firstChild.children].every(child => child.textContent.trim() === 'List')
    ).toBeTruthy()
  })

  test('Resolves ordered items with followed by parentheses', () => {
    p1.textContent = '1) List'
    p2.textContent = '2) List'
    p3.textContent = '3) List'

    rule.update(p1, {...rule.data(p1), formatAsList: true})

    expect(body.firstChild.tagName).toBe('OL')
    expect(body.firstChild.children.length).toBe(3)
    expect(
      [...body.firstChild.children].every(child => child.textContent.trim() === 'List')
    ).toBeTruthy()
  })

  test('Resolves unordered items with preceded by an asterisk', () => {
    p1.textContent = '* List'
    p2.textContent = '* List'
    p3.textContent = '* List'

    rule.update(p1, {...rule.data(p1), formatAsList: true})

    expect(body.firstChild.tagName).toBe('UL')
    expect(body.firstChild.children.length).toBe(3)
    expect(
      [...body.firstChild.children].every(child => child.textContent.trim() === 'List')
    ).toBeTruthy()
  })

  test('Resolves unordered items with preceded by a hyphen', () => {
    p1.textContent = '- List'
    p2.textContent = '- List'
    p3.textContent = '- List'

    rule.update(p1, {...rule.data(p1), formatAsList: true})

    expect(body.firstChild.tagName).toBe('UL')
    expect(body.firstChild.children.length).toBe(3)
    expect(
      [...body.firstChild.children].every(child => child.textContent.trim() === 'List')
    ).toBeTruthy()
  })

  test('Resolves items regardless of whitespace', () => {
    p1.textContent = '  - List'
    p2.textContent = '    -   List'
    p3.textContent = '  -   List'

    rule.update(p1, {...rule.data(p1), formatAsList: true})

    expect(body.firstChild.tagName).toBe('UL')
    expect(body.firstChild.children.length).toBe(3)
    expect(
      [...body.firstChild.children].every(child => child.textContent.trim() === 'List')
    ).toBeTruthy()
  })

  test('Resolves ordered with a start attribute', () => {
    p1.textContent = '3. List'
    p2.textContent = '4. List'
    p3.textContent = '5. List'

    rule.update(p1, {...rule.data(p1), formatAsList: true})

    expect(body.firstChild.tagName).toBe('OL')
    expect(body.firstChild.getAttribute('start')).toBe('3')
    expect(body.firstChild.children.length).toBe(3)
    expect(
      [...body.firstChild.children].every(child => child.textContent.trim() === 'List')
    ).toBeTruthy()
  })

  test('Replaces the ordered part of the list even when nested in an element', () => {
    p1.innerHTML = '<strong>1. Text</strong> Text'
    p2.innerHTML = '<strong>2. Text</strong> Text'
    p3.innerHTML = '<strong>3. Text</strong> Text'

    rule.update(p1, {...rule.data(p1), formatAsList: true})

    expect(body.firstChild.tagName).toBe('OL')
    expect(body.firstChild.children.length).toBe(3)
    expect(
      [...body.firstChild.children].every(
        child => child.textContent === 'Text Text' && child.firstChild.tagName === 'STRONG'
      )
    ).toBeTruthy()
  })

  test('Replaces bullets/numbers even when it is not in the first child', () => {
    p1.innerHTML = '<div></div>1. List'
    p2.innerHTML = '<div></div>2. List'
    p3.innerHTML = '<div></div>3. List'

    rule.update(p1, {...rule.data(p1), formatAsList: true})

    expect(body.firstChild.tagName).toBe('OL')
    expect(body.firstChild.children.length).toBe(3)
    expect(
      [...body.firstChild.children].every(
        child => child.textContent === 'List' && child.firstChild.tagName === 'DIV'
      )
    ).toBeTruthy()
  })

  test('Stops creating list items if a paragraph is not list-like', () => {
    p1.innerHTML = '1. List'
    p2.innerHTML = '2. List'
    p3.innerHTML = 'Normal Paragraph'

    rule.update(p1, {...rule.data(p1), formatAsList: true})

    expect(body.firstChild.tagName).toBe('OL')
    expect(body.firstChild.children.length).toBe(2)
    expect(
      [...body.firstChild.children].every(child => child.textContent.trim() === 'List')
    ).toBeTruthy()
  })

  test('Stops creating list items if a paragraph is a different type of list', () => {
    p1.innerHTML = '1. List'
    p2.innerHTML = '2. List'
    p3.innerHTML = '* List'

    rule.update(p1, {...rule.data(p1), formatAsList: true})

    expect(body.firstChild.tagName).toBe('OL')
    expect(body.firstChild.children.length).toBe(2)
    expect(
      [...body.firstChild.children].every(child => child.textContent.trim() === 'List')
    ).toBeTruthy()
    expect(body.children[1].tagName).toBe('P')
    expect(body.children[1].textContent).toBe('* List')
  })

  test('Splits paragraphs by <br>', () => {
    p1.innerHTML = '1. List <br> 2. List'
    p2.innerHTML = '3. List'
    p3.innerHTML = '4. List'

    rule.update(p1, {...rule.data(p1), formatAsList: true})

    expect(body.firstChild.tagName).toBe('OL')
    expect(body.firstChild.children.length).toBe(4)
    expect(
      [...body.firstChild.children].every(child => child.textContent.trim() === 'List')
    ).toBeTruthy()
  })
})

describe('rootNode', () => {
  test('returns the parentNode of an element', () => {
    expect(rule.rootNode(p1).tagName).toBe('BODY')
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
