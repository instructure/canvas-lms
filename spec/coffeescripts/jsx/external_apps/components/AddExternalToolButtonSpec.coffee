define [
  'react'
  'react-modal'
  'jsx/external_apps/components/AddExternalToolButton'
], (React, Modal, AddExternalToolButton) ->

  TestUtils = React.addons.TestUtils
  Simulate = TestUtils.Simulate
  wrapper = null


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
    setup: ->
      wrapper = document.getElementById('fixtures')
      wrapper.innerHTML = ''
      Modal.setAppElement(wrapper)

    teardown: ->
      React.unmountComponentAtNode wrapper
      wrapper.innerHTML = ''

  test 'render', ->
    nodes = getDOMNodes()
    ok nodes.component.isMounted()
    ok TestUtils.isCompositeComponentWithType(nodes.component, AddExternalToolButton)
