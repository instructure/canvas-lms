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
import SelectInput from 'jsx/external_apps/components/SelectInput'

const {Simulate} = TestUtils
const wrapper = document.getElementById('fixtures')
const createElement = data => (
  <SelectInput
    defaultValue={data.defaultValue}
    values={data.values}
    allowBlank={data.allowBlank}
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

QUnit.module('ExternalApps.SelectInput', {
  teardown() {
    ReactDOM.unmountComponentAtNode(wrapper)
  }
})

test('renders', () => {
  const data = {
    defaultValue: 'UT',
    values: {
      WI: 'Wisconsin',
      TX: 'Texas',
      UT: 'Utah',
      AL: 'Alabama'
    },
    label: 'State',
    id: 'state',
    required: true,
    hintText: 'Select State',
    errors: {}
  }
  const [component, inputNode, hintNode] = Array.from(getDOMNodes(data))
  equal(inputNode.value, data.defaultValue)
  ok(inputNode.required)
  equal(hintNode.textContent, data.hintText)
  equal(component.state.value, data.defaultValue)
})

test('renders without hint text and required', () => {
  const data = {
    defaultValue: 'UT',
    values: {
      WI: 'Wisconsin',
      TX: 'Texas',
      UT: 'Utah',
      AL: 'Alabama'
    },
    label: 'State',
    id: 'state',
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
    allowBlank: true,
    values: {
      WI: 'Wisconsin',
      TX: 'Texas',
      UT: 'Utah',
      AL: 'Alabama'
    },
    label: 'State',
    id: 'state',
    required: true,
    hintText: null,
    errors: {state: 'Must be present'}
  }
  const [component, inputNode, hintNode] = Array.from(getDOMNodes(data))
  equal(inputNode.value, '')
  equal(hintNode.textContent, 'Must be present')
})

test('modifies state when text is entered', () => {
  const data = {
    defaultValue: '',
    label: 'State',
    id: 'state',
    required: true,
    hintText: 'Select State',
    errors: {}
  }
  const [component, inputNode, hintNode] = Array.from(getDOMNodes(data))
  Simulate.click(inputNode)
  Simulate.change(inputNode, {target: {value: 'TX'}})
  equal(component.state.value, 'TX')
})
