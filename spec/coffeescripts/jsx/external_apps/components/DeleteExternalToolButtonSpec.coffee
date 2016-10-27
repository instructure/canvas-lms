define [
  'react'
  'react-dom'
  'react-modal'
  'jsx/external_apps/components/DeleteExternalToolButton'
  'jsx/external_apps/lib/ExternalAppsStore'
], (React, ReactDOM, Modal, DeleteExternalToolButton, store) ->

  TestUtils = React.addons.TestUtils
  Simulate = TestUtils.Simulate
  wrapper = document.getElementById('fixtures')

  Modal.setAppElement(wrapper)

  createElement = (data) ->
    React.createElement(DeleteExternalToolButton, {
      tool: data.tool
    })

  renderComponent = (data) ->
    ReactDOM.render(createElement(data), wrapper)

  getDOMNodes = (data) ->
    component        = renderComponent(data)
    btnTriggerDelete = component.refs.btnTriggerDelete?.getDOMNode()
    [component, btnTriggerDelete]

  module 'ExternalApps.DeleteExternalToolButton',
    setup: ->
      @tools = [
        {
          "app_id": 1,
          "app_type": "ContextExternalTool",
          "description": "Talent provides an online, interactive video platform for professional development",
          "enabled": true,
          "installed_locally": true,
          "name": "Talent"
        },
        {
          "app_id": 2,
          "app_type": "Lti::ToolProxy",
          "description": null,
          "enabled": true,
          "installed_locally": true,
          "name": "Twitter"
        },
      ]
      store.reset()
      store.setState({ externalTools: @tools })
    teardown: ->
      store.reset()
      ReactDOM.unmountComponentAtNode wrapper

  test 'open and close modal', ->
    data = { tool: @tools[1] }
    [component, btnTriggerDelete] = getDOMNodes(data)
    Simulate.click(btnTriggerDelete)
    ok component.state.modalIsOpen, 'modal is open'
    ok component.refs.btnClose
    ok component.refs.btnDelete
    Simulate.click(component.refs.btnClose.getDOMNode())
    ok !component.state.modalIsOpen, 'modal is not open'
    ok !component.refs.btnClose
    ok !component.refs.btnDelete
