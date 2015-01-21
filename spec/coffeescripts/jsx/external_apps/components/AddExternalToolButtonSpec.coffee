define [
  'old_unsupported_dont_use_react'
  'old_unsupported_dont_use_react-modal'
  'jsx/external_apps/components/AddExternalToolButton'
], (React, Modal, AddExternalToolButton) ->

  TestUtils = React.addons.TestUtils
  Simulate = TestUtils.Simulate
  wrapper = document.getElementById('fixtures')

  Modal.setAppElement(wrapper)

  createElement = ->
    AddExternalToolButton({})

  renderComponent = ->
    React.renderComponent(createElement(), wrapper)

  getDOMNodes = ->
    component = renderComponent()
    {
      component: component
      addToolButton: component.refs.addTool?.getDOMNode()
      modal: component.refs.modal?.getDOMNode()
      lti2Permissions: component.refs.lti2Permissions?.getDOMNode()
      lti2Iframe: component.refs.lti2Iframe?.getDOMNode()
      configurationForm: component.refs.configurationForm?.getDOMNode()
    }

  module 'ExternalApps.AddExternalToolButton',
    teardown: ->
      React.unmountComponentAtNode wrapper

  test 'render', ->
    nodes = getDOMNodes()
    ok nodes.component.isMounted()
    ok TestUtils.isCompositeComponentWithType(nodes.component, AddExternalToolButton)

  test 'renderForm', ->
    nodes = getDOMNodes()

    nodes.component.setState({ isLti2: true, tool: { app_id: 1 }})
    form = nodes.component.renderForm()
    equal form.props.ref, 'lti2Permissions'

    nodes.component.setState({ isLti2: true, tool: { app_id: null }})
    form = nodes.component.renderForm()
    equal form.props.ref, 'lti2Iframe'

    nodes.component.setState({ isLti2: false, tool: {}})
    form = nodes.component.renderForm()
    equal form.props.ref, 'configurationForm'