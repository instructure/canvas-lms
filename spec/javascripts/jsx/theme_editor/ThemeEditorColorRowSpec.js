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
import ThemeEditorColorRow from 'jsx/theme_editor/ThemeEditorColorRow'

let elem, props

QUnit.module('ThemeEditorColorRow Component', {
  setup() {
    elem = document.createElement('div')
    props = {
      varDef: {},
      onChange: sinon.spy(),
      handleThemeStateChange: sinon.spy()
    }
    // element needs to be attached to test focus
    document.body.appendChild(elem)
  },

  teardown() {
    document.body.removeChild(elem)
  }
})

test('showWarning', () => {
  let component = ReactDOM.render(<ThemeEditorColorRow {...props} />, elem)
  notOk(component.showWarning(), 'not invalid')
  props.userInput = {invalid: true}
  sinon.stub(component, 'inputNotFocused').returns(false)
  component = ReactDOM.render(<ThemeEditorColorRow {...props} />, elem)
  notOk(component.showWarning(), 'invalid but input focused')
  component.inputNotFocused.returns(true)
  ok(component.showWarning(), 'invalid and input not focused')
})

test('changedColor', () => {
  const component = ReactDOM.render(<ThemeEditorColorRow {...props} />, elem)
  equal(component.changedColor('foo'), null, 'returns null if background color is invalid string')

  equal(
    component.changedColor('#fff'),
    'rgb(255, 255, 255)',
    'accepts and returns valid values in rgb'
  )

  equal(component.changedColor('red'), 'red', 'accepts valid color words')

  equal(component.changedColor('transparent'), 'transparent', 'accepts transparent as a value')

  equal(component.changedColor(undefined), null, 'rejects undefined params')

  equal(
    component.changedColor('rgb(123,123,123)'),
    'rgb(123, 123, 123)',
    'accepts valid rgb values'
  )

  equal(
    component.changedColor('rgba(255, 255, 255, 255)'),
    'rgb(255, 255, 255)',
    'accepts and compresses rgba values'
  )

  equal(component.changedColor('rgba(foo)'), null, 'rejects bad rgba values')
})

test('invalidHexString', () => {
  const component = ReactDOM.render(<ThemeEditorColorRow {...props} />, elem)
  notOk(component.invalidHexString('foo'), 'hex string is not valid')
  ok(component.invalidHexString('#aabbccc'), 'hex string is valid')
  ok(component.invalidHexString('#abcc'), 'short hex string is valid')
})

test('inputChange', () => {
  const component = ReactDOM.render(<ThemeEditorColorRow {...props} />, elem)
  const expected = 'foo'
  sinon.stub(component, 'changedColor').returns(true)
  sinon.stub(component, 'invalidHexString').returns(false)

  component.inputChange(expected)
  ok(
    props.onChange.calledWith(expected, false),
    'calls onChange with value and invalid false when valid'
  )

  component.changedColor.returns(false)
  props.onChange.reset()
  component.inputChange(expected)
  ok(
    props.onChange.calledWith(expected, true),
    'calls onChange with value and invalid true when invalid'
  )

  component.changedColor.returns(true)
  component.invalidHexString.returns(true)
  props.onChange.reset()
  component.inputChange(expected)
  ok(
    props.onChange.calledWith(expected, true),
    'calls onChange with value and invalid true when invalid'
  )
})

test('inputNotFocused', () => {
  const component = ReactDOM.render(<ThemeEditorColorRow {...props} />, elem)
  document.body.focus()
  ok(component.inputNotFocused, 'input is not focused')
  component.textInput.focus()
  notOk(component.inputNotFocused(), 'input is focused')
})
