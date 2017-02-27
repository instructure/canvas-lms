define [
  'react'
  'react-dom'
  'react-addons-test-utils'
  'jsx/external_apps/components/Lti2Edit'
], (React, ReactDOM, TestUtils, Lti2Edit) ->

  Simulate = TestUtils.Simulate
  wrapper = document.getElementById('fixtures')

  createElement = (data) ->
    React.createElement(Lti2Edit, {
      tool: data.tool
      handleActivateLti2: data.handleActivateLti2
      handleDeactivateLti2: data.handleDeactivateLti2
      handleCancel: data.handleCancel
    })

  renderComponent = (data) ->
    ReactDOM.render(createElement(data), wrapper)

  QUnit.module 'ExternalApps.Lti2Edit',
    teardown: ->
      ReactDOM.unmountComponentAtNode wrapper

  test 'renders', ->
    data =
      tool: {
        "app_id": 3,
        "app_type": "Lti::ToolProxy",
        "description": null,
        "enabled": false,
        "installed_locally": true,
        "name": "Twitter"
      }
      handleActivateLti2: ->
      handleDeactivateLti2: ->
      handleCancel: ->
    component = renderComponent(data)
    ok component.isMounted()
    ok TestUtils.isCompositeComponentWithType(component, Lti2Edit)
