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
import ThemeEditorImageRow from 'jsx/theme_editor/ThemeEditorImageRow'

let elem, props

QUnit.module('ThemeEditorImageRow Component', {
  setup() {
    elem = document.createElement('div')
    props = {
      varDef: {},
      onChange: sinon.spy()
    }
  }
})

test('renders with human name heading', () => {
  const expected = 'Human'
  props.varDef.human_name = expected
  const component = ReactDOM.render(<ThemeEditorImageRow {...props} />, elem)
  const subject = elem.getElementsByTagName('h3')[0]
  equal(subject.textContent, expected, 'renders human name')
})

test('renders with helper text', () => {
  const expected = 'Halp!'
  props.varDef.helper_text = expected
  const component = ReactDOM.render(<ThemeEditorImageRow {...props} />, elem)
  const subject = elem.getElementsByClassName('Theme__editor-upload_restrictions')[0]
  equal(subject.textContent, expected, 'renders helper text')
})

test('renders image with placeholder', () => {
  const expected = 'image.png'
  props.placeholder = expected
  const component = ReactDOM.render(<ThemeEditorImageRow {...props} />, elem)
  const subject = elem.getElementsByTagName('img')[0]
  equal(subject.src.split('/').pop(), expected, 'has placeholder for src')
})

test('renders image with user input val', () => {
  const expected = 'image.png'
  props.placeholder = 'other.png'
  props.userInput = {val: expected}
  const component = ReactDOM.render(<ThemeEditorImageRow {...props} />, elem)
  const subject = elem.getElementsByTagName('img')[0]
  equal(subject.src.split('/').pop(), expected, 'has userInput.val for src')
})

test('setValue clears file input and calls onChange when arg is null', () => {
  const component = ReactDOM.render(<ThemeEditorImageRow {...props} />, elem)
  const subject = component.fileInput
  subject.setAttribute('type', 'text')
  subject.value = 'foo'
  component.setValue(null)
  equal(subject.value, '', 'file upload field is empty')
  ok(props.onChange.calledWith(null), 'onChange called with null')
})

test('setValue clears file input and calls onChange when arg is empty string', () => {
  const component = ReactDOM.render(<ThemeEditorImageRow {...props} />, elem)
  const subject = component.fileInput
  subject.setAttribute('type', 'text')
  subject.value = 'foo'
  component.setValue('')
  equal(subject.value, '', 'file upload field is empty')
  ok(props.onChange.calledWith(''), 'onChange called with empty string')
})

test('setValue calls onChange with blob url of input file', () => {
  const component = ReactDOM.render(<ThemeEditorImageRow {...props} />, elem)
  const blob = new Blob(['foo'], {type: 'text/plain'})
  // URL.createObjectURL returns different URLS when called twice with the
  // same blob.
  const originalCreateObjectURL = window.URL.createObjectURL
  const expected = {}
  sinon.stub(window.URL, 'createObjectURL').returns(expected)
  component.setValue({files: [blob]})
  ok(props.onChange.calledWith(expected), 'onChange called with blob url')
  ok(window.URL.createObjectURL.calledWith(blob), 'object url created for file')
  window.URL.createObjectURL.restore()
})
