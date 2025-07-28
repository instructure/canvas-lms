// Copyright (C) 2024 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import {getVisibleTextContent, up} from '../installNodeDecorations'

describe('getVisibleTextContent() utility', () => {
  it('returns text content for a simple element', () => {
    const div = document.createElement('div')
    div.textContent = 'Visible Text'
    expect(getVisibleTextContent(div)).toBe('Visible Text')
  })

  it('excludes text content of hidden elements', () => {
    const div = document.createElement('div')
    div.innerHTML =
      '<span> Visible </span><span>Text</span> <span style="display:none;"> Hidden Text </span>'
    expect(getVisibleTextContent(div)).toBe('Visible Text')
  })

  it('returns concatenated text content of nested elements', () => {
    const div = document.createElement('div')
    div.innerHTML = '<span>Visible</span> <span>Text</span>'
    expect(getVisibleTextContent(div)).toBe('Visible Text')
  })

  it('excludes text content of elements with screenreader-only class', () => {
    const div = document.createElement('div')
    div.innerHTML =
      '<span>Visible Text</span><span class="screenreader-only">Screenreader Only Text</span>'
    const screenReaderOnlyElement = div.querySelector('.screenreader-only') as HTMLElement
    screenReaderOnlyElement.style.display = 'none'
    expect(getVisibleTextContent(div)).toBe('Visible Text')
  })
})

describe('up() installer', () => {
  it('is idempotent and defines the innerText property at most once', () => {
    // Our initializers are automagically run by Jest, so assert the state we expect.
    expect(typeof Object.getOwnPropertyDescriptor(Node.prototype, 'innerText')!.get).toBe(
      'function'
    )

    expect(() => up()).not.toThrow()
  })
})
