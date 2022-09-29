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
import TestUtils from 'react-dom/test-utils'
import TextInput from 'ui/features/external_apps/react/components/TextInput.js'

const {Simulate} = TestUtils
const wrapper = document.getElementById('fixtures')
const createElement = data => (
  <TextInput
    defaultValue={data.defaultValue}
    renderLabel={data.renderLabel}
    id={data.id}
    isRequired={data.isRequired}
    hintText={data.hintText}
    errors={data.errors}
  />
)
const renderComponent = data => ReactDOM.render(createElement(data), wrapper)
const getDOMNodes = function (data) {
  const component = renderComponent(data)
  const inputNode = component.refs.input
  const hintNode = component.refs.hintText
  return [component, inputNode, hintNode]
}

QUnit.module('ExternalApps.TextInput', {
  teardown() {
    ReactDOM.unmountComponentAtNode(wrapper)
  },
})

test('renders', () => {
  const data = {
    defaultValue: 'Joe',
    renderLabel: 'Name',
    id: 'name',
    isRequired: true,
    hintText: 'First Name',
    errors: {},
  }
  const [component, inputNode, hintNode] = Array.from(getDOMNodes(data))
  equal(inputNode.value, 'Joe')
  ok(inputNode.required)
  equal(hintNode.textContent, 'First Name')
  equal(component.state.value, 'Joe')
})

test('renders without hint text and isRequired', () => {
  const data = {
    defaultValue: 'Joe',
    renderLabel: 'Name',
    id: 'name',
    isRequired: false,
    hintText: null,
    errors: {},
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
    renderLabel: 'Name',
    id: 'name',
    isRequired: true,
    hintText: null,
    errors: {name: 'Must be present'},
  }
  const [component, inputNode, hintNode] = Array.from(getDOMNodes(data))
  equal(inputNode.value, '')
  equal(hintNode.textContent, 'Must be present')
})

test('modifies state when text is entered', () => {
  const data = {
    defaultValue: '',
    renderLabel: 'Name',
    id: 'name',
    isRequired: true,
    hintText: 'First Name',
    errors: {},
  }
  const [component, inputNode, hintNode] = Array.from(getDOMNodes(data))
  Simulate.click(inputNode)
  Simulate.change(inputNode, {target: {value: 'Larry Bird'}})
  equal(component.state.value, 'Larry Bird')
})
