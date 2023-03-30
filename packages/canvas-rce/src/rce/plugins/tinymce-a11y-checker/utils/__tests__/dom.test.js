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

import * as dom from '../dom'

test('walk calls function with each child element depth first', () => {
  document.body.innerHTML = `
    <div>
      <h1>Test Heading</h1>
      <p>Test <a href="">Link</a></p>
      <h2>Test Subheading</h2>
    </div>
  `
  const nodeNames = []
  const fn = node => nodeNames.push(node.nodeName)
  dom.walk(document.body, fn)
  expect(nodeNames).toEqual(['DIV', 'H1', 'P', 'A', 'H2'])
})

describe('select', () => {
  let node, doc, range, sel, indicateFn

  beforeEach(() => {
    range = {selectNode: jest.fn()}
    sel = {addRange: jest.fn(), removeAllRanges: jest.fn()}
    doc = {createRange: () => range, getSelection: () => sel}
    node = {scrollIntoView: jest.fn(), ownerDocument: doc, childNodes: []}
    indicateFn = jest.fn()
  })

  test('scrolls the node into view', () => {
    dom.select(node, indicateFn)
    expect(node.scrollIntoView).toHaveBeenCalled()
  })
  test('calls the indicator function with the node', () => {
    dom.select(node, indicateFn)
    expect(indicateFn).toHaveBeenCalledWith(node)
  })

  test('select does not throw if node is underfined or null', () => {
    dom.select(undefined)
    dom.select(null)
  })
})

describe('pathForNode', () => {
  test('returns empty array of ancestor and decendant are the same', () => {
    const elem = document.createElement('div')
    expect(dom.pathForNode(elem, elem)).toEqual([])
  })

  test('returns null if decendant is not a decendant of ancestor', () => {
    const a = document.createElement('div')
    const b = document.createElement('div')
    expect(dom.pathForNode(a, b)).toBe(null)
  })

  test('returns array with single index if direct child', () => {
    const a = document.createElement('div')
    const b = document.createElement('div')
    a.appendChild(document.createElement('div'))
    a.appendChild(b)
    expect(dom.pathForNode(a, b)).toEqual([1])
  })

  test('returns full index path for nested decendant', () => {
    const a = document.createElement('div')
    const b = document.createElement('div')
    const c = document.createElement('div')
    a.appendChild(document.createElement('div'))
    a.appendChild(b)
    b.appendChild(document.createElement('div'))
    b.appendChild(document.createElement('div'))
    b.appendChild(c)
    expect(dom.pathForNode(a, c)).toEqual([2, 1])
  })
})

describe('nodeByPath', () => {
  test('returns ancestor path is empty array', () => {
    const elem = document.createElement('div')
    expect(dom.nodeByPath(elem, [])).toBe(elem)
  })

  test('returns null if any path index is out of range', () => {
    const elem = document.createElement('div')
    elem.appendChild(document.createElement('div'))
    expect(dom.nodeByPath(elem, [1])).toBe(null)
  })

  test('returns nested decendant by path', () => {
    const a = document.createElement('div')
    const b = document.createElement('div')
    const c = document.createElement('div')
    a.appendChild(document.createElement('div'))
    a.appendChild(b)
    b.appendChild(document.createElement('div'))
    b.appendChild(document.createElement('div'))
    b.appendChild(c)
    expect(dom.nodeByPath(a, [2, 1])).toBe(c)
  })
})

describe('onlyContainsLink', () => {
  test('returns true when a link is the only text present', () => {
    const elem = document.createElement('div')
    const link = document.createElement('a')
    link.setAttribute('href', 'http://example.com')
    link.textContent = 'Example Site'
    elem.appendChild(link)
    expect(dom.onlyContainsLink(elem)).toBe(true)
  })

  test('returns true when a link is deeply nested', () => {
    const elem = document.createElement('div')
    const elem1 = document.createElement('div')
    const elem2 = document.createElement('div')
    const elem3 = document.createElement('span')
    const link = document.createElement('a')
    elem3.appendChild(link)
    elem2.appendChild(elem3)
    elem1.appendChild(elem2)
    elem.appendChild(elem1)
    expect(dom.onlyContainsLink(elem)).toBe(true)
  })

  test('returns false when there are no links', () => {
    const elem = document.createElement('div')
    elem.textContent = "I'm just some text, not a link"
    expect(dom.onlyContainsLink(elem)).toBe(false)
  })
})

describe('splitStyleAttribute', () => {
  test('creates an object with key values', () => {
    expect(dom.splitStyleAttribute('background-color: #000000; color: #ffffff;')).toMatchObject({
      'background-color': '#000000',
      color: '#ffffff',
    })
  })

  test('returns an empty object when given an empty string', () => {
    expect(dom.splitStyleAttribute('')).toEqual({})
  })
})

describe('createStyleString', () => {
  test('creates a style string given a style object', () => {
    expect(dom.createStyleString({'background-color': '#000000', color: '#ffffff'})).toBe(
      'background-color:#000000;color:#ffffff;'
    )
  })

  test('returns an empty string when given an empty object', () => {
    expect(dom.createStyleString({})).toBe('')
  })
})

describe('hasTextNode', () => {
  test('returns true when the element has a text node child', () => {
    const elem = document.createElement('div')
    elem.appendChild(document.createElement('span'))
    elem.appendChild(document.createTextNode('text me'))
    expect(dom.hasTextNode(elem)).toBe(true)
  })

  test('returns false when the element has no text node children', () => {
    const elem = document.createElement('div')
    elem.appendChild(document.createElement('span'))
    elem.appendChild(document.createElement('span'))
    expect(dom.hasTextNode(elem)).toBe(false)
  })
})
