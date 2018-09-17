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
import TextInput from 'jsx/external_apps/components/TextInput'

const {Simulate} = TestUtils
const wrapper = document.getElementById('fixtures')
const createElement = data => (
  <TextInput
    defaultValue={data.defaultValue}
    label={data.label}
    id={data.id}
    required={data.required}
    hintText={data.hintText}
    errors={data.errors}
  />
)
const renderComponent = data => ReactDOM.render(createElement(data), wrapper)
const getDOMNodes = function(data) {
  const component = renderComponent(data)
  const inputNode = component.refs.input
  const hintNode = component.refs.hintText
  return [component, inputNode, hintNode]
}

QUnit.module('ExternalApps.TextInput', {
  teardown() {
    ReactDOM.unmountComponentAtNode(wrapper)
  }
})

test('renders', () => {
  const data = {
    defaultValue: 'Joe',
    label: 'Name',
    id: 'name',
    required: true,
    hintText: 'First Name',
    errors: {}
  }
  const [component, inputNode, hintNode] = Array.from(getDOMNodes(data))
  equal(inputNode.value, 'Joe')
  ok(inputNode.required)
  equal(hintNode.textContent, 'First Name')
  equal(component.state.value, 'Joe')
})

test('renders without hint text and required', () => {
  const data = {
    defaultValue: 'Joe',
    label: 'Name',
    id: 'name',
    required: false,
    hintText: null,
    errors: {}
  }
  const [component, inputNode, hintNode] = Array.from(getDOMNodes(data))
  equal(inputNode.value, 'Joe')
  ok(!inputNode.required)
  equal(hintNode, undefined)
  equal(component.state.value, 'Joe')
})

test('renders with error hint text', () => {
  const data = {
    defaultValue: '',
    label: 'Name',
    id: 'name',
    required: true,
    hintText: null,
    errors: {name: 'Must be present'}
  }
  const [component, inputNode, hintNode] = Array.from(getDOMNodes(data))
  equal(inputNode.value, '')
  equal(hintNode.textContent, 'Must be present')
})

test('modifies state when text is entered', () => {
  const data = {
    defaultValue: '',
    label: 'Name',
    id: 'name',
    required: true,
    hintText: 'First Name',
    errors: {}
  }
  const [component, inputNode, hintNode] = Array.from(getDOMNodes(data))
  Simulate.click(inputNode)
  Simulate.change(inputNode, {target: {value: 'Larry Bird'}})
  equal(component.state.value, 'Larry Bird')
})
