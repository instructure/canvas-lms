/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {insert, replace} from '../edit'
import FakeEditor from '@instructure/canvas-rce/src/rce/plugins/shared/__tests__/FakeEditor'

let editor

beforeEach(() => {
  editor = new FakeEditor()

  editor.execCommand = jest.fn()
  editor.execCommand.mockImplementation(function (command, _ui, value) {
    const newElement = document.createElement('span')
    newElement.innerHTML = value
    this._$container.appendChild(newElement)
    return true
  })
})

afterEach(() => {
  jest.resetAllMocks()
})

const returnValueExamples = subject => {
  describe('when the insert succeeds', () => {
    beforeEach(() => editor.execCommand.mockReturnValueOnce(true))

    it('returns true', () => {
      expect(subject()).toEqual(true)
    })
  })

  describe('when the insert fails', () => {
    beforeEach(() => editor.execCommand.mockReturnValueOnce(false))

    it('returns false', () => {
      expect(subject()).toEqual(false)
    })
  })
}

describe('insert()', () => {
  const html = '<p id="new">hello!</p>'

  const subject = () => insert(html, editor)

  it('inserts the content into the editor', () => {
    subject()
    expect(editor.getContainer().querySelector('#new').innerHTML).toEqual('hello!')
  })

  returnValueExamples(subject)
})

describe('replace()', () => {
  const html = '<p id="new">new html!</p>'

  const subject = () => replace('#test', html, editor)

  beforeEach(() => {
    editor.setContent('<div id="test"></div>')
  })

  it('deletes the element that should be replaced', () => {
    expect(editor.getContainer().querySelector('#test')).not.toBeNull()
    subject()
    expect(editor.getContainer().querySelector('#test')).toBeNull()
  })

  it('inserts the new html', () => {
    subject()
    expect(editor.getContainer().querySelector('#new').innerHTML).toEqual('new html!')
  })

  returnValueExamples(subject)
})
