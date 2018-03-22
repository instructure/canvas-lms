/*
 * Copyright (C) 2014 - present Instructure, Inc.
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
import TestUtils from 'react-addons-test-utils'
import TextAreaInput from 'jsx/external_apps/components/TextAreaInput'

const {Simulate} = TestUtils
const wrapper = document.getElementById('fixtures')
const createElement = data => (
  <TextAreaInput
    defaultValue={data.defaultValue}
    label={data.label}
    id={data.id}
    rows={data.rows}
    required={data.required}
    hintText={data.hintText}
    errors={data.errors}
  />
)
const renderComponent = data => ReactDOM.render(createElement(data), wrapper)
const getDOMNodes = function(data) {
  const component = renderComponent(data)
  const inputNode = component.refs.input != null ? component.refs.input.getDOMNode() : undefined
  const hintNode =
    component.refs.hintText != null ? component.refs.hintText.getDOMNode() : undefined
  return [component, inputNode, hintNode]
}

QUnit.module('ExternalApps.TextAreaInput', {
  teardown() {
    ReactDOM.unmountComponentAtNode(wrapper)
  }
})

test('renders', () => {
  const data = {
    defaultValue: 'Lorem ipsum dolor...',
    label: 'Comments',
    id: 'comments',
    rows: 10,
    required: true,
    hintText: 'Enter comments above',
    errors: {}
  }
  const [component, inputNode, hintNode] = Array.from(getDOMNodes(data))
  equal(inputNode.value, data.defaultValue)
  ok(inputNode.required)
  equal(inputNode.attributes.rows.value, '10')
  equal(hintNode.textContent, data.hintText)
  equal(component.state.value, data.defaultValue)
})

test('renders without hint text and required', () => {
  const data = {
    defaultValue: 'Lorem ipsum dolor...',
    label: 'Comments',
    id: 'comments',
    rows: 10,
    required: false,
    hintText: null,
    errors: {}
  }
  const [component, inputNode, hintNode] = Array.from(getDOMNodes(data))
  equal(inputNode.value, data.defaultValue)
  ok(!inputNode.required)
  equal(hintNode, undefined)
  equal(component.state.value, data.defaultValue)
})

test('renders with error hint text', () => {
  const data = {
    defaultValue: null,
    label: 'Comments',
    id: 'comments',
    required: true,
    hintText: null,
    errors: {comments: 'Must be present'}
  }
  const [component, inputNode, hintNode] = Array.from(getDOMNodes(data))
  equal(inputNode.value, '')
  equal(hintNode.textContent, 'Must be present')
})

test('modifies state when text is entered', () => {
  const data = {
    defaultValue: '',
    label: 'Comments',
    id: 'comments',
    required: true,
    hintText: 'Enter comments above',
    errors: {}
  }
  const [component, inputNode, hintNode] = Array.from(getDOMNodes(data))
  Simulate.click(inputNode)
  Simulate.change(inputNode, {target: {value: 'Hello my friend, hello!'}})
  equal(component.state.value, 'Hello my friend, hello!')
})
