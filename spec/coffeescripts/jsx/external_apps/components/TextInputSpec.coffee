#
# Copyright (C) 2014 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'react'
  'react-dom'
  'react-addons-test-utils'
  'jsx/external_apps/components/TextInput'
], (React, ReactDOM, TestUtils, TextInput) ->

  Simulate = TestUtils.Simulate
  wrapper = document.getElementById('fixtures')

  createElement = (data) ->
    React.createElement(TextInput, {
      defaultValue: data.defaultValue
      label: data.label
      id: data.id
      required: data.required
      hintText: data.hintText
      errors: data.errors
    })

  renderComponent = (data) ->
    ReactDOM.render(createElement(data), wrapper)

  getDOMNodes = (data) ->
    component = renderComponent(data)
    inputNode = component.refs.input?.getDOMNode()
    hintNode = component.refs.hintText?.getDOMNode()
    [ component, inputNode, hintNode ]

  QUnit.module 'ExternalApps.TextInput',
    teardown: ->
      ReactDOM.unmountComponentAtNode wrapper

  test 'renders', ->
    data =
      defaultValue: 'Joe'
      label: 'Name'
      id: 'name'
      required: true
      hintText: 'First Name'
      errors: {}
    [component, inputNode, hintNode] = getDOMNodes(data)
    equal inputNode.value, 'Joe'
    ok inputNode.required
    equal hintNode.textContent, 'First Name'
    equal component.state.value, 'Joe'

  test 'renders without hint text and required', ->
    data =
      defaultValue: 'Joe'
      label: 'Name'
      id: 'name'
      required: false
      hintText: null
      errors: {}
    [component, inputNode, hintNode] = getDOMNodes(data)
    equal inputNode.value, 'Joe'
    ok !inputNode.required
    equal hintNode, undefined
    equal component.state.value, 'Joe'

  test 'renders with error hint text', ->
    data =
      defaultValue: ''
      label: 'Name'
      id: 'name'
      required: true
      hintText: null
      errors: { name: 'Must be present' }
    [component, inputNode, hintNode] = getDOMNodes(data)
    equal inputNode.value, ''
    equal hintNode.textContent, 'Must be present'

  test 'modifies state when text is entered', ->
    data =
      defaultValue: ''
      label: 'Name'
      id: 'name'
      required: true
      hintText: 'First Name'
      errors: {}
    [component, inputNode, hintNode] = getDOMNodes(data)
    Simulate.click(inputNode);
    Simulate.change(inputNode, {target: {value: 'Larry Bird'}});
    equal component.state.value, 'Larry Bird'
