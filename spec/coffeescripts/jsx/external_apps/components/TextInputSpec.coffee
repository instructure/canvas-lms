define [
  'react'
  'jsx/external_apps/components/TextInput'
], (React, TextInput) ->

  TestUtils = React.addons.TestUtils
  Simulate = TestUtils.Simulate
  wrapper = document.getElementById('fixtures')

  createElement = (data) ->
    TextInput({
      defaultValue: data.defaultValue
      label: data.label
      id: data.id
      required: data.required
      hintText: data.hintText
      errors: data.errors
    })

  renderComponent = (data) ->
    React.renderComponent(createElement(data), wrapper)

  getDOMNodes = (data) ->
    component = renderComponent(data)
    inputNode = component.refs.input?.getDOMNode()
    hintNode = component.refs.hintText?.getDOMNode()
    [ component, inputNode, hintNode ]

  module 'ExternalApps.TextInput',
    teardown: ->
      React.unmountComponentAtNode wrapper

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
