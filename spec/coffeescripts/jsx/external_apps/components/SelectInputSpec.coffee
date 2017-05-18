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
  'jsx/external_apps/components/SelectInput'
], (React, ReactDOM, TestUtils, SelectInput) ->

  Simulate = TestUtils.Simulate
  wrapper = document.getElementById('fixtures')

  createElement = (data) ->
    React.createElement(SelectInput, {
      defaultValue: data.defaultValue
      values: data.values
      allowBlank: data.allowBlank
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

  QUnit.module 'ExternalApps.SelectInput',
    teardown: ->
      ReactDOM.unmountComponentAtNode wrapper

  test 'renders', ->
    data =
      defaultValue: 'UT'
      values: { WI: 'Wisconsin', TX: 'Texas', UT: 'Utah', AL: 'Alabama' }
      label: 'State'
      id: 'state'
      required: true
      hintText: 'Select State'
      errors: {}
    [component, inputNode, hintNode] = getDOMNodes(data)
    equal inputNode.value, data.defaultValue
    ok inputNode.required
    equal hintNode.textContent, data.hintText
    equal component.state.value, data.defaultValue

  test 'renders without hint text and required', ->
    data =
      defaultValue: 'UT'
      values: { WI: 'Wisconsin', TX: 'Texas', UT: 'Utah', AL: 'Alabama' }
      label: 'State'
      id: 'state'
      required: false
      hintText: null
      errors: {}
    [component, inputNode, hintNode] = getDOMNodes(data)
    equal inputNode.value, data.defaultValue
    ok !inputNode.required
    equal hintNode, undefined
    equal component.state.value, data.defaultValue

  test 'renders with error hint text', ->
    data =
      defaultValue: null
      allowBlank: true
      values: { WI: 'Wisconsin', TX: 'Texas', UT: 'Utah', AL: 'Alabama' }
      label: 'State'
      id: 'state'
      required: true
      hintText: null
      errors: { state: 'Must be present' }
    [component, inputNode, hintNode] = getDOMNodes(data)
    equal inputNode.value, ''
    equal hintNode.textContent, 'Must be present'

  test 'modifies state when text is entered', ->
    data =
      defaultValue: ''
      label: 'State'
      id: 'state'
      required: true
      hintText: 'Select State'
      errors: {}
    [component, inputNode, hintNode] = getDOMNodes(data)
    Simulate.click(inputNode);
    Simulate.change(inputNode, {target: {value: 'TX'}});
    equal component.state.value, 'TX'
