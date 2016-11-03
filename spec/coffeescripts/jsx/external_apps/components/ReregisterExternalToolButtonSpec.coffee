define [
  'react'
  'react-dom'
  'react-modal'
  'jsx/external_apps/components/ReregisterExternalToolButton'
  'jsx/external_apps/lib/ExternalAppsStore'
], (React, ReactDOM, Modal, ReregisterExternalToolButton, store) ->

  TestUtils = React.addons.TestUtils
  Simulate = TestUtils.Simulate
  wrapper = document.getElementById('fixtures')

  Modal.setAppElement(wrapper)

  createElement = (data) ->
    React.createElement(ReregisterExternalToolButton, {
      tool: data.tool
    })

  renderComponent = (data) ->
    ReactDOM.render(createElement(data), wrapper)

  getDOMNodes = (data) ->
    component        = renderComponent(data)
    btnTriggerReregister = component.refs.reregisterExternalToolButton?.getDOMNode()
    [component, btnTriggerReregister]

  module 'ExternalApps.ReregisterExternalToolButton',
    setup: ->
      @tools = [
        {
          "app_id": 2,
          "app_type": "Lti::ToolProxy",
          "description": null,
          "enabled": true,
          "installed_locally": true,
          "name": "Twitter",
          "reregistration_url": "http://some.lti/reregister"
        }
      ]
      store.reset()
      store.setState({ externalTools: @tools })
    teardown: ->
      store.reset()
      ReactDOM.unmountComponentAtNode wrapper

  test 'open and close modal', ->
    data = { tool: @tools[0] }
    [component, btnTriggerReregister] = getDOMNodes(data)
    Simulate.click(btnTriggerReregister)
    ok component.state.modalIsOpen, 'modal is open'
    ok component.refs.btnClose
    ok component.refs.reregisterExternalToolButton
    Simulate.click(component.refs.btnClose.getDOMNode())
    ok !component.state.modalIsOpen, 'modal is not open'
    ok !component.refs.btnClose
