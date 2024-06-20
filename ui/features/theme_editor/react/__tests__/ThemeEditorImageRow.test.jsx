/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import React from 'react'
import ReactDOM from 'react-dom'
import ThemeEditorImageRow from '../ThemeEditorImageRow'

let elem, props

describe('ThemeEditorImageRow Component', () => {
  beforeEach(() => {
    elem = document.createElement('div')
    props = {
      varDef: {
        type: 'image',
        accept: 'image/*',
        default: 'default.png',
        human_name: 'Image',
        variable_name: 'image',
      },
      onChange: jest.fn(),
    }
  })

  test('renders with human name heading', () => {
    const expected = 'Human'
    props.varDef.human_name = expected
    ReactDOM.render(<ThemeEditorImageRow {...props} />, elem)
    const subject = elem.getElementsByTagName('h3')[0]
    expect(subject.textContent).toBe(expected)
  })

  test('renders with helper text', () => {
    const expected = 'Halp!'
    props.varDef.helper_text = expected
    ReactDOM.render(<ThemeEditorImageRow {...props} />, elem)
    const subject = elem.getElementsByClassName('Theme__editor-upload_restrictions')[0]
    expect(subject.textContent).toBe(expected)
  })

  test('renders image with placeholder', () => {
    const expected = 'image.png'
    props.placeholder = expected
    ReactDOM.render(<ThemeEditorImageRow {...props} />, elem)
    const subject = elem.getElementsByTagName('img')[0]
    expect(subject.src.split('/').pop()).toBe(expected)
  })

  // fails in Jest, passes in QUnit
  test.skip('renders image with user input val', () => {
    const expected = 'image.png'
    props.placeholder = 'other.png'
    props.userInput = {val: expected}
    ReactDOM.render(<ThemeEditorImageRow {...props} />, elem)
    const subject = elem.getElementsByTagName('img')[0]
    expect(subject.src.split('/').pop()).toBe(expected)
  })

  test('setValue clears file input and calls onChange when arg is null', () => {
    const component = ReactDOM.render(<ThemeEditorImageRow {...props} />, elem)
    const subject = component.fileInput
    subject.setAttribute('type', 'text')
    subject.value = 'foo'
    component.setValue(null)
    expect(subject.value).toBe('')
    expect(props.onChange).toHaveBeenCalledWith(null)
  })

  test('setValue clears file input and calls onChange when arg is empty string', () => {
    const component = ReactDOM.render(<ThemeEditorImageRow {...props} />, elem)
    const subject = component.fileInput
    subject.setAttribute('type', 'text')
    subject.value = 'foo'
    component.setValue('')
    expect(subject.value).toBe('')
    expect(props.onChange).toHaveBeenCalledWith('')
  })

  // we can't mutate window.URL
  test.skip('setValue calls onChange with blob url of input file', () => {
    const component = ReactDOM.render(<ThemeEditorImageRow {...props} />, elem)
    const blob = new Blob(['foo'], {type: 'text/plain'})
    const originalCreateObjectURL = window.URL.createObjectURL
    const expected = 'blob:url'
    jest.spyOn(window.URL, 'createObjectURL').mockReturnValue(expected)
    component.setValue({files: [blob]})
    expect(props.onChange).toHaveBeenCalledWith(expected)
    expect(window.URL.createObjectURL).toHaveBeenCalledWith(blob)
    window.URL.createObjectURL.mockRestore()
  })
})
