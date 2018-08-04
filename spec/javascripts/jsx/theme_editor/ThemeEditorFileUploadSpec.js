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
import ThemeEditorFileUpload from 'jsx/theme_editor/ThemeEditorFileUpload'

let elem, props

QUnit.module('ThemeEditorFileUpload Component', {
  setup() {
    elem = document.createElement('div')
    props = {
      onChange: sinon.spy()
    }
  }
})

test('renders button disabled if nothing to reset', () => {
  const component = ReactDOM.render(<ThemeEditorFileUpload {...props} />, elem)
  const subject = elem.getElementsByTagName('button')[0]
  equal(subject.disabled, true, 'button is disabled')
})

test('renders button not disabled if something to reset', () => {
  props.userInput = {val: 'foo'}
  const component = ReactDOM.render(<ThemeEditorFileUpload {...props} />, elem)
  const subject = elem.getElementsByTagName('button')[0]
  equal(subject.disabled, false, 'button is enabled')
})

test('reset button label', () => {
  let component = ReactDOM.render(<ThemeEditorFileUpload {...props} />, elem)
  const subject = elem.getElementsByTagName('button')[0]
  equal(subject.textContent, 'Reset', 'button label is "Reset"')

  props.currentValue = 'foo'
  component = ReactDOM.render(<ThemeEditorFileUpload {...props} />, elem)
  equal(subject.textContent, 'Clear', 'button label is "Clear"')

  props.userInput = {val: 'foo'}
  component = ReactDOM.render(<ThemeEditorFileUpload {...props} />, elem)
  equal(subject.textContent, 'Undo', 'button label is "Undo"')
})

test('hasSomethingToReset', () => {
  props.userInput = {val: 'foo'}
  let component = ReactDOM.render(<ThemeEditorFileUpload {...props} />, elem)
  ok(component.hasSomethingToReset(), 'truthy userInput.val')

  props.userInput.val = ''
  component = ReactDOM.render(<ThemeEditorFileUpload {...props} />, elem)
  ok(component.hasSomethingToReset(), 'empty string userInput.val')

  props.userInput = {}
  props.currentValue = 'foo'
  component = ReactDOM.render(<ThemeEditorFileUpload {...props} />, elem)
  ok(component.hasSomethingToReset(), 'currentValue truthy')

  props.currentValue = null
  component = ReactDOM.render(<ThemeEditorFileUpload {...props} />, elem)
  notOk(component.hasSomethingToReset(), 'no value')
})

test('hasUserInput', () => {
  let component = ReactDOM.render(<ThemeEditorFileUpload {...props} />, elem)
  notOk(component.hasUserInput(), 'no user input')

  props.userInput = {val: 'foo'}
  component = ReactDOM.render(<ThemeEditorFileUpload {...props} />, elem)
  ok(component.hasUserInput(), 'non null input value')
})

test('handleFileChanged', function() {
  var expected = {}
  sandbox.stub(window.URL, 'createObjectURL').returns(expected)
  const component = ReactDOM.render(<ThemeEditorFileUpload {...props} />, elem)
  sandbox.spy(component, 'setState')
  const file = new Blob(['foo'], {type: 'text/plain'})
  file.name = 'foo.png'
  component.handleFileChanged({target: {files: [file]}})
  ok(
    component.setState.calledWithMatch({selectedFileName: file.name}),
    'sets selectedFileName in state'
  )
  ok(window.URL.createObjectURL.calledWith(file), 'creates object url with file')
  ok(props.onChange.calledWith(expected), 'calls onChange with object url')
})

test('handleResetClicked', function() {
  const component = ReactDOM.render(<ThemeEditorFileUpload {...props} />, elem)
  const subject = component.fileInput
  subject.setAttribute('type', 'text')
  subject.value = 'foo'
  sandbox.spy(component, 'setState')
  const file = new Blob(['foo'], {type: 'text/plain'})
  file.name = 'foo.png'
  sandbox.stub(component, 'hasUserInput').returns(true)
  component.handleResetClicked()
  equal(subject.value, '', 'cleared file input value')
  ok(
    component.setState.calledWithMatch({selectedFileName: ''}),
    'sets selectedFileName in state to empty string'
  )
  ok(props.onChange.calledWith(null), 'calls onChange null')

  component.hasUserInput.returns(false)
  component.handleResetClicked()
  ok(props.onChange.calledWith(''), 'calls onChange empty string')
})

test('displayValue', function() {
  let component = ReactDOM.render(<ThemeEditorFileUpload {...props} />, elem)
  sandbox.stub(component, 'hasUserInput').returns(false)
  equal(component.displayValue(), '', 'no input or current value, returns empty string')

  props.userInput = {val: 'foo'}
  component = ReactDOM.render(<ThemeEditorFileUpload {...props} />, elem)
  const state = {selectedFileName: 'file.png'}
  component.setState(state)
  equal(
    component.displayValue(),
    state.selectedFileName,
    'return selectedFileName from component state'
  )

  props.currentValue = 'bar'
  component = ReactDOM.render(<ThemeEditorFileUpload {...props} />, elem)
  equal(component.displayValue(), props.currentValue, 'returns current value')
})

test('sets accept on file input from prop', () => {
  props.accept = 'image/*'
  const component = ReactDOM.render(<ThemeEditorFileUpload {...props} />, elem)
  const subject = component.fileInput
  equal(subject.accept, props.accept, 'accepted is set on file input')
})
