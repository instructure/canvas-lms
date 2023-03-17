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

import fn from '../describe'

test('describes an image', () => {
  const elem = document.createElement('img')
  elem.src = 'http://someurl.com/path/to/image.jpg?foo=bar'
  expect(fn(elem)).toBe('Image with filename image.jpg')
})

test('describes a table', () => {
  const elem = document.createElement('table')
  elem.innerHTML = `
    <caption>This is</caption
    <tr>
      <td>a</td>
      <td>test</td>
      <td>table</td>
    </tr>
  `
  expect(fn(elem)).toBe('Table starting with This is a test…')
})

test('describes a link', () => {
  const elem = document.createElement('a')
  elem.textContent = 'something'
  expect(fn(elem)).toBe('Link with text starting with something')
})

test('describes a paragraph', () => {
  const elem = document.createElement('p')
  elem.textContent = 'This is the text of a paragraph.'
  expect(fn(elem)).toBe('Paragraph starting with This is the text…')
})

test('describes a table header', () => {
  const elem = document.createElement('th')
  elem.textContent = 'This is the text of a table header.'
  expect(fn(elem)).toBe('Table header starting with This is the text…')
})

test('describes a h1', () => {
  const elem = document.createElement('h1')
  elem.textContent = 'This is a heading'
  expect(fn(elem)).toBe('Heading starting with This is a heading')
})

test('describes a h2', () => {
  const elem = document.createElement('h2')
  elem.textContent = 'This is a heading'
  expect(fn(elem)).toBe('Heading starting with This is a heading')
})

test('describes a h3', () => {
  const elem = document.createElement('h3')
  elem.textContent = 'This is a heading'
  expect(fn(elem)).toBe('Heading starting with This is a heading')
})

test('describes a h4', () => {
  const elem = document.createElement('h4')
  elem.textContent = 'This is a heading'
  expect(fn(elem)).toBe('Heading starting with This is a heading')
})

test('describes a h5', () => {
  const elem = document.createElement('h5')
  elem.textContent = 'This is a heading'
  expect(fn(elem)).toBe('Heading starting with This is a heading')
})

test('describes other elements', () => {
  const elem = document.createElement('div')
  elem.textContent = 'This is the text of an element.'
  expect(fn(elem)).toBe('Element starting with This is the text…')
})

test("returns null when there isn't a valid element", () => {
  const elem = undefined
  expect(fn(elem)).toBe(null)
})
