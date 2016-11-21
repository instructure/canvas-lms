define [
  'react'
  'react-dom'
  'react-addons-test-utils'
  'react-modal'
  'jsx/external_apps/components/ConfigureExternalToolButton'
], (React, ReactDOM, TestUtils, Modal, ConfigureExternalToolButton) ->

  Simulate = TestUtils.Simulate
  wrapper = document.getElementById('fixtures')

  Modal.setAppElement(wrapper)

  createElement = (tool) ->
    React.createElement(ConfigureExternalToolButton, {
      tool: tool
    })

  renderComponent = (data) ->
    ReactDOM.render(createElement(data), wrapper)

  getDOMNodes = (data) ->
    component        = renderComponent(data)
    btnTriggerModal = component.refs.btnTriggerModal?.getDOMNode()
    [component, btnTriggerModal]

  module 'ExternalApps.ConfigureExternalToolButton',
    setup: ->
      @tools = [
        {
          "app_id": 1,
          "app_type": "ContextExternalTool",
          "description": "Talent provides an online, interactive video platform for professional development",
          "enabled": true,
          "installed_locally": true,
          "name": "Talent",
          "tool_configuration": { "url": "http://example.com" }
        },
        {
          "app_id": 2,
          "app_type": "Lti::ToolProxy",
          "description": null,
          "enabled": true,
          "installed_locally": true,
          "name": "Twitter",
          "tool_configuration": null
        },
      ]
    teardown: ->
      ReactDOM.unmountComponentAtNode wrapper

  test 'open and close modal', ->
    tool = {
      "app_id": 1
      "app_type": "ContextExternalTool"
      "description": "Talent provides an online, interactive video platform for professional development"
      "enabled": true
      "installed_locally": true
      "name": "Talent"
      "tool_configuration": { "url": "http://example.com" }
    }
    [component, btnTriggerModal] = getDOMNodes(tool)
    Simulate.click(btnTriggerModal)
    ok component.state.modalIsOpen, 'modal is open'
    ok component.refs.btnClose
    Simulate.click(component.refs.btnClose.getDOMNode())
    ok !component.state.modalIsOpen, 'modal is not open'
    ok !component.refs.btnClose
